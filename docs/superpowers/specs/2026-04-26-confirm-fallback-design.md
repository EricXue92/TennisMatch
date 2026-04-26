# 确认环节兜底机制 — 设计 Spec

> Source issue: `docs/2026-04-26-flow-stress-test.md` #1
> Date: 2026-04-26
> Status: design approved, pending implementation plan

---

## 1. 问题陈述

当前 `BookingStore.signUp()` 是单路径**直接加入**:报名即占名额,不经发起人审核。这不是已有 bug,而是**完全缺失了「需审核」流程**。

#1 压测报告中担心的「pending 卡住」在现有代码里不存在(因为根本没有 pending review 状态)。本 spec 设计一套**可选的审核流程 + 超时兜底**,在不破坏现有「自动通过」体验的前提下,给发起人一个筛选闸口。

---

## 2. 范围与决策摘要

| 决策                  | 选项                                                                  | 理由                                                 |
| --------------------- | --------------------------------------------------------------------- | ---------------------------------------------------- |
| 审核是否默认开        | **可选(发起人自选,默认关)**                                           | 业余局多数「先到先得」心态,审核是负担;但要给筛选选项 |
| 超时未审核兜底        | **自动全部接受**(FIFO 直到满员,后到 waitlist)                         | 卡住的报名者体验最差;发起人不点 = 主动放弃筛选权     |
| 短时间发布的 deadline | **动态阈值 = `min(12h, totalLeadTime × 0.5)`**                        | 简单、可预测,不增加发布表单复杂度                    |
| 满员后剩余 pending    | **自动转 waitlist + 自动递补**                                        | 餐厅排队级国民体验                                   |
| 触发机制              | **App 进前台 / View onAppear,无 timer**                               | 无后端阶段最务实;后端接入再换                        |
| 数据迁移              | **一刀替换** `accepted[]` → `applications[]`                          | 渐进迁移成本最终更高                                 |
| 后端友好建模          | **现在就补 `id: UUID`** 到 UserProfile / MatchRegistrant / 所有新模型 | 项目原则:前端设计阶段就为后端建模                    |

---

## 3. 状态机

新增 `BookingApprovalStatus`(独立于 `MyMatchStatus`,后者表示球局自身满员状态):

```swift
enum BookingApprovalStatus: String, Codable {
    case autoConfirmed     // 球局未开审核,直接确认(默认行为)
    case pendingReview     // 已申请,等发起人审核
    case approved          // 审核通过,占名额
    case rejected          // 被拒(host 主动 / 满员转拒)
    case waitlisted        // 满员被挤到候补
    case cancelledBySelf   // 报名者主动撤回
    case autoApproved      // 超时兜底自动接受(区分,UI 标记「系统自动通过」)
    case expired           // 球局已过期,从未审核
}
```

### 合法转换

| From            | To                | 触发                |
| --------------- | ----------------- | ------------------- |
| `pendingReview` | `approved`        | host 主动接受       |
| `pendingReview` | `rejected`        | host 主动拒绝       |
| `pendingReview` | `waitlisted`      | host 接受他人到满员 |
| `pendingReview` | `autoApproved`    | 超时兜底            |
| `pendingReview` | `cancelledBySelf` | 报名者撤回          |
| `pendingReview` | `expired`         | 球局过期且未处理    |
| `waitlisted`    | `approved`        | 候补递补成功        |
| `waitlisted`    | `cancelledBySelf` | 报名者撤回          |
| `waitlisted`    | `expired`         | 球局过期未递补      |

### 不合法

- `approved → pendingReview`(已批锁定;host 反悔需先 reject 再请求重新申请)
- 任何非 `pendingReview` → `autoApproved`
- 终态(`approved` / `rejected` / `cancelledBySelf` / `expired` / `autoApproved`)不再迁出

**报名者主动撤回 pending 不扣信用分**(信用分系统在 #2 任务范围)。

**已知限制**:`.approved` 是终态 → host 接受后**不能再单独踢人**。如需移除某 approved 报名者,只能整局取消重发。简化状态机的代价,v1 可接受。

---

## 4. 数据模型

### 4.1 现有模型补 ID

```swift
// UserStore.UserProfile
let id: UUID                    // 持久化(首次启动写入 UserDefaults,与 displayName 同生命周期)

// MatchRegistrant
let id: UUID                    // mock seed 时生成,持久化进 BookingStore
```

### 4.2 `MockMatch` 增字段

```swift
var hostID: UUID                // host 的 UserProfile.id(mock seed 写死)
var requiresApproval: Bool = false
var approvalDeadline: Date? = nil
```

`approvalDeadline` 计算(发布时一次算定,不变):

```
if !requiresApproval { return nil }
totalLeadTime = startDate - publishedAt
return startDate - min(12h, totalLeadTime * 0.5)
```

边界:`totalLeadTime < 30min` → 不允许开 `requiresApproval`(UI 强制关 + 灰提示)。

### 4.3 新增 `MatchApplication`

```swift
struct MatchApplication: Identifiable, Codable {
    let id: UUID
    let matchID: UUID
    let applicantID: UUID            // 报名者 UserProfile.id
    let hostID: UUID                 // 冗余,后端查询友好
    var status: BookingApprovalStatus
    let appliedAt: Date
    var resolvedAt: Date?
    var resolvedBy: UUID?            // host 接受 = hostID;系统兜底 = nil;自撤 = applicantID
    var note: String?                // host 拒绝时的可选理由
}
```

字段命名直接对齐 REST 风格,`POST /api/applications` 的 body 就是这个结构。

### 4.4 `BookingStore` 一刀替换

**删除**:

- `accepted: [AcceptedMatchInfo]`
- `signedUpMatchIDs: Set<UUID>`
- 对应的 UserDefaults 持久化 key

**新增**:

- `applications: [MatchApplication]`(唯一来源)
- 派生 helper(view 侧用):
  ```swift
  var myApprovedMatches: [UUID]                                      // 替代 signedUpMatchIDs
  func incomingApplications(for matchID: UUID) -> [MatchApplication] // host 视角
  func myApplication(for matchID: UUID) -> MatchApplication?         // 自己视角
  func conflict(start:end:excluding:) -> ConflictHit?                // 内部改读 applications
  ```

**新增 API**:

```swift
func apply(to match: MockMatch, now: Date = .now) -> MatchApplication
func approve(applicationID: UUID, now: Date = .now)
func reject(applicationID: UUID, note: String?, now: Date = .now)
func cancelApplication(_ id: UUID, now: Date = .now)
func runApprovalDeadlines(now: Date = .now)
func promoteWaitlist(now: Date = .now)
func runFallbackChecks(now: Date = .now)   // 顺序调上面两个,带 2s 去抖
```

### 4.5 `AcceptedMatchInfo` 保留为 ViewModel

被 `MessagesView` 当显示卡片用 → 改成**纯 UI ViewModel**,从 `MatchApplication.filter { status ∈ {approved, autoApproved, autoConfirmed} }` 关联 `MockMatch` 派生,不再独立持久化。

### 4.6 影响面(本次 PR 必改)

- `Models/BookingStore.swift` —— 全文重写
- `Models/UserStore.swift` —— 加 id 字段 + 持久化
- `Views/Home/MockMatchData.swift` —— 加 hostID / requiresApproval / approvalDeadline
- `Views/MessagesView.swift:249` —— `AcceptedMatchInfo` 改派生
- `Views/MyMatchesView.swift:150` —— `acceptedMatchItems` 改读 applications
- `Views/HomeView.swift:653` —— `signUp` 入口改 `apply`
- `Views/CreateMatchView.swift` —— 加审核 section
- `Views/MatchDetailView.swift` —— 加 host 审核区块
- `TennisMatchApp.swift` —— scenePhase 监听
- `Models/NotificationStore.swift` —— 新增 6 种 kind + `coalesceKey`

---

## 5. 自动兜底触发器

### 5.1 触发点

仅两个入口调用 `runFallbackChecks(now:)`:

1. `TennisMatchApp.swift` 监听 `@Environment(\.scenePhase) == .active`
2. 各核心 view(HomeView / MyMatchesView / MatchDetailView)的 `onAppear`

### 5.2 去抖

`BookingStore` 维护 `lastRunAt: Date`。`runFallbackChecks` 入口检查 `now - lastRunAt < 2s` → 直接 return。

### 5.3 关键定义

`approvedCount(for matchID:)` —— 返回该 match 下状态为 `.approved` / `.autoApproved` / `.autoConfirmed` 三者之一的 `applications` 数量。所有「占名额」判断均以此为准。

### 5.4 主流程伪代码

```swift
func runApprovalDeadlines(now: Date) {
    let pending = applications
        .filter { $0.status == .pendingReview }
        .sorted { $0.appliedAt < $1.appliedAt }    // FIFO

    for app in pending {
        guard let match = matchLookup[app.matchID],
              let deadline = match.approvalDeadline,
              now >= deadline else { continue }

        if match.startDate < now {
            transition(app, to: .expired, now: now)
        } else if approvedCount(for: match.id) < match.maxPlayers - 1 {
            transition(app, to: .autoApproved, now: now)
        } else {
            transition(app, to: .waitlisted, now: now)
        }
    }
}

func promoteWaitlist(now: Date) {
    for match in allMatches where !match.isExpired {
        let slots = match.maxPlayers - 1 - approvedCount(for: match.id)
        guard slots > 0 else { continue }

        let queue = applications
            .filter { $0.matchID == match.id && $0.status == .waitlisted }
            .sorted { $0.appliedAt < $1.appliedAt }

        for app in queue.prefix(slots) {
            transition(app, to: .approved, now: now)
            // 注意:递补走 .approved 不是 .autoApproved,
            // 因为它是发起人原意接受队列的延伸
        }
    }
}
```

### 5.5 调用顺序保证

`runFallbackChecks` 内部:

```swift
runApprovalDeadlines(now: now)
promoteWaitlist(now: now)
persist()
emitNotifications(now: now)
```

`approve` / `reject` / `cancelApplication` 末尾也调 `promoteWaitlist`(不带去抖)+ `persist`。

### 5.6 调试入口

`#if DEBUG` 包裹,我的约球右上角隐藏菜单(长按):

- `⏩ 跳到所有 deadline 之后`(传 `now = farFuture` 给 `runFallbackChecks`)
- `🔧 强制递补 waitlist`

Release build 自动剥离。

---

## 6. UI 变更

### 6.1 发布表单(`CreateMatchView`)

新增 section,位置:水平要求 ↔ 费用之间(**不**塞折叠的「高级选项」)。

```
┌─────────────────────────────┐
│  审核报名                       │
│  ☐ 需要我审核报名者(默认关)        │
│  💡 开启后,报名者需等你接受;        │
│     12h 内未处理,系统自动通过。      │
│  → 将于 5/3 19:00 自动处理        │
└─────────────────────────────┘
```

- caption 动态显示 `approvalDeadline`
- `totalLeadTime < 30min` → 开关 disabled + 灰提示「时间太短,无法开启审核」

### 6.2 报名者视角

**SignUpConfirmSheet** 文案分支:

| 球局类型       | 主按钮     | 副标题                              |
| -------------- | ---------- | ----------------------------------- |
| 自动通过(默认) | `确认报名` | `提交后立即占位`                    |
| 需要审核       | `提交申请` | `等发起人接受,12h 未处理将自动通过` |

**我的约球 - pending 卡片**:

```
┌────────────────────────────────────┐
│  🟠 等待发起人审核                       │
│  约 3 小时后自动通过                     │
│  [撤回申请]                              │
└────────────────────────────────────┘
```

- 倒计时用 `TimelineView(.everyMinute)`,不开真实 timer
- 「撤回申请」用 `confirmationDialog`(底部弹出),文案:`确认撤回?` / `撤回后名额释放,可重新报名` / `[撤回] [取消]`
- 自动通过到达后,卡片状态升级 + 顶部一次性 banner:`✨ 你的申请已自动通过`

### 6.3 Host 视角

**入口**:`MatchDetailView`,条件 `match.hostID == userStore.profile.id && match.requiresApproval`。

**未满员**:

- 详情页底部新 section 「**待审核 (3)**」,列表项 = applicant name + ntrp + 申请时间
- 每行右侧:`✅ 接受` `❌ 拒绝`
- `now > approvalDeadline - 2h` → 顶部 banner:`⚠️ 2 小时内未处理将自动通过 3 名申请者`

**已满员**:

- section 标题改为「候补队列 (2)」(状态 `.waitlisted`)
- 按钮变为 `⬆️ 提前补位` / `❌ 拒绝`

### 6.4 通知中心(`NotificationStore`)

新增 6 种 kind:

```swift
case applicationReceived       // host: 有人报名了
case approvalDeadlineSoon      // host: 你还没处理,2h 后自动通过
case applicationAutoApproved   // applicant: 自动通过了
case applicationRejected       // applicant: 被拒了
case waitlistedToApproved      // applicant: 候补递补成功
case applicationExpired        // applicant: 球局过期未处理
```

**合并策略**:`MatchNotification` 加 `coalesceKey: String?`。同 key 的写入**覆盖**而非新增。Host 进过详情页 → 该 key 通知 mark seen,下次新申请重新生成。

例:host 收到 3 条 `applicationReceived`(同 matchID) → 合并为「`小李` 等 3 人申请了你的球局」。

### 6.5 空状态 / 边界

- Host 开了审核但无人报名 → section 显示「空空如也,等待报名中…」
- 球局被 host 取消 → applicant 状态 `.rejected` + note = `"球局已取消"`,卡片置灰
- 倒计时穿越 0 → caption 改「即将自动处理…」(下次 App 进前台触发)

### 6.6 不做(明确划线)

- ❌ 不做 push 通知(NotificationStore 仅 in-app)
- ❌ 不做 sound / haptic
- ❌ 不做「批量接受全部」按钮(v2 候选)

---

## 7. 测试策略

### 7.1 测试 target

新建 `TennisMatchTests`(XCTest)—— 项目首个测试 target。

### 7.2 必测(TDD 写)

| 测试                                                    | 覆盖                                            |
| ------------------------------------------------------- | ----------------------------------------------- |
| `test_approvalDeadline_normalLeadTime_clampsTo12h`      | 提前 3 天 → deadline = startDate - 12h          |
| `test_approvalDeadline_shortLeadTime_clampsToHalf`      | 提前 5h → deadline = startDate - 2.5h           |
| `test_approvalDeadline_underHalfHour_disallowsApproval` | 提前 20min + 开审核 → 应拒绝                    |
| `test_runApprovalDeadlines_autoApprovesPendingWithSlot` | 有空位 + 过 deadline → autoApproved             |
| `test_runApprovalDeadlines_waitlistsWhenFull`           | 满员 + 过 deadline → waitlisted                 |
| `test_runApprovalDeadlines_expiresWhenMatchPassed`      | 球局过期 → expired                              |
| `test_runApprovalDeadlines_FIFOOrder`                   | 3 人抢 2 位,前两个 autoApproved,第三 waitlisted |
| `test_promoteWaitlist_promotesOnReject`                 | host 拒绝后 → 候补头部 → approved               |
| `test_promoteWaitlist_promotesOnCancel`                 | approved 撤回 → 候补递补                        |
| `test_cancelApplication_pendingNoCreditPenalty`         | 撤回 → status = cancelledBySelf,信用分契约不变  |
| `test_debounce_runFallbackChecks_within2s_skips`        | 连调两次 → 第二次 noop                          |
| `test_stateTransitions_illegal_throws`                  | `approved → pendingReview` 拒绝                 |

**核心 4 条 TDD 写**(测试先于实现):deadline 计算、auto-approve、waitlist 递补、FIFO。其余实现完后补。

### 7.3 时间注入

`BookingStore` 内部所有时间判断走 `now: Date` 形参,**禁止内部直接调 `Date()`**。view 层用 `.now` 不受限。

### 7.4 不测

- SwiftUI view 渲染(snapshot)
- NotificationStore 文案(只测 kind / 数量)
- UserDefaults 持久化(信任 Apple)

### 7.5 手动 UI 测试清单(发版前过)

- [ ] 发布表单开「需审核」→ caption 显示正确 deadline
- [ ] 发布短局(< 30min)→ 开关被 disabled
- [ ] 报名 pending 局 → 我的约球显示倒计时
- [ ] 撤回 → confirmationDialog 出现 → 撤回后状态消失
- [ ] Host 进详情页 → 看到待审核列表
- [ ] Host 接受到满员 → 后续 pending 显示「候补队列」
- [ ] 改系统时间至 deadline 之后,杀 App 重启 → 自动通过生效
- [ ] Debug 按钮「跳到 deadline 之后」→ 一键看到所有兜底分支
- [ ] Approved 报名者撤回 → 候补头部递补成功 + 通知触发
- [ ] Host 收到 3 条申请通知 → 合并显示「小李 等 3 人申请了你的球局」

---

## 8. 不在范围(显式声明)

- 信用分系统(扣分规则、爽约判定)→ 任务 #2
- 时间冲突 pending 软占用 / confirmed 硬占用 → 任务 #2
- 并发抢名额回退 UI → 任务 #3
- 推送(APNs)、本地通知 → 后端接入后做
- 「批量接受」、「拒绝理由模板」→ v2 候选

---

## 9. 后续步骤

进入 `writing-plans` skill,把本 spec 拆成可执行 implementation plan。
