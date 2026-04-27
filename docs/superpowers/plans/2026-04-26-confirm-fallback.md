# 确认环节兜底机制 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给 TennisMatch 加可选的「需审核报名」流程,T-12h 未审核自动通过,满员转 waitlist 自动递补;一刀替换现有 `BookingStore.accepted[]` 为后端友好的 `applications: [MatchApplication]`。

**Architecture:**

- 新建 `BookingApprovalStatus` 状态机 + `MatchApplication` 模型(后端友好,自带 applicantID/hostID UUID)。
- `BookingStore` 全文重写:`applications` 作为唯一来源,`accepted` 派生为纯 UI ViewModel。
- 兜底触发器在 view `onAppear` + App `scenePhase=.active` 调用,2s 去抖,无 timer。
- TDD 核心 4 条(deadline 计算 / auto-approve / waitlist / FIFO),其余写完补测。

**Tech Stack:** Swift 5.x / SwiftUI / `@Observable` / XCTest / UserDefaults 持久化

**Spec:** `docs/superpowers/specs/2026-04-26-confirm-fallback-design.md`

---

## 执行进度(Execution Tracker)

> 单一来源:Task 完成后在下方表格 + 对应 Task 标题旁打勾,不要写在别处。
> 工作分支:`feat/confirm-fallback`(worktree:`.worktrees/confirm-fallback`)。

### 7-Step Roadmap

| Step           | 范围                                                  | 涵盖 Task  | 状态    |
| -------------- | ----------------------------------------------------- | ---------- | ------- |
| ① 收尾 Phase A | UserProfile.id + MatchRegistrant 抽离                 | 4, 5       | ✅ done |
| ② 收尾 Phase B | MockMatch 加 hostID/requiresApproval/approvalDeadline | 6          | ✅ done |
| ③ Phase C-上   | BookingStore 骨架 + apply/approve/reject              | 8, 9       | ✅ done |
| ④ Phase C-下   | deadline / waitlist / 去抖(TDD 核心)                  | 10, 11, 12 | ✅ done |
| ⑤ Phase D      | View 全量迁移到 applications                          | 13–17      | ⬜ todo |
| ⑥ Phase E      | 新 UI:CreateMatch / MatchDetail host 区块 / 通知      | 18, 19, 20 | ⬜ todo |
| ⑦ Phase F      | scenePhase + debug + 全测 + 手动 checklist            | 21, 22, 23 | ⬜ todo |

> Tasks 1–11 在 2026-04-26 期间已先在 `feat/confirm-fallback` 分支完成,后于 main 上重做了 Task 2/3/7(commit `547e9a9`、`c83bc9d`)— 这两笔与本分支内容重复,合并到 main 时统一处理。

### Task 级清单

- ✅ Task 1 · TennisMatchTests target(commit `980084f`)
- ✅ Task 2 · BookingApprovalStatus(commit `5c5c8d2`;main 重做于 `547e9a9`)
- ✅ Task 3 · ApprovalDeadlineCalculator(commit `1955391`;main 重做于 `547e9a9`)
- ✅ Task 4 · UserProfile.id(commit `3f6eaf8`)
- ✅ Task 5 · MatchRegistrant.id 抽离(commit `370a816`)
- ✅ Task 6 · MockMatch hostID/requiresApproval/approvalDeadline(commit `dd8a683`)
- ✅ Task 7 · MatchApplication 模型(commit `3aad8ab`;main 重做于 `c83bc9d`)
- ✅ Task 8 · BookingStore 骨架(commit `43d2f4d`)
- ✅ Task 9 · approve / reject / cancelApplication API(commit `fb31750`)
- ✅ Task 10 · runApprovalDeadlines(commit `589d0ce`)
- ✅ Task 11 · promoteWaitlist(commit `8d9a77d`)
- ✅ Task 12 · runFallbackChecks + 去抖(commit `66e44ae`,13/13 测试 PASS)
- ⬜ Task 13 · HomeView 改用 apply
- ⬜ Task 14 · SignUpConfirmSheet 文案分支
- ⬜ Task 15 · MyMatchesView 消费 applications + pending 卡片
- ⬜ Task 16 · MessagesView AcceptedMatchInfo 派生
- ⬜ Task 17 · 删除 deprecated wrapper(可选)
- ⬜ Task 18 · CreateMatchView「审核报名」section
- ⬜ Task 19 · MatchDetailView host 审核区块
- ⬜ Task 20 · NotificationStore kinds + coalesceKey
- ⬜ Task 21 · TennisMatchApp scenePhase 监听
- ⬜ Task 22 · Debug 隐藏菜单
- ⬜ Task 23 · 全量测试 + 手动 UI checklist

### 进度日志

- **2026-04-27**:核对发现旧分支已完成 Tasks 1–11(11 commits,26 测试 PASS),复用之;后续从 Task 12 起在 `feat/confirm-fallback` 上推进。
- **2026-04-27**:Task 12(runFallbackChecks + 2s 去抖)完成 — commit `66e44ae`,subagent 实现,13/13 PASS。Phase C 整段收尾 ✅。下一步 Step ⑤ Phase D。

---

## File Structure

### 新建文件

| 文件                                                     | 职责                                             |
| -------------------------------------------------------- | ------------------------------------------------ |
| `TennisMatch/Models/BookingApprovalStatus.swift`         | 状态枚举 + 合法转换矩阵 + transition validator   |
| `TennisMatch/Models/MatchApplication.swift`              | Codable 模型(后端友好字段)                       |
| `TennisMatch/Models/ApprovalDeadlineCalculator.swift`    | 纯函数:发布参数 → `Date?` deadline               |
| `TennisMatchTests/BookingApprovalStatusTests.swift`      | 状态转换合法性                                   |
| `TennisMatchTests/ApprovalDeadlineCalculatorTests.swift` | deadline 边界 case                               |
| `TennisMatchTests/BookingStoreApprovalTests.swift`       | apply/approve/reject/cancel/runApprovalDeadlines |
| `TennisMatchTests/BookingStoreWaitlistTests.swift`       | promoteWaitlist + 递补触发                       |
| `TennisMatchTests/Helpers/MockBuilders.swift`            | test fixtures(MockMatch / MatchApplication)      |

### 修改文件

| 文件                                         | 改动                                                                                      |
| -------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `TennisMatch/Models/UserStore.swift`         | `var id: UUID` + UserDefaults 持久化                                                      |
| `TennisMatch/Models/BookingStore.swift`      | 全文重写,删 accepted/signedUpMatchIDs                                                     |
| `TennisMatch/Models/SignUpMatchInfo.swift`   | `AcceptedMatchInfo` 改为派生 ViewModel                                                    |
| `TennisMatch/Models/NotificationStore.swift` | 新增 6 种 kind + `coalesceKey: String?`                                                   |
| `TennisMatch/Views/Home/MockMatchData.swift` | MockMatch 加 hostID/requiresApproval/approvalDeadline;MatchRegistrant 移到独立文件并加 id |
| `TennisMatch/Views/HomeView.swift`           | signUp → apply,SignUpConfirmSheet 文案分支                                                |
| `TennisMatch/Views/MyMatchesView.swift`      | acceptedMatchItems 改读 applications;pending 卡片 UI                                      |
| `TennisMatch/Views/MessagesView.swift`       | AcceptedMatchInfo 派生消费                                                                |
| `TennisMatch/Views/CreateMatchView.swift`    | 「审核报名」section + deadline caption                                                    |
| `TennisMatch/Views/MatchDetailView.swift`    | host 审核区块 + deadline banner                                                           |
| `TennisMatch/TennisMatchApp.swift`           | scenePhase listener                                                                       |

### 项目层

| 改动                    | 描述                                               |
| ----------------------- | -------------------------------------------------- |
| `TennisMatch.xcodeproj` | 新建 `TennisMatchTests` test target(Xcode UI 操作) |

---

## Phase A · 测试基建与基础类型

### Task 1: 在 Xcode 添加 TennisMatchTests target

**Files:**

- Modify: `TennisMatch.xcodeproj/project.pbxproj`(由 Xcode UI 自动改)
- Create: `TennisMatchTests/TennisMatchTests.swift`(Xcode 默认产物,内容会被替换)

> 说明:`.xcodeproj` 不能脚本编辑。这一步必须在 Xcode UI 操作,后续步骤就能命令行 build/test。

- [ ] **Step 1: 在 Xcode 添加 Unit Test target**

操作:

1. 打开 `/Users/xue/AppProjects/TennisMatch/TennisMatch.xcodeproj`
2. File → New → Target → iOS → Unit Testing Bundle
3. Product Name: `TennisMatchTests`,Target to be Tested: `TennisMatch`,Language: Swift
4. Finish

- [ ] **Step 2: 验证 test target 可运行**

Run:

```
xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch \
    -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing TennisMatchTests
```

Expected: 1 test passes (Xcode 默认 stub `testExample`)。

- [ ] **Step 3: 删除 Xcode 默认 stub,留空文件**

Replace `TennisMatchTests/TennisMatchTests.swift` with:

```swift
import XCTest
@testable import TennisMatch

final class TennisMatchTests: XCTestCase {
    func test_smoke_targetCompiles() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 4: 验证编译**

Run: `xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing TennisMatchTests/TennisMatchTests/test_smoke_targetCompiles`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add TennisMatch.xcodeproj TennisMatchTests
git commit -m "test: add TennisMatchTests target"
```

---

### Task 2: BookingApprovalStatus 状态机

**Files:**

- Create: `TennisMatch/Models/BookingApprovalStatus.swift`
- Create: `TennisMatchTests/BookingApprovalStatusTests.swift`

- [ ] **Step 1: 写失败测试(状态枚举完整 + 合法转换)**

Create `TennisMatchTests/BookingApprovalStatusTests.swift`:

```swift
import XCTest
@testable import TennisMatch

final class BookingApprovalStatusTests: XCTestCase {

    func test_legalTransition_pendingReviewToApproved() {
        XCTAssertTrue(BookingApprovalStatus.pendingReview.canTransition(to: .approved))
    }

    func test_legalTransition_pendingReviewToAutoApproved() {
        XCTAssertTrue(BookingApprovalStatus.pendingReview.canTransition(to: .autoApproved))
    }

    func test_legalTransition_waitlistedToApproved() {
        XCTAssertTrue(BookingApprovalStatus.waitlisted.canTransition(to: .approved))
    }

    func test_illegalTransition_approvedToPendingReview() {
        XCTAssertFalse(BookingApprovalStatus.approved.canTransition(to: .pendingReview))
    }

    func test_illegalTransition_anyToAutoApproved_exceptPending() {
        for from in BookingApprovalStatus.allCases where from != .pendingReview {
            XCTAssertFalse(from.canTransition(to: .autoApproved),
                          "\(from) → autoApproved should be illegal")
        }
    }

    func test_terminalStates_cannotTransitionOut() {
        let terminals: [BookingApprovalStatus] = [
            .approved, .rejected, .cancelledBySelf, .expired, .autoApproved, .autoConfirmed
        ]
        for from in terminals {
            for to in BookingApprovalStatus.allCases where from != to {
                XCTAssertFalse(from.canTransition(to: to),
                              "\(from) is terminal, cannot go to \(to)")
            }
        }
    }
}
```

- [ ] **Step 2: 跑测试,确认失败**

Run: `xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing TennisMatchTests/BookingApprovalStatusTests`
Expected: 编译错误「Cannot find 'BookingApprovalStatus' in scope」。

- [ ] **Step 3: 实现状态枚举**

Create `TennisMatch/Models/BookingApprovalStatus.swift`:

```swift
import Foundation

/// 报名条目的审核状态。独立于 `MyMatchStatus`(后者是球局自身的满员状态)。
enum BookingApprovalStatus: String, Codable, CaseIterable {
    case autoConfirmed     // 球局未开审核,直接确认(默认行为)
    case pendingReview     // 已申请,等发起人审核
    case approved          // 审核通过,占名额
    case rejected          // 被拒(host 主动 / 满员转拒)
    case waitlisted        // 满员被挤到候补
    case cancelledBySelf   // 报名者主动撤回
    case autoApproved      // 超时兜底自动接受
    case expired           // 球局已过期,从未审核

    /// 该状态是否允许迁出。
    var isTerminal: Bool {
        switch self {
        case .approved, .rejected, .cancelledBySelf, .expired, .autoApproved, .autoConfirmed:
            return true
        case .pendingReview, .waitlisted:
            return false
        }
    }

    /// 是否合法转换到 `to`。
    func canTransition(to: BookingApprovalStatus) -> Bool {
        guard !isTerminal else { return false }
        switch (self, to) {
        case (.pendingReview, .approved),
             (.pendingReview, .rejected),
             (.pendingReview, .waitlisted),
             (.pendingReview, .autoApproved),
             (.pendingReview, .cancelledBySelf),
             (.pendingReview, .expired):
            return true
        case (.waitlisted, .approved),
             (.waitlisted, .cancelledBySelf),
             (.waitlisted, .expired):
            return true
        default:
            return false
        }
    }
}
```

- [ ] **Step 4: 跑测试,确认通过**

Run: 同 Step 2
Expected: 6 tests PASS

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/BookingApprovalStatus.swift TennisMatchTests/BookingApprovalStatusTests.swift
git commit -m "feat(booking): BookingApprovalStatus 状态机 + 合法转换"
```

---

### Task 3: ApprovalDeadlineCalculator(纯函数,TDD 核心 #1)

**Files:**

- Create: `TennisMatch/Models/ApprovalDeadlineCalculator.swift`
- Create: `TennisMatchTests/ApprovalDeadlineCalculatorTests.swift`

- [ ] **Step 1: 写失败测试**

Create `TennisMatchTests/ApprovalDeadlineCalculatorTests.swift`:

```swift
import XCTest
@testable import TennisMatch

final class ApprovalDeadlineCalculatorTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func test_normalLeadTime_clampsTo12h() {
        // 提前 3 天发布
        let start = now.addingTimeInterval(3 * 24 * 3600)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertEqual(deadline, start.addingTimeInterval(-12 * 3600))
    }

    func test_shortLeadTime_clampsToHalf() {
        // 提前 5h 发布 → deadline = start - 2.5h
        let start = now.addingTimeInterval(5 * 3600)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertEqual(deadline, start.addingTimeInterval(-2.5 * 3600))
    }

    func test_underHalfHour_returnsNil() {
        // 提前 20min,不允许开审核
        let start = now.addingTimeInterval(20 * 60)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertNil(deadline)
    }

    func test_requiresApprovalFalse_returnsNil() {
        let start = now.addingTimeInterval(3 * 24 * 3600)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: false, publishedAt: now, startDate: start
        )
        XCTAssertNil(deadline)
    }

    func test_canEnableApproval_underHalfHourFalse() {
        let start = now.addingTimeInterval(20 * 60)
        XCTAssertFalse(ApprovalDeadlineCalculator.canEnableApproval(
            publishedAt: now, startDate: start
        ))
    }

    func test_canEnableApproval_atHalfHourTrue() {
        let start = now.addingTimeInterval(31 * 60)
        XCTAssertTrue(ApprovalDeadlineCalculator.canEnableApproval(
            publishedAt: now, startDate: start
        ))
    }
}
```

- [ ] **Step 2: 跑测试,确认失败**

Run: `xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing TennisMatchTests/ApprovalDeadlineCalculatorTests`
Expected: 编译错误「Cannot find 'ApprovalDeadlineCalculator'」。

- [ ] **Step 3: 实现**

Create `TennisMatch/Models/ApprovalDeadlineCalculator.swift`:

```swift
import Foundation

/// 计算「审核截止时间」的纯函数。无状态、可独立测试。
enum ApprovalDeadlineCalculator {

    /// 短局阈值:总时长 < 此值时不允许开审核。
    static let minLeadTimeForApproval: TimeInterval = 30 * 60   // 30 min

    /// 自动审核窗口上限。
    static let maxApprovalWindow: TimeInterval = 12 * 3600      // 12h

    /// 计算自动接受触发时间。`requiresApproval == false` 或 lead time 太短 → nil。
    static func deadline(
        requiresApproval: Bool,
        publishedAt: Date,
        startDate: Date
    ) -> Date? {
        guard requiresApproval else { return nil }
        let leadTime = startDate.timeIntervalSince(publishedAt)
        guard leadTime >= minLeadTimeForApproval else { return nil }
        let window = min(maxApprovalWindow, leadTime / 2)
        return startDate.addingTimeInterval(-window)
    }

    /// 当前发布参数下能否启用审核(用于 UI 锁开关)。
    static func canEnableApproval(publishedAt: Date, startDate: Date) -> Bool {
        startDate.timeIntervalSince(publishedAt) >= minLeadTimeForApproval
    }
}
```

- [ ] **Step 4: 跑测试,确认通过**

Run: 同 Step 2
Expected: 6 tests PASS

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/ApprovalDeadlineCalculator.swift TennisMatchTests/ApprovalDeadlineCalculatorTests.swift
git commit -m "feat(booking): ApprovalDeadlineCalculator 纯函数 + 测试"
```

---

### Task 4: UserProfile.id

**Files:**

- Modify: `TennisMatch/Models/UserStore.swift`
- Modify: `TennisMatchTests/TennisMatchTests.swift`(增 smoke 测)

- [ ] **Step 1: 写测试**

Append to `TennisMatchTests/TennisMatchTests.swift`:

```swift
extension TennisMatchTests {
    @MainActor
    func test_userStore_hasStableID() {
        let key = "userStore.id"
        UserDefaults.standard.removeObject(forKey: key)

        let s1 = UserStore()
        let id1 = s1.id

        let s2 = UserStore()
        let id2 = s2.id

        XCTAssertEqual(id1, id2, "id 应在 init 间稳定(从 UserDefaults 读)")
    }
}
```

- [ ] **Step 2: 跑测试,确认失败**

Run: `xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing TennisMatchTests/TennisMatchTests/test_userStore_hasStableID`
Expected: 编译错误「Value of type 'UserStore' has no member 'id'」。

- [ ] **Step 3: 给 UserStore 加 id**

In `TennisMatch/Models/UserStore.swift`:

- 在 `final class UserStore {` 之后(`var displayName` 之前)加:

```swift
private static let idKey = "userStore.id"

/// 当前用户稳定 ID。首次启动生成并写入 UserDefaults,跨启动稳定。
let id: UUID
```

- 在 `init(...)` 内最末尾加:

```swift
        if let saved = UserDefaults.standard.string(forKey: Self.idKey),
           let uuid = UUID(uuidString: saved) {
            self.id = uuid
        } else {
            let new = UUID()
            UserDefaults.standard.set(new.uuidString, forKey: Self.idKey)
            self.id = new
        }
```

> 注意:`let id` 的初始化必须在所有 `self.X = X` 之后才能写,但因为 `id` 不是参数,它可以放最后。Swift 允许 `let` 在 init 内单次赋值。

- [ ] **Step 4: 跑测试,确认通过**

Run: 同 Step 2
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/UserStore.swift TennisMatchTests/TennisMatchTests.swift
git commit -m "feat(user): UserProfile.id 持久化(后端友好建模)"
```

---

### Task 5: MatchRegistrant.id 抽离到独立文件

**Files:**

- Create: `TennisMatch/Models/MatchRegistrant.swift`
- Modify: `TennisMatch/Views/MyMatchesView.swift`(删除原定义,加 id)

- [ ] **Step 1: 找出 MatchRegistrant 当前位置**

Run: `grep -n "struct MatchRegistrant" TennisMatch/Views/MyMatchesView.swift`
Expected: `1212:struct MatchRegistrant {`

- [ ] **Step 2: 新建独立文件**

Create `TennisMatch/Models/MatchRegistrant.swift`:

```swift
import Foundation

/// 球局中的报名/参与者。后端友好建模:`id: UUID` 用于 `MatchApplication.applicantID` 引用。
struct MatchRegistrant: Identifiable, Hashable {
    let id: UUID
    let name: String
    let gender: Gender
    let ntrp: String
    let isOrganizer: Bool

    init(
        id: UUID = UUID(),
        name: String,
        gender: Gender,
        ntrp: String,
        isOrganizer: Bool
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.ntrp = ntrp
        self.isOrganizer = isOrganizer
    }
}
```

- [ ] **Step 3: 删除 MyMatchesView 中的旧定义**

In `TennisMatch/Views/MyMatchesView.swift`,删除:

```swift
struct MatchRegistrant {
    let name: String
    let gender: Gender
    let ntrp: String
    let isOrganizer: Bool
}
```

(约第 1212-1217 行)

- [ ] **Step 4: 编译**

Run: `xcodebuild build -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: BUILD SUCCEEDED(default initializer 调用兼容,因为新版 init 的所有非 id 参数顺序相同)

> 如有调用方手写 `MatchRegistrant(name:gender:ntrp:isOrganizer:)` —— 兼容(默认 id 参数)。

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/MatchRegistrant.swift TennisMatch/Views/MyMatchesView.swift
git commit -m "refactor(model): MatchRegistrant 抽离独立文件 + 加 id: UUID"
```

---

## Phase B · 新模型

### Task 6: MockMatch 增 hostID/requiresApproval/approvalDeadline

**Files:**

- Modify: `TennisMatch/Views/Home/MockMatchData.swift`

- [ ] **Step 1: 给 MockMatch 加字段**

In `TennisMatch/Views/Home/MockMatchData.swift`,`struct MockMatch` 内,`var isOwnMatch: Bool = false` 之后加:

```swift
    /// 球局发起人 ID(对应 UserStore.id)。mock seed 写死;真后端从 host 关系拉。
    var hostID: UUID = UUID()
    /// 发起人是否要求审核报名者。默认关 — 兼容现有「自动通过」体验。
    var requiresApproval: Bool = false
    /// 自动接受触发时间。发布时一次算定,nil 表示不需要审核或 lead time 太短。
    var approvalDeadline: Date? = nil
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild build -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: BUILD SUCCEEDED(所有字段有默认值,现有调用不破)

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/Home/MockMatchData.swift
git commit -m "feat(match): MockMatch 增 hostID/requiresApproval/approvalDeadline"
```

---

### Task 7: MatchApplication 模型

**Files:**

- Create: `TennisMatch/Models/MatchApplication.swift`
- Create: `TennisMatchTests/Helpers/MockBuilders.swift`

- [ ] **Step 1: 实现 MatchApplication**

Create `TennisMatch/Models/MatchApplication.swift`:

```swift
import Foundation

/// 报名申请条目。后端友好建模 — 字段命名直接对齐 REST schema。
/// `POST /api/applications` 的 body 就是这个结构。
struct MatchApplication: Identifiable, Codable, Hashable {
    let id: UUID
    let matchID: UUID
    let applicantID: UUID
    let hostID: UUID            // 冗余,便于查询
    var status: BookingApprovalStatus
    let appliedAt: Date
    var resolvedAt: Date?
    var resolvedBy: UUID?       // host 接受 = hostID;系统兜底 = nil;自撤 = applicantID
    var note: String?           // host 拒绝时的可选理由

    init(
        id: UUID = UUID(),
        matchID: UUID,
        applicantID: UUID,
        hostID: UUID,
        status: BookingApprovalStatus,
        appliedAt: Date = .now,
        resolvedAt: Date? = nil,
        resolvedBy: UUID? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.matchID = matchID
        self.applicantID = applicantID
        self.hostID = hostID
        self.status = status
        self.appliedAt = appliedAt
        self.resolvedAt = resolvedAt
        self.resolvedBy = resolvedBy
        self.note = note
    }
}
```

- [ ] **Step 2: 写测试 fixture helper**

Create `TennisMatchTests/Helpers/MockBuilders.swift`:

```swift
import Foundation
@testable import TennisMatch

enum MockBuilders {
    static let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)

    static func match(
        startsIn seconds: TimeInterval = 3 * 24 * 3600,
        maxPlayers: Int = 4,
        currentPlayers: Int = 1,
        requiresApproval: Bool = true,
        publishedAt: Date = fixedNow,
        hostID: UUID = UUID()
    ) -> MockMatch {
        let start = publishedAt.addingTimeInterval(seconds)
        var m = MockMatch(
            name: "Host",
            gender: .male,
            matchType: "單打",
            weather: "☀️",
            dateTime: "test",
            startDate: start,
            location: "Court 1",
            fee: "AA",
            ntrpLow: 3.0,
            ntrpHigh: 4.0,
            ageRange: "26-35",
            genderLabel: "不限",
            hour: 10,
            dayOfWeek: "一",
            currentPlayers: currentPlayers,
            maxPlayers: maxPlayers
        )
        m.hostID = hostID
        m.requiresApproval = requiresApproval
        m.approvalDeadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: requiresApproval,
            publishedAt: publishedAt,
            startDate: start
        )
        return m
    }

    static func application(
        matchID: UUID,
        applicantID: UUID = UUID(),
        hostID: UUID,
        status: BookingApprovalStatus = .pendingReview,
        appliedAt: Date = fixedNow
    ) -> MatchApplication {
        MatchApplication(
            matchID: matchID,
            applicantID: applicantID,
            hostID: hostID,
            status: status,
            appliedAt: appliedAt
        )
    }
}
```

- [ ] **Step 3: 编译 + smoke test**

Run: `xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing TennisMatchTests`
Expected: 现有测试 PASS,新模型可被引用。

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Models/MatchApplication.swift TennisMatchTests/Helpers/MockBuilders.swift
git commit -m "feat(booking): MatchApplication 模型 + test fixtures"
```

---

## Phase C · BookingStore 重写(TDD 核心)

### Task 8: BookingStore 骨架(applications + 派生 helper)

**Files:**

- Modify: `TennisMatch/Models/BookingStore.swift`(全文重写)
- Create: `TennisMatchTests/BookingStoreApprovalTests.swift`

> 注意:本 task 的实现会让 `HomeView`/`MyMatchesView`/`MessagesView` 暂时编译失败 —— 它们还在用旧 API。Phase D 会修。这是「一刀替换」的代价,中间提交允许编译失败需视项目惯例,这里**用类型 alias + deprecated wrapper 让中间状态可编译**。

- [ ] **Step 1: 写失败测试(应用 apply API)**

Create `TennisMatchTests/BookingStoreApprovalTests.swift`:

```swift
import XCTest
@testable import TennisMatch

@MainActor
final class BookingStoreApprovalTests: XCTestCase {

    var store: BookingStore!
    let userID = UUID()

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        store = BookingStore(currentUserID: userID)
    }

    func test_apply_autoConfirmsWhenApprovalNotRequired() {
        let match = MockBuilders.match(requiresApproval: false)
        store.registerMatch(match)

        let app = store.apply(to: match, now: MockBuilders.fixedNow)

        XCTAssertEqual(app.status, .autoConfirmed)
        XCTAssertEqual(store.applications.count, 1)
    }

    func test_apply_pendingReviewWhenApprovalRequired() {
        let match = MockBuilders.match(requiresApproval: true)
        store.registerMatch(match)

        let app = store.apply(to: match, now: MockBuilders.fixedNow)

        XCTAssertEqual(app.status, .pendingReview)
    }

    func test_apply_rejectsDuplicateApplication() {
        let match = MockBuilders.match(requiresApproval: true)
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)

        let dup = store.apply(to: match, now: MockBuilders.fixedNow)

        XCTAssertEqual(dup.status, .pendingReview, "重复申请应返回现有条目")
        XCTAssertEqual(store.applications.count, 1, "不应新增")
    }
}
```

- [ ] **Step 2: 跑测试,确认编译失败**

Run: `xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing TennisMatchTests/BookingStoreApprovalTests`
Expected: 编译错误「'BookingStore' has no initializer 'init(currentUserID:)'」。

- [ ] **Step 3: 重写 BookingStore.swift**

Replace `TennisMatch/Models/BookingStore.swift` with:

```swift
//
//  BookingStore.swift
//  TennisMatch
//
//  Phase 2c: applications 作为唯一来源,替代旧 accepted[]/signedUpMatchIDs。
//  保留 externalSlots(mock 阶段的"已占用但不在 applications 里"的时段)。
//

import Foundation
import Observation

struct BookedSlot: Identifiable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    let label: String
}

enum SignUpResult: Equatable {
    case ok
    case alreadySignedUp
    case conflict(label: String)
}

enum AcceptResult: Equatable {
    case ok
    case conflict(label: String)
}

struct ConflictHit: Equatable {
    let id: UUID
    let label: String
}

@Observable
@MainActor
final class BookingStore {
    private static let applicationsKey = "bookingStore.applications"
    private static let debounceInterval: TimeInterval = 2.0

    private let currentUserID: UUID

    /// 唯一来源。所有 view 派生消费。
    private(set) var applications: [MatchApplication] = []

    /// MockMatch 索引(运行时注入,不持久化 — match data 由 view 拥有)。
    private var matches: [UUID: MockMatch] = [:]

    /// mock 阶段的"外部占用时段"。
    private(set) var externalSlots: [BookedSlot] = []

    private var lastFallbackRunAt: Date = .distantPast

    init(currentUserID: UUID) {
        self.currentUserID = currentUserID
        loadApplications()
    }

    // MARK: - Match registry

    func registerMatch(_ match: MockMatch) {
        matches[match.id] = match
    }

    func unregisterMatch(_ matchID: UUID) {
        matches.removeValue(forKey: matchID)
    }

    // MARK: - Apply

    @discardableResult
    func apply(to match: MockMatch, now: Date = .now) -> MatchApplication {
        registerMatch(match)
        if let existing = myApplication(for: match.id) {
            return existing
        }
        let initial: BookingApprovalStatus = match.requiresApproval ? .pendingReview : .autoConfirmed
        let app = MatchApplication(
            matchID: match.id,
            applicantID: currentUserID,
            hostID: match.hostID,
            status: initial,
            appliedAt: now
        )
        applications.append(app)
        persist()
        return app
    }

    // MARK: - Queries

    func myApplication(for matchID: UUID) -> MatchApplication? {
        applications.first(where: { $0.matchID == matchID && $0.applicantID == currentUserID })
    }

    func incomingApplications(for matchID: UUID) -> [MatchApplication] {
        applications
            .filter { $0.matchID == matchID && $0.applicantID != currentUserID }
            .sorted { $0.appliedAt < $1.appliedAt }
    }

    var myApprovedMatches: [UUID] {
        applications
            .filter { $0.applicantID == currentUserID && Self.occupiesSlot($0.status) }
            .map(\.matchID)
    }

    func isSignedUp(matchID: UUID) -> Bool {
        myApprovedMatches.contains(matchID) ||
            applications.contains(where: {
                $0.matchID == matchID && $0.applicantID == currentUserID && $0.status == .pendingReview
            })
    }

    // MARK: - External slots

    func registerExternal(_ slot: BookedSlot) {
        externalSlots.removeAll { $0.id == slot.id }
        externalSlots.append(slot)
    }

    func removeExternal(id: UUID) {
        externalSlots.removeAll { $0.id == id }
    }

    // MARK: - Conflict (内部改读 applications)

    func conflict(start: Date, end: Date, excluding: UUID? = nil) -> ConflictHit? {
        for app in applications where app.applicantID == currentUserID && Self.occupiesSlot(app.status) {
            guard app.matchID != excluding,
                  let m = matches[app.matchID] else { continue }
            let mEnd = m.startDate.addingTimeInterval(2 * 3600)
            if m.startDate < end && start < mEnd {
                return ConflictHit(id: app.matchID, label: "\(m.name) \(m.dateTimeDisplay)")
            }
        }
        for s in externalSlots where s.id != excluding && s.start < end && start < s.end {
            return ConflictHit(id: s.id, label: s.label)
        }
        return nil
    }

    // MARK: - Helpers

    static func occupiesSlot(_ status: BookingApprovalStatus) -> Bool {
        switch status {
        case .approved, .autoApproved, .autoConfirmed: return true
        default: return false
        }
    }

    /// 该 match 已占用名额数(不含 host 自己)。
    func approvedCount(for matchID: UUID) -> Int {
        applications.filter { $0.matchID == matchID && Self.occupiesSlot($0.status) }.count
    }

    // MARK: - Persistence

    private func loadApplications() {
        guard let data = UserDefaults.standard.data(forKey: Self.applicationsKey),
              let decoded = try? JSONDecoder().decode([MatchApplication].self, from: data) else {
            return
        }
        applications = decoded
    }

    fileprivate func persist() {
        guard let data = try? JSONEncoder().encode(applications) else { return }
        UserDefaults.standard.set(data, forKey: Self.applicationsKey)
    }

    // MARK: - 转换辅助(Phase D 之前用)

    /// 临时供旧 view 读取的「已加入」聚合视图。Phase D 完成后 view 改读 applications,该方法可删。
    func legacyAcceptedSnapshot() -> [MatchApplication] {
        applications.filter { $0.applicantID == currentUserID && Self.occupiesSlot($0.status) }
    }
}
```

- [ ] **Step 4: 修补现有 view 编译错误(临时 stub,Phase D 替换)**

旧调用方 `BookingStore()`、`signUp(matchID:info:)`、`acceptInvitation(_:)`、`cancel(acceptedID:)`、`accepted`、`signedUpMatchIDs` 都没了。给他们 stub:

In `TennisMatch/Models/BookingStore.swift` 末尾追加:

```swift
// MARK: - Legacy compat (Phase D 内逐步移除)

extension BookingStore {
    /// Deprecated wrapper — Phase D 完成后删。仅供未迁移的 view 临时编译。
    @available(*, deprecated, message: "Use apply(to:) instead. Phase D 内迁移。")
    @discardableResult
    func signUp(matchID: UUID, info: AcceptedMatchInfo) -> SignUpResult {
        // 找到对应 match — 若未注册过(legacy seed),用 info 反推一个 stub
        let host = matches[matchID]?.hostID ?? UUID()
        let initial: BookingApprovalStatus = matches[matchID]?.requiresApproval == true
            ? .pendingReview : .autoConfirmed
        if applications.contains(where: { $0.matchID == matchID && $0.applicantID == currentUserID }) {
            return .alreadySignedUp
        }
        if let hit = conflict(start: info.startDate, end: info.endDate, excluding: matchID) {
            return .conflict(label: hit.label)
        }
        applications.append(MatchApplication(
            matchID: matchID, applicantID: currentUserID, hostID: host,
            status: initial, appliedAt: .now
        ))
        persist()
        return .ok
    }

    @available(*, deprecated, message: "Use apply(to:) for invitations. Phase D 内迁移。")
    @discardableResult
    func acceptInvitation(_ info: AcceptedMatchInfo) -> AcceptResult {
        if let hit = conflict(start: info.startDate, end: info.endDate) {
            return .conflict(label: hit.label)
        }
        let mid = info.sourceMatchID ?? UUID()
        applications.append(MatchApplication(
            matchID: mid, applicantID: currentUserID, hostID: UUID(),
            status: .autoConfirmed, appliedAt: .now
        ))
        persist()
        return .ok
    }

    @available(*, deprecated, message: "Use cancelApplication(_:) instead. Phase D 内迁移。")
    @discardableResult
    func cancel(acceptedID: UUID) -> AcceptedMatchInfo? {
        // acceptedID 在新模型里 == application.id
        guard let idx = applications.firstIndex(where: { $0.id == acceptedID }) else { return nil }
        let removed = applications.remove(at: idx)
        persist()
        // 派生回旧 ViewModel 给调用方
        guard let m = matches[removed.matchID] else { return nil }
        return AcceptedMatchInfo(
            id: removed.id,
            organizerName: m.name,
            location: m.location,
            dateString: AppDateFormatter.monthDay.string(from: m.startDate),
            time: AppDateFormatter.hourMinute.string(from: m.startDate),
            startDate: m.startDate,
            endDate: m.startDate.addingTimeInterval(2*3600),
            sourceMatchID: removed.matchID
        )
    }

    /// Deprecated 派生:旧 view 仍读 `accepted` 数组。Phase D 完成后删。
    @available(*, deprecated, message: "派生自 applications。Phase D 内迁移到 applications 直读。")
    var accepted: [AcceptedMatchInfo] {
        legacyAcceptedSnapshot().compactMap { app in
            guard let m = matches[app.matchID] else { return nil }
            return AcceptedMatchInfo(
                id: app.id,
                organizerName: m.name,
                location: m.location,
                dateString: AppDateFormatter.monthDay.string(from: m.startDate),
                time: AppDateFormatter.hourMinute.string(from: m.startDate),
                startDate: m.startDate,
                endDate: m.startDate.addingTimeInterval(2*3600),
                sourceMatchID: app.matchID
            )
        }
    }

    @available(*, deprecated, message: "Use myApprovedMatches 或 isSignedUp(matchID:)")
    var signedUpMatchIDs: Set<UUID> { Set(myApprovedMatches) }
}
```

> 注意:`AcceptedMatchInfo` 当前的 `init` 签名以 `SignUpMatchInfo.swift` 中实际定义为准。如果字段不一致,这里需对齐(下个 task 处理 ViewModel 派生时再校对)。

- [ ] **Step 5: 修复 init 调用方(TennisMatchApp 等)**

Search: `grep -rn "BookingStore()" TennisMatch/`
For each match, change to:

```swift
BookingStore(currentUserID: userStore.id)
```

> 若 BookingStore 在某处被无 user 上下文构造(如纯预览),传 `UUID()`。

- [ ] **Step 6: 跑测试,确认通过**

Run: `xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing TennisMatchTests/BookingStoreApprovalTests`
Expected: 3 tests PASS

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Models/BookingStore.swift TennisMatch/TennisMatchApp.swift TennisMatchTests/BookingStoreApprovalTests.swift
git commit -m "refactor(booking): applications 作为唯一来源 + 旧 API deprecated wrapper"
```

---

### Task 9: approve / reject / cancelApplication API

**Files:**

- Modify: `TennisMatch/Models/BookingStore.swift`
- Modify: `TennisMatchTests/BookingStoreApprovalTests.swift`

- [ ] **Step 1: 写失败测试**

Append to `TennisMatchTests/BookingStoreApprovalTests.swift`:

```swift
extension BookingStoreApprovalTests {
    func test_approve_transitionsToApproved() {
        let match = MockBuilders.match(hostID: userID)
        store.registerMatch(match)
        // 别人申请我的局
        let app = MockBuilders.application(matchID: match.id, hostID: userID)
        store.applications.append(app)

        store.approve(applicationID: app.id, now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first?.status, .approved)
        XCTAssertEqual(store.applications.first?.resolvedBy, userID)
        XCTAssertNotNil(store.applications.first?.resolvedAt)
    }

    func test_reject_transitionsToRejectedWithNote() {
        let match = MockBuilders.match(hostID: userID)
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: userID)
        store.applications.append(app)

        store.reject(applicationID: app.id, note: "水平不匹配", now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first?.status, .rejected)
        XCTAssertEqual(store.applications.first?.note, "水平不匹配")
    }

    func test_cancelApplication_pendingNoCreditPenalty() {
        let match = MockBuilders.match()
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)
        let app = store.myApplication(for: match.id)!

        store.cancelApplication(app.id, now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first?.status, .cancelledBySelf)
        XCTAssertEqual(store.applications.first?.resolvedBy, userID)
    }

    func test_approve_illegalFromTerminal_noop() {
        let match = MockBuilders.match(hostID: userID)
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: userID, status: .approved)
        store.applications.append(app)

        store.approve(applicationID: app.id, now: MockBuilders.fixedNow)

        // 状态保持(不从 approved 再转 approved)
        XCTAssertEqual(store.applications.first?.status, .approved)
    }
}
```

- [ ] **Step 2: 跑测试,确认编译失败**

Run: 同 Task 8
Expected: 「has no member 'approve'」

- [ ] **Step 3: 实现**

In `TennisMatch/Models/BookingStore.swift`,在 `// MARK: - Apply` 之后插入:

```swift
    // MARK: - Host actions

    func approve(applicationID: UUID, now: Date = .now) {
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        guard applications[idx].status.canTransition(to: .approved) else { return }
        applications[idx].status = .approved
        applications[idx].resolvedAt = now
        applications[idx].resolvedBy = currentUserID
        persist()
    }

    func reject(applicationID: UUID, note: String? = nil, now: Date = .now) {
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        guard applications[idx].status.canTransition(to: .rejected) else { return }
        applications[idx].status = .rejected
        applications[idx].resolvedAt = now
        applications[idx].resolvedBy = currentUserID
        applications[idx].note = note
        persist()
    }

    // MARK: - Applicant actions

    func cancelApplication(_ id: UUID, now: Date = .now) {
        guard let idx = applications.firstIndex(where: { $0.id == id }) else { return }
        guard applications[idx].status.canTransition(to: .cancelledBySelf) else { return }
        applications[idx].status = .cancelledBySelf
        applications[idx].resolvedAt = now
        applications[idx].resolvedBy = currentUserID
        persist()
    }
```

> 注意:`approved` 是 terminal,不能 cancel(已知限制,见 spec §3)。`autoConfirmed` 也是 terminal — 现行行为是「不能从 my-matches 取消」。这与现有 `cancel(acceptedID:)` 行为不一致。Phase D 修 my-matches 时,改为允许 `autoConfirmed → cancelledBySelf`(给 `canTransition` 加规则)。当前 task 不动。

- [ ] **Step 4: 跑测试,确认通过**

Run: 同 Step 2
Expected: 4 tests PASS

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/BookingStore.swift TennisMatchTests/BookingStoreApprovalTests.swift
git commit -m "feat(booking): approve/reject/cancelApplication API"
```

---

### Task 10: runApprovalDeadlines(TDD 核心 #2)

**Files:**

- Modify: `TennisMatch/Models/BookingStore.swift`
- Modify: `TennisMatchTests/BookingStoreApprovalTests.swift`

- [ ] **Step 1: 写失败测试(包含 FIFO TDD 核心 #4)**

Append to `TennisMatchTests/BookingStoreApprovalTests.swift`:

```swift
extension BookingStoreApprovalTests {
    func test_runApprovalDeadlines_autoApprovesPendingWithSlot() {
        let match = MockBuilders.match(maxPlayers: 4, currentPlayers: 1)
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: match.hostID)
        store.applications.append(app)

        let afterDeadline = match.approvalDeadline!.addingTimeInterval(60)
        store.runApprovalDeadlines(now: afterDeadline)

        XCTAssertEqual(store.applications.first?.status, .autoApproved)
    }

    func test_runApprovalDeadlines_waitlistsWhenFull() {
        // 3 人空位,4 人 pending
        let match = MockBuilders.match(maxPlayers: 4, currentPlayers: 1)
        store.registerMatch(match)
        for _ in 0..<4 {
            store.applications.append(MockBuilders.application(
                matchID: match.id, hostID: match.hostID
            ))
        }

        let afterDeadline = match.approvalDeadline!.addingTimeInterval(60)
        store.runApprovalDeadlines(now: afterDeadline)

        let auto = store.applications.filter { $0.status == .autoApproved }
        let wait = store.applications.filter { $0.status == .waitlisted }
        XCTAssertEqual(auto.count, 3)
        XCTAssertEqual(wait.count, 1)
    }

    func test_runApprovalDeadlines_FIFOOrder() {
        let match = MockBuilders.match(maxPlayers: 3, currentPlayers: 1)
        store.registerMatch(match)
        // 三个 pending,2 个空位 — 早申请的两个应通过,晚的进 waitlist
        let early = MockBuilders.application(
            matchID: match.id, hostID: match.hostID,
            appliedAt: MockBuilders.fixedNow
        )
        let middle = MockBuilders.application(
            matchID: match.id, hostID: match.hostID,
            appliedAt: MockBuilders.fixedNow.addingTimeInterval(10)
        )
        let late = MockBuilders.application(
            matchID: match.id, hostID: match.hostID,
            appliedAt: MockBuilders.fixedNow.addingTimeInterval(20)
        )
        store.applications = [late, early, middle]   // 故意乱序

        let afterDeadline = match.approvalDeadline!.addingTimeInterval(60)
        store.runApprovalDeadlines(now: afterDeadline)

        XCTAssertEqual(store.applications.first(where: { $0.id == early.id })?.status, .autoApproved)
        XCTAssertEqual(store.applications.first(where: { $0.id == middle.id })?.status, .autoApproved)
        XCTAssertEqual(store.applications.first(where: { $0.id == late.id })?.status, .waitlisted)
    }

    func test_runApprovalDeadlines_expiresWhenMatchPassed() {
        let match = MockBuilders.match()  // 默认 3 天后开始
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: match.hostID)
        store.applications.append(app)

        // now > startDate
        store.runApprovalDeadlines(now: match.startDate.addingTimeInterval(60))

        XCTAssertEqual(store.applications.first?.status, .expired)
    }

    func test_runApprovalDeadlines_skipsBeforeDeadline() {
        let match = MockBuilders.match()
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: match.hostID)
        store.applications.append(app)

        // now < deadline
        let beforeDeadline = match.approvalDeadline!.addingTimeInterval(-60)
        store.runApprovalDeadlines(now: beforeDeadline)

        XCTAssertEqual(store.applications.first?.status, .pendingReview)
    }
}
```

- [ ] **Step 2: 跑测试,确认编译失败**

Run: 同 Task 8
Expected: 「has no member 'runApprovalDeadlines'」

- [ ] **Step 3: 实现**

In `TennisMatch/Models/BookingStore.swift`,在 `// MARK: - Helpers` 之前插入:

```swift
    // MARK: - Fallback: deadline scan

    func runApprovalDeadlines(now: Date = .now) {
        let pendingSorted = applications
            .enumerated()
            .filter { $0.element.status == .pendingReview }
            .sorted { $0.element.appliedAt < $1.element.appliedAt }

        // 单 match 局部计数缓存(避免遍历过程中 approvedCount 抖动)
        var localApproved: [UUID: Int] = [:]

        for (idx, app) in pendingSorted {
            guard let match = matches[app.matchID] else { continue }
            guard let deadline = match.approvalDeadline, now >= deadline else { continue }

            if match.startDate < now {
                applications[idx].status = .expired
                applications[idx].resolvedAt = now
                applications[idx].resolvedBy = nil
                continue
            }

            let count = localApproved[match.id] ?? approvedCount(for: match.id)
            let cap = max(0, match.maxPlayers - 1)   // 减去 host 自己
            if count < cap {
                applications[idx].status = .autoApproved
                applications[idx].resolvedAt = now
                applications[idx].resolvedBy = nil
                localApproved[match.id] = count + 1
            } else {
                applications[idx].status = .waitlisted
                applications[idx].resolvedAt = now
                applications[idx].resolvedBy = nil
            }
        }
        persist()
    }
```

- [ ] **Step 4: 跑测试,确认通过**

Run: 同 Step 2
Expected: 5 tests PASS(包含本任务 5 条)

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/BookingStore.swift TennisMatchTests/BookingStoreApprovalTests.swift
git commit -m "feat(booking): runApprovalDeadlines + FIFO + 满员转 waitlist"
```

---

### Task 11: promoteWaitlist(TDD 核心 #3)

**Files:**

- Modify: `TennisMatch/Models/BookingStore.swift`
- Create: `TennisMatchTests/BookingStoreWaitlistTests.swift`

- [ ] **Step 1: 写失败测试**

Create `TennisMatchTests/BookingStoreWaitlistTests.swift`:

```swift
import XCTest
@testable import TennisMatch

@MainActor
final class BookingStoreWaitlistTests: XCTestCase {

    var store: BookingStore!
    let userID = UUID()

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        store = BookingStore(currentUserID: userID)
    }

    func test_promoteWaitlist_promotesOnReject() {
        let match = MockBuilders.match(maxPlayers: 3, currentPlayers: 1, hostID: userID)
        store.registerMatch(match)
        let approved = MockBuilders.application(matchID: match.id, hostID: userID, status: .approved)
        let waiter = MockBuilders.application(matchID: match.id, hostID: userID, status: .waitlisted)
        store.applications = [approved, waiter]

        store.reject(applicationID: approved.id, note: nil, now: MockBuilders.fixedNow)
        store.promoteWaitlist(now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first { $0.id == waiter.id }?.status, .approved)
    }

    func test_promoteWaitlist_promotesOnCancel() {
        let match = MockBuilders.match(maxPlayers: 3, currentPlayers: 1)
        store.registerMatch(match)
        // 我自己已 approved
        let mine = MatchApplication(
            matchID: match.id, applicantID: userID, hostID: match.hostID,
            status: .approved, appliedAt: MockBuilders.fixedNow
        )
        let waiter = MockBuilders.application(matchID: match.id, hostID: match.hostID, status: .waitlisted)
        store.applications = [mine, waiter]

        store.cancelApplication(mine.id, now: MockBuilders.fixedNow)
        store.promoteWaitlist(now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first { $0.id == waiter.id }?.status, .approved)
    }

    func test_promoteWaitlist_promotesByFIFO() {
        let match = MockBuilders.match(maxPlayers: 4, currentPlayers: 1, hostID: userID)
        store.registerMatch(match)
        let earlyWait = MockBuilders.application(
            matchID: match.id, hostID: userID, status: .waitlisted,
            appliedAt: MockBuilders.fixedNow
        )
        let lateWait = MockBuilders.application(
            matchID: match.id, hostID: userID, status: .waitlisted,
            appliedAt: MockBuilders.fixedNow.addingTimeInterval(10)
        )
        store.applications = [lateWait, earlyWait]   // 乱序

        // 球局空 3 位,递补头部 — 都应升级
        store.promoteWaitlist(now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first { $0.id == earlyWait.id }?.status, .approved)
        XCTAssertEqual(store.applications.first { $0.id == lateWait.id }?.status, .approved)
    }

    func test_promoteWaitlist_doesNotPromoteWhenFull() {
        let match = MockBuilders.match(maxPlayers: 3, currentPlayers: 1, hostID: userID)
        store.registerMatch(match)
        // 满员 (host + 2 approved = 3)
        let a1 = MockBuilders.application(matchID: match.id, hostID: userID, status: .approved)
        let a2 = MockBuilders.application(matchID: match.id, hostID: userID, status: .approved)
        let waiter = MockBuilders.application(matchID: match.id, hostID: userID, status: .waitlisted)
        store.applications = [a1, a2, waiter]

        store.promoteWaitlist(now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first { $0.id == waiter.id }?.status, .waitlisted)
    }
}
```

- [ ] **Step 2: 跑测试,确认编译失败**

Run: `xcodebuild test ... -only-testing TennisMatchTests/BookingStoreWaitlistTests`
Expected: 「has no member 'promoteWaitlist'」

- [ ] **Step 3: 实现**

In `TennisMatch/Models/BookingStore.swift`,紧接 `runApprovalDeadlines` 后:

```swift
    // MARK: - Fallback: waitlist promotion

    func promoteWaitlist(now: Date = .now) {
        let matchIDs = Set(applications.compactMap {
            $0.status == .waitlisted ? $0.matchID : nil
        })
        for matchID in matchIDs {
            guard let match = matches[matchID], match.startDate >= now else { continue }
            let cap = max(0, match.maxPlayers - 1)
            let approvedNow = approvedCount(for: matchID)
            let slots = cap - approvedNow
            guard slots > 0 else { continue }

            let queueIdx = applications
                .enumerated()
                .filter { $0.element.matchID == matchID && $0.element.status == .waitlisted }
                .sorted { $0.element.appliedAt < $1.element.appliedAt }
                .prefix(slots)
                .map { $0.offset }

            for idx in queueIdx {
                applications[idx].status = .approved
                applications[idx].resolvedAt = now
                applications[idx].resolvedBy = nil
            }
        }
        persist()
    }
```

- [ ] **Step 4: 在 reject / cancelApplication 末尾自动调 promoteWaitlist**

In `TennisMatch/Models/BookingStore.swift`,修改 `reject` 和 `cancelApplication` 函数末尾(在 `persist()` 之前):

```swift
        promoteWaitlist(now: now)
```

> 同样修改 `approve`?——不需要,approve 不释放名额。

- [ ] **Step 5: 跑测试,确认通过**

Run: `xcodebuild test ... -only-testing TennisMatchTests/BookingStoreWaitlistTests`
Expected: 4 tests PASS

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Models/BookingStore.swift TennisMatchTests/BookingStoreWaitlistTests.swift
git commit -m "feat(booking): promoteWaitlist + reject/cancel 后自动递补"
```

---

### Task 12: runFallbackChecks + 去抖

**Files:**

- Modify: `TennisMatch/Models/BookingStore.swift`
- Modify: `TennisMatchTests/BookingStoreApprovalTests.swift`

- [ ] **Step 1: 写测试**

Append to `TennisMatchTests/BookingStoreApprovalTests.swift`:

```swift
extension BookingStoreApprovalTests {
    func test_runFallbackChecks_debounceWithin2s_skips() {
        let match = MockBuilders.match()
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: match.hostID)
        store.applications.append(app)

        let afterDeadline = match.approvalDeadline!.addingTimeInterval(60)
        store.runFallbackChecks(now: afterDeadline)
        // 第一次应通过
        XCTAssertEqual(store.applications.first?.status, .autoApproved)

        // 重置回 pendingReview 模拟新一轮 — 1s 后再调
        store.applications[0].status = .pendingReview
        store.runFallbackChecks(now: afterDeadline.addingTimeInterval(1))
        // 第二次应被去抖跳过 — 状态不动
        XCTAssertEqual(store.applications.first?.status, .pendingReview)

        // 3s 后应放行
        store.runFallbackChecks(now: afterDeadline.addingTimeInterval(3))
        XCTAssertEqual(store.applications.first?.status, .autoApproved)
    }
}
```

- [ ] **Step 2: 跑测试,确认编译失败**

Expected: 「has no member 'runFallbackChecks'」

- [ ] **Step 3: 实现**

In `TennisMatch/Models/BookingStore.swift`,加在 `promoteWaitlist` 之后:

```swift
    // MARK: - Fallback driver

    /// 触发器入口。HomeView/MyMatchesView/MatchDetailView onAppear + scenePhase=.active 调用。
    /// 2s 去抖 — 同秒多次 onAppear 不会重复扫描。
    func runFallbackChecks(now: Date = .now) {
        guard now.timeIntervalSince(lastFallbackRunAt) > Self.debounceInterval else { return }
        lastFallbackRunAt = now
        runApprovalDeadlines(now: now)
        promoteWaitlist(now: now)
    }
```

- [ ] **Step 4: 跑测试,确认通过**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/BookingStore.swift TennisMatchTests/BookingStoreApprovalTests.swift
git commit -m "feat(booking): runFallbackChecks 入口 + 2s 去抖"
```

---

## Phase D · 迁移 view 到新 API

### Task 13: HomeView 改用 apply

**Files:**

- Modify: `TennisMatch/Views/HomeView.swift`(line 653 附近)

- [ ] **Step 1: 找到 signUp 调用**

Run: `grep -n "bookingStore.signUp\|signUp(matchID:" TennisMatch/Views/HomeView.swift`

- [ ] **Step 2: 改为 apply**

将每处:

```swift
let result = bookingStore.signUp(matchID: match.id, info: info)
```

改为:

```swift
bookingStore.registerMatch(match)
if let hit = bookingStore.conflict(start: info.startDate, end: info.endDate, excluding: match.id) {
    /* 现有 conflict 处理保留 */
} else if bookingStore.myApplication(for: match.id) != nil {
    /* 现有 alreadySignedUp toast 保留 */
} else {
    let app = bookingStore.apply(to: match)
    /* 现有 .ok 处理 — 如显示报名成功 toast — 保留 */
    /* 若 app.status == .pendingReview,toast 文案改为「申请已提交,等发起人审核」*/
}
```

> 注意:具体 toast 调用语句沿用现有写法,这里只换核心调用。

- [ ] **Step 3: 编译 + 手测**

Run: `xcodebuild build -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: BUILD SUCCEEDED

启 simulator,首页随便报名一个局,确认报名成功 toast 出现,我的约球能看到。

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "refactor(home): signUp → apply,接通新 BookingApprovalStatus"
```

---

### Task 14: SignUpConfirmSheet 文案分支

**Files:**

- Modify: `TennisMatch/Views/HomeView.swift`(SignUpConfirmSheet 定义处)

- [ ] **Step 1: 找到 SignUpConfirmSheet**

Run: `grep -n "SignUpConfirmSheet\|struct SignUpConfirmSheet" TennisMatch/Views/HomeView.swift`

- [ ] **Step 2: 加入 requiresApproval 条件分支**

修改 sheet,主按钮文字与副标题根据 `match.requiresApproval` 切换:

```swift
private var primaryButtonTitle: String {
    match.requiresApproval ? "提交申请" : "确认报名"
}

private var subtitle: String {
    match.requiresApproval
        ? "等发起人接受,12h 未处理将自动通过"
        : "提交后立即占位"
}
```

然后在原显示文案处用上述两个 computed property。

- [ ] **Step 3: 手测**

启 simulator,找一个 mock 局开 `requiresApproval=true`(seed 加),进 sheet 看文案切换。

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "feat(home): SignUpConfirmSheet 按 requiresApproval 切换文案"
```

---

### Task 15: MyMatchesView 消费 applications + pending 卡片

**Files:**

- Modify: `TennisMatch/Views/MyMatchesView.swift`

- [ ] **Step 1: 找出 acceptedMatchItems**

Run: `grep -n "acceptedMatchItems\|bookingStore.accepted" TennisMatch/Views/MyMatchesView.swift`
Expected: `:150`

- [ ] **Step 2: 改为读 applications**

将 `acceptedMatchItems` computed property 改为遍历 `bookingStore.applications`,过滤 `applicantID == userStore.id`,跳过 `cancelledBySelf`/`rejected`/`expired`,根据 status 映射到 UI:

```swift
private var acceptedMatchItems: [MyMatchItem] {
    bookingStore.applications
        .filter { $0.applicantID == userStore.id }
        .filter { ![.cancelledBySelf, .rejected, .expired].contains($0.status) }
        .compactMap { app -> MyMatchItem? in
            guard let match = bookingStore.matches[app.matchID]
                ?? findMatchInSeeds(app.matchID) else { return nil }
            // 状态映射
            let myStatus: MyMatchStatus
            switch app.status {
            case .pendingReview:           myStatus = .pendingApproval(deadline: match.approvalDeadline)
            case .waitlisted:              myStatus = .waitlisted
            case .approved, .autoApproved, .autoConfirmed:
                myStatus = match.isFull ? .confirmed : .pending
            default:                       return nil
            }
            return MyMatchItem(
                title: match.name,
                isOrganizer: false,
                status: myStatus,
                /* 其他字段沿用 */
                ...
            )
        }
}
```

> `bookingStore.matches` 是 fileprivate — 需在 BookingStore 加 `func match(for: UUID) -> MockMatch?` public helper。

- [ ] **Step 3: 在 BookingStore 加 match accessor**

In `TennisMatch/Models/BookingStore.swift`,在 `unregisterMatch` 之后:

```swift
    func match(for matchID: UUID) -> MockMatch? {
        matches[matchID]
    }
```

然后 view 里用 `bookingStore.match(for: app.matchID)` 替代直接访问。

- [ ] **Step 4: MyMatchStatus 加 pendingApproval / waitlisted**

In `TennisMatch/Views/MyMatchesView.swift`,`enum MyMatchStatus`(约 line 1186)加:

```swift
case pendingApproval(deadline: Date?)
case waitlisted
```

对应 `bannerColor` / 文字也加分支。

- [ ] **Step 5: 写 pending 卡片视觉**

按 spec §6.2 实现:

- 倒计时:`TimelineView(.everyMinute) { context in ... }`,显示「约 N 小时后自动通过」
- 撤回按钮:用 `confirmationDialog`,绑定到 application.id
- 撤回回调:`bookingStore.cancelApplication(app.id)`

- [ ] **Step 6: 手测**

发布 mock 局开 requiresApproval,模拟报名,看 my-matches 卡片显示倒计时 + 撤回按钮工作。

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift TennisMatch/Models/BookingStore.swift
git commit -m "feat(my-matches): pending/waitlisted 卡片 + 撤回申请"
```

---

### Task 16: MessagesView AcceptedMatchInfo 派生

**Files:**

- Modify: `TennisMatch/Views/MessagesView.swift`(line 249 附近)

- [ ] **Step 1: 看现有用法**

Run: `grep -n "AcceptedMatchInfo\|bookingStore.accepted" TennisMatch/Views/MessagesView.swift`

- [ ] **Step 2: 切换数据源**

把读 `bookingStore.accepted` 的地方,改为读 `bookingStore.legacyAcceptedSnapshot()` 或重写为读 `applications.filter { occupiesSlot } + match lookup` 派生。

> 该 view 仅显示卡片,无写入,改 source 即可。具体代码量取决于现有结构;小心 sourceMatchID 可能为 nil 的旧调用方。

- [ ] **Step 3: 编译 + 手测**

启 simulator,进 messages,验证已加入的局正常显示,聊天入口可用。

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/MessagesView.swift
git commit -m "refactor(messages): AcceptedMatchInfo 派生自 applications"
```

---

### Task 17: 删除 deprecated wrapper(可选,确认无引用后)

**Files:**

- Modify: `TennisMatch/Models/BookingStore.swift`

- [ ] **Step 1: 验证无引用**

Run:

```bash
grep -rn "bookingStore.signUp\|bookingStore.acceptInvitation\|bookingStore.cancel(\|bookingStore.accepted\|bookingStore.signedUpMatchIDs" TennisMatch/Views TennisMatch/Components
```

Expected: 0 results

- [ ] **Step 2: 删除 // MARK: - Legacy compat 整段**

In `TennisMatch/Models/BookingStore.swift`,删除最末尾 `extension BookingStore { /* legacy */ }` 整段。

- [ ] **Step 3: 删除 legacyAcceptedSnapshot()**(若 MessagesView 已迁完)

- [ ] **Step 4: 编译 + 跑全部测试**

Run: `xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: 全部 PASS

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/BookingStore.swift
git commit -m "chore(booking): 移除 deprecated 兼容 wrapper"
```

---

## Phase E · 新 UI

### Task 18: CreateMatchView 加「审核报名」section

**Files:**

- Modify: `TennisMatch/Views/CreateMatchView.swift`

- [ ] **Step 1: 加 form state**

In `CreateMatchView`,`@State` 变量列表(约 line 30-50)加:

```swift
@State private var requiresApproval: Bool = false
```

- [ ] **Step 2: 加 approval section**

在 `levelSection` 与 `feeSection` 之间(看 line 124-126)新加 `approvalSection`:

```swift
private var approvalSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Toggle(isOn: $requiresApproval) {
            VStack(alignment: .leading, spacing: 2) {
                Text("需要我审核报名者")
                Text("开启后,报名者需等你接受;12h 内未处理,系统自动通过。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(!canEnable)

        if !canEnable {
            Text("时间太短,无法开启审核")
                .font(.caption)
                .foregroundStyle(.orange)
        } else if requiresApproval, let deadline = computedDeadline {
            Text("将于 \(deadline, format: .dateTime.month().day().hour().minute()) 自动处理")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    .padding(/* 与其他 section 相同 padding */)
}

private var canEnable: Bool {
    ApprovalDeadlineCalculator.canEnableApproval(
        publishedAt: .now, startDate: composedStartDate
    )
}

private var computedDeadline: Date? {
    ApprovalDeadlineCalculator.deadline(
        requiresApproval: requiresApproval,
        publishedAt: .now,
        startDate: composedStartDate
    )
}
```

> `composedStartDate` 是现有从 selectedDate + selectedStartTime 拼出的 Date — 找现有计算复用。

- [ ] **Step 3: 加进 form card**

In `formCard` body,`levelSection` 之后、`feeSection` 之前插入:

```swift
approvalSection
```

- [ ] **Step 4: 提交时把字段写入 MockMatch**

找发布回调(form submit handler),构造 MockMatch 时加:

```swift
match.requiresApproval = requiresApproval
match.approvalDeadline = computedDeadline
match.hostID = userStore.id
```

- [ ] **Step 5: 手测**

- 发布表单开关默认关
- 时间设近(<30min)→ 开关 disabled + 灰提示
- 设远 → 可开,caption 显示 deadline
- 提交后 my-matches 看到这场局

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/CreateMatchView.swift
git commit -m "feat(create): 审核报名 section + deadline caption"
```

---

### Task 19: MatchDetailView host 审核区块

**Files:**

- Modify: `TennisMatch/Views/MatchDetailView.swift`

- [ ] **Step 1: 找 view 入口 + 现有结构**

Run: `grep -n "struct MatchDetailView\|var body" TennisMatch/Views/MatchDetailView.swift`

- [ ] **Step 2: 加 host gate computed property**

```swift
private var isHostWithApproval: Bool {
    match.hostID == userStore.id && match.requiresApproval
}

private var pendingApplications: [MatchApplication] {
    bookingStore.incomingApplications(for: match.id)
        .filter { $0.status == .pendingReview }
}

private var waitlistedApplications: [MatchApplication] {
    bookingStore.incomingApplications(for: match.id)
        .filter { $0.status == .waitlisted }
}

private var deadlineWarn: Bool {
    guard let d = match.approvalDeadline else { return false }
    return Date.now > d.addingTimeInterval(-2 * 3600)
}
```

- [ ] **Step 3: 加 review section**

在 body 末尾(详情底部)加:

```swift
if isHostWithApproval {
    Section {
        if deadlineWarn && !pendingApplications.isEmpty {
            Banner.warning("⚠️ 2 小时内未处理将自动通过 \(pendingApplications.count) 名申请者")
        }
        if pendingApplications.isEmpty && waitlistedApplications.isEmpty {
            Text("空空如也,等待报名中…").foregroundStyle(.secondary)
        } else {
            ForEach(pendingApplications) { app in
                applicantRow(app, isWaitlist: false)
            }
            ForEach(waitlistedApplications) { app in
                applicantRow(app, isWaitlist: true)
            }
        }
    } header: {
        Text(pendingApplications.isEmpty
             ? "候补队列 (\(waitlistedApplications.count))"
             : "待审核 (\(pendingApplications.count))")
    }
}

private func applicantRow(_ app: MatchApplication, isWaitlist: Bool) -> some View {
    HStack {
        // applicant 名字 + ntrp + 申请时间 — 从 MatchRegistrant 或 user lookup
        VStack(alignment: .leading) {
            Text(applicantName(app.applicantID))
            Text("申请于 \(app.appliedAt, format: .relative(presentation: .named))")
                .font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Button(isWaitlist ? "⬆️ 提前补位" : "✅ 接受") {
            bookingStore.approve(applicationID: app.id)
        }
        Button("❌ 拒绝") {
            bookingStore.reject(applicationID: app.id, note: nil)
        }
    }
}

private func applicantName(_ id: UUID) -> String {
    // mock 阶段:从 MatchRegistrant 索引 — 当前局缺少 applicantID → registrant 关系
    // v1 简化:显示 UUID prefix,后续 task 串接真实 MatchRegistrant.name
    "申请者 \(id.uuidString.prefix(6))"
}
```

> 注:`applicantName` 在当前 mock 没有 applicant→registrant 映射,简化显示;后续 task / 真后端再补。spec §6.3 说显示 name + ntrp + 申请时间 — 此处先 stub,加 TODO 注释:

```swift
// TODO: 真后端接入后串 applicantID → User → name/ntrp
```

> 这是允许的 TODO(因为是真实未来工作,不是占位符遗留)。但更严格做法:把 `applicantName` 当成本 task 的 known limitation 写进 spec scope 后续。

- [ ] **Step 4: onAppear 调 runFallbackChecks**

```swift
.onAppear {
    bookingStore.runFallbackChecks()
}
```

- [ ] **Step 5: 手测**

- 用 host 视角发一场需审核的局
- 在 BookingStore 手动注入 mock 申请(临时调试代码)
- 进详情页看 section,接受/拒绝按钮工作

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/MatchDetailView.swift
git commit -m "feat(match): host 审核区块 + deadline banner"
```

---

### Task 20: NotificationStore kinds + coalesceKey

**Files:**

- Modify: `TennisMatch/Models/NotificationStore.swift`

- [ ] **Step 1: 加 kind**

In `enum MatchNotification.Kind`(或 `MatchNotification` 内枚举),加:

```swift
case applicationReceived       // host: 有人报名了
case approvalDeadlineSoon      // host: 你还没处理,2h 后自动通过
case applicationAutoApproved   // applicant: 自动通过了
case applicationRejected       // applicant: 被拒了
case waitlistedToApproved      // applicant: 候补递补成功
case applicationExpired        // applicant: 球局过期未处理
```

- [ ] **Step 2: 给 MatchNotification 加 coalesceKey**

```swift
struct MatchNotification: Identifiable {
    let id: UUID
    let kind: Kind
    let title: String
    let createdAt: Date
    let coalesceKey: String?    // 新增
    var seen: Bool = false
}
```

- [ ] **Step 3: 改写写入逻辑**

In `NotificationStore`,加 `upsert` 方法:

```swift
func upsert(_ note: MatchNotification) {
    if let key = note.coalesceKey,
       let idx = items.firstIndex(where: {
           $0.coalesceKey == key && !$0.seen
       }) {
        items[idx] = note   // 覆盖
    } else {
        items.insert(note, at: 0)
    }
}

func markSeen(coalesceKey: String) {
    for idx in items.indices where items[idx].coalesceKey == coalesceKey {
        items[idx].seen = true
    }
}
```

- [ ] **Step 4: 在 BookingStore 各转换点调用**

In `BookingStore`,持有 `notificationStore: NotificationStore`(init 注入)。在 approve/reject/cancel/runApprovalDeadlines/promoteWaitlist 末尾发对应通知:

- `apply` 入 pending: `.applicationReceived` + key = "received-\(matchID)"
- `runApprovalDeadlines` autoApproved: `.applicationAutoApproved`
- `runApprovalDeadlines` waitlisted: 不发(避免噪声)
- `runApprovalDeadlines` expired: `.applicationExpired`
- `promoteWaitlist` waitlisted→approved: `.waitlistedToApproved`
- `reject`: `.applicationRejected`

> 详细文案沿现有 NotificationStore 习惯。

- [ ] **Step 5: MatchDetailView 进入时清 seen**

In MatchDetailView `.onAppear`:

```swift
notificationStore.markSeen(coalesceKey: "received-\(match.id)")
```

- [ ] **Step 6: 手测 + Commit**

```bash
git add TennisMatch/Models/NotificationStore.swift TennisMatch/Models/BookingStore.swift TennisMatch/Views/MatchDetailView.swift
git commit -m "feat(notification): 6 种新 kind + coalesceKey 合并策略"
```

---

## Phase F · Wiring + 调试

### Task 21: TennisMatchApp scenePhase 监听

**Files:**

- Modify: `TennisMatch/TennisMatchApp.swift`

- [ ] **Step 1: 加 scenePhase**

In `TennisMatchApp.swift` body:

```swift
@Environment(\.scenePhase) private var scenePhase
```

WindowGroup 加 modifier:

```swift
.onChange(of: scenePhase) { _, new in
    if new == .active {
        bookingStore.runFallbackChecks()
    }
}
```

- [ ] **Step 2: 在 HomeView / MyMatchesView onAppear 也调一次**

```swift
.onAppear {
    bookingStore.runFallbackChecks()
}
```

- [ ] **Step 3: 手测**

- 跑模拟器,后台 → 前台,看 console / 状态变化
- 改系统时间至 deadline 之后,杀 App 重启 → pending 应自动通过

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/TennisMatchApp.swift TennisMatch/Views/HomeView.swift TennisMatch/Views/MyMatchesView.swift
git commit -m "feat(app): scenePhase + onAppear 触发 runFallbackChecks"
```

---

### Task 22: Debug 隐藏菜单

**Files:**

- Modify: `TennisMatch/Views/MyMatchesView.swift`

- [ ] **Step 1: 加 #if DEBUG 菜单**

In MyMatchesView 顶部 toolbar,加:

```swift
#if DEBUG
Menu("🔧") {
    Button("⏩ 跳到所有 deadline 之后") {
        bookingStore.runFallbackChecks(now: .now.addingTimeInterval(365 * 24 * 3600))
    }
    Button("🔧 强制递补 waitlist") {
        bookingStore.promoteWaitlist()
    }
}
#endif
```

- [ ] **Step 2: Release build 验证剥离**

Run: `xcodebuild build -project TennisMatch.xcodeproj -scheme TennisMatch -configuration Release -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: BUILD SUCCEEDED,grep 编译产物确认无 "跳到所有 deadline" 字符串。

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "chore(debug): MyMatches 隐藏菜单(#if DEBUG)"
```

---

### Task 23: 全量测试 + 手动 UI checklist

- [ ] **Step 1: 跑全部测试**

Run: `xcodebuild test -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: 全部 PASS(BookingApprovalStatusTests 6 + ApprovalDeadlineCalculatorTests 6 + BookingStoreApprovalTests 13 + BookingStoreWaitlistTests 4 + smoke 2 ≈ 31 测试)

- [ ] **Step 2: 手动 UI checklist(spec §7.5)**

按 spec 末尾清单,逐条手测:

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

- [ ] **Step 3: 收尾 commit**

若有清单中暴露的小 bug 修了,合并提交;否则:

```bash
git commit --allow-empty -m "test: 手动 UI checklist 通过"
```

---

## 完成标志

- ✅ 31 单测 PASS
- ✅ 手动 UI checklist 全过
- ✅ 旧 `accepted[]` / `signedUpMatchIDs` / `signUp(matchID:info:)` 在代码中无引用
- ✅ Spec §6.6「不做」清单中的事确实没做

后续 PR 范围(spec §8 显式 out-of-scope):

- 信用分系统(任务 #2)
- 时间冲突 pending 软占用(任务 #2)
- 推送通知
- 「批量接受」
