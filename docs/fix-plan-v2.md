# Let's Tennis — 第二轮测试 & 修复计划 v2

> **测试日期**: 2026-04-22
> **基准分支**: `main` (commit 37a5991)
> **角色**: 资深 iOS QA — 在 v1 修复基础上全量复扫
> **严重等级**: P0 (阻断主流程 / 数据错乱) · P1 (体验明显受损) · P2 (打磨项)

---

## 〇、v1 修复回顾

v1 计划（`docs/ux-test-findings.md`）共 Batch 1-3，绝大部分已合入 main。
本轮在 v1 基础上**新发现 + 遗留未完成**的问题，按模块重新编号。

---

## 一、问题清单（按模块）

### 📍 模块 A：核心数据 & 业务逻辑（Models/Stores）

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| A-1 | **CreditScoreStore 取消扣分条件反转** | **P0** | `CreditScoreStore.swift:57` | `guard hoursBeforeStart < 6` 应为 `guard hoursBeforeStart >= 6`（当前：开场前 5h 取消 → 不扣分；开场前 7h 取消 → 反而扣分） | 改为 `guard hoursBeforeStart >= 6 else { /* 扣分逻辑 */ }` 或直接去掉 guard，改成 `if hoursBeforeStart < 6 { 扣分 }` |
| A-2 | **MatchSchedule 不支持跨午夜时间段** | P1 | `MatchSchedule.swift:124` | 输入 `"04/19 23:00 - 01:00"` → end 解析为同日 01:00 < start → fallback 2h，应为次日 01:00 | end < start 时自动 +1 天：`end = calendar.date(byAdding: .day, value: 1, to: end)` |
| A-3 | **CalendarService 不校验 hour/minute 边界** | P1 | `CalendarService.swift:159` | `apply(time: "25:75", to:)` → `bySettingHour` 静默包装到次日 02:15，日历事件时间错乱 | 加 `guard (0...23).contains(hour), (0...59).contains(minute)` |
| A-4 | **RatingFeedbackStore 不校验极端 peer 评分** | P2 | `RatingFeedbackStore.swift:96` | 全部 peer 给 0.5 → avg=0.5 → 校准建议 snap 到 1.0，用户无感知原因 | 在 `calibrationSuggestion()` 中加注释或 log；可选：丢弃 [0,1) 和 (6,7] 范围外的输入 |
| A-5 | **MatchSchedule / CalendarService 缺少时区参数** | P2 | `MatchSchedule.swift:18` | 多时区用户解析同一 "04/19 10:00" 得到不同绝对时间 | 在 Model 中统一存 UTC `Date`，展示层再 `formatted(date:time:)` |

---

### 📍 模块 B：注册 & 登录

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| B-1 | **RegisterView 无必填字段校验** | **P0** | `RegisterView.swift:482` | 姓名为空 + NTRP 随意填 → 直接 `isLoggedIn = true` | 提交前校验：name 非空、ntrpScore 在 1.0-7.0 范围内，不合格 shake + 红框 |
| B-2 | **LoginView WeChat/Apple 按钮直接置 `isLoggedIn = true`** | P1 | `LoginView.swift:146,150` | 点击微信/Apple → 直接跳过注册进入主页，无用户数据 | 暂时改为 toast "即將支持" 或跳到 RegisterView；长期接入 SDK |
| B-3 | **LoginView "立即註冊" 跳 PhoneVerificationView 而非 RegisterView** | P1 | `LoginView.swift:208` | 新用户点注册 → 进验证码页（无手机号输入），流程断裂 | 改 destination 为 RegisterView，或在 PhoneVerification 之前插入手机号输入页 |

---

### 📍 模块 C：首页 HomeView

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| C-1 | **chatUnreadCount 硬编码为 4，不随消息变化** | **P0** | `HomeView.swift:37` | Tab 3 badge 永远显示 4 | 绑定到 MessagesView 或 NotificationStore 的实际未读数 |
| C-2 | **推荐卡片区域统计硬编码**（信誉 85、场次 28、NTRP 3.5） | P1 | `HomeView.swift:451-453` | 应从 UserStore / CreditScoreStore 读取 | 替换为 `userStore.ntrpText`、`creditScoreStore.score` 等 |
| C-3 | **signedUpMatchIDs 为 @State，App 切后台可能丢失** | P1 | `HomeView.swift:51` | 报名后切后台再回来，signedUpMatchIDs 可能重置 | 改用 `@AppStorage` 或持久化到 Store |
| C-4 | **满员约球按钮仍为绿色"報名"，点击后才报错** | P1 | `HomeView.swift:1149-1155` | players = "2/2" → 按钮外观无变化 | 解析 current/max，满员时文案改"已額滿" + 禁用灰态 |
| C-5 | **时间过滤 Picker 无 accessibilityLabel** | P2 | `HomeView.swift:786-805` | 屏幕阅读器无法识别 from/to 含义 | 加 `.accessibilityLabel("開始時間")` / `.accessibilityLabel("結束時間")` |

---

### 📍 模块 D：约球详情 MatchDetailView

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| D-1 | **Preview 缺少 BookedSlotStore 环境** | **P0** | `MatchDetailView.swift:861-874` | 预览中点报名 → crash（`@Environment(BookedSlotStore.self)` 为 nil） | 在 #Preview 加 `.environment(BookedSlotStore())` |
| D-2 | **participantList 用 `id: \.name` 做 ForEach key** | P1 | `MatchDetailView.swift:281` | 两名同名参加者 → SwiftUI 只渲染一个 | 改 Participant struct 加 UUID id，或用 `\.self` + Hashable |
| D-3 | **报名留言 message 从未传递到聊天** | P1 | `MatchDetailView.swift` | 输入留言 → 确认 → 跳聊天 → 留言丢失 | 将 signUpMessage 作为 ChatDetailView 的 initialMessage 传入 |
| D-4 | **toolbar title 字号 18 与其他页面 navTitle(17) 不一致** | P2 | `MatchDetailView.swift:94-95` | 视觉不统一 | 改用 `Typography.navTitle` |
| D-5 | **性别符号 ternary 在 3 处重复** | P2 | `MatchDetailView.swift:122,297,452` | 重复代码 | 抽取 `Gender.symbol` 计算属性或 helper |

---

### 📍 模块 E：我的约球 MyMatchesView

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| E-1 | **发起人管理 3 项功能仍为 toast 占位** | P1 | `MyMatchesView.swift:215-227` | "編輯約球 / 查看報名者 / 關閉報名" 点击仅弹 toast | 至少实现"查看报名者"列表页；其余标 disabled + "即將推出" |
| E-2 | **邀请 badge 计数含已拒绝的邀请** | P1 | `MyMatchesView.swift:328` | `mockInvitations.count` 未减去已拒绝数 | 改为 `visibleInvitations.count` |
| E-3 | **接受邀请 acceptedMatchItems 硬编码 "2/2 · NTRP 3.0-4.0"** | P1 | `MyMatchesView.swift:84` | 所有接受的邀请显示相同 players 信息 | 从 invitation model 中传递实际 players / NTRP |
| E-4 | **空态页缺少跳转操作按钮** | P1 | `MyMatchesView.swift:103-116` | "去首頁找一場約球" 只有文案无按钮 | 加 Button → 切换到 Tab 0 |
| E-5 | **Toast 背景用 Theme.textBody（语义错误）** | P2 | `MyMatchesView.swift:260` | textBody 是文字色不是背景色 | 改为 `Theme.toastBg` 或 `Theme.textDeep` |
| E-6 | **rejectedInvitationKeys 编码用 `|` 分隔，无转义** | P2 | `MyMatchesView.swift:45-51` | 若 inviterName 含 `|` → 解析错误 | 改用 Codable JSON 结构 |

---

### 📍 模块 F：聊天 ChatDetailView & MessagesView

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| F-1 | **"拒絕" 邀请按钮 action 为空 closure** | **P0** | `ChatDetailView.swift:465` | 聊天内邀请卡片点"拒絕" → 无任何响应 | 添加拒绝逻辑：移除邀请卡片 + 发送系统消息 |
| F-2 | **未读数无幂等清零机制** | P1 | `ChatDetailView.swift:78-102` | 反复进入同一会话 → unreadCount 可能重复扣减 | 进入时一次性 `chat.unreadCount = 0`，用 flag 防重复 |
| F-3 | **Toast 自动消失有竞态** | P2 | `ChatDetailView.swift:241-246` | 2.2s 内连续弹两条 toast → 旧 timer 可能清除新 toast | 用 toast ID 匹配，或 debounce |
| F-4 | **"查看約球詳情" / "查看群成員" 仍为 toast 占位** | P2 | `ChatDetailView.swift:175-180` | 聊天菜单点击 → "即將推出" | 至少禁用 + 灰色文字，或实现跳转 |

---

### 📍 模块 G：个人资料 ProfileView / EditProfileView / SettingsView

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| G-1 | **粉丝 / 互相关注 数字不可点击** | P1 | `ProfileView.swift:214-215` | 只有"關注"可点，其他两个纯展示 | 包装成 Button → NavigationLink 到 FollowerView / MutualView |
| G-2 | **EditProfileView 不保存球场选择** | P1 | `EditProfileView.swift:24,285-289` | 选球场 → 保存 → 再编辑 → 球场回到默认 | 在 saveButton 中同步 `userStore.selectedCourt = selectedCourt` |
| G-3 | **ProfileView 统计数据硬编码** | P1 | `ProfileView.swift:248,307-309` | "場次 28"、"出席率 92%"、"最愛球場 維多利亞公園" 写死 | 从 Store / 统计模块读取 |
| G-4 | **登出后 NavigationStack 可能残留** | P2 | `SettingsView.swift:50` + `TennisMatchApp.swift:22-27` | 登出时 NavigationStack 未显式 pop，可能短暂闪现旧页面 | 把 NavigationStack 放在 if/else 分支内部，或在登出时 `path = NavigationPath()` |

---

### 📍 模块 H：发布约球 CreateMatchView

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| H-1 | **AA制费用可为空发布** | P1 | `CreateMatchView.swift:504-516` | 选 "AA制" → 不填金额 → 发布成功 | 发布前校验 costAmount 非空且 > 0 |
| H-2 | **日期/时间 "已编辑" flag 用 computed property，设值无效** | P1 | `CreateMatchView.swift:312-320` | `_dateWasEdited` 等是 computed property 而非 @State → `onChange` 中赋值被忽略 | 改为 `@State private var dateWasEdited = false` |
| H-3 | **费用显示用 ¥ 但说明写"港幣"** | P2 | `CreateMatchView.swift:596` | 货币符号不一致 | 统一为 `HK$` 或 `$` |

---

### 📍 模块 I：约球助手 MatchAssistantView

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| I-1 | **"查看" 按钮为 TODO，不跳转** | **P0** | `MatchAssistantView.swift:135-144` | 推荐卡片点"查看" → 无反应 | 传入 match 数据，跳 MatchDetailView |
| I-2 | **推荐文案硬编码 NTRP 3.5** | P1 | `MatchAssistantView.swift:30` | "根據你的 NTRP 3.5…" 不读 UserStore | 改为 `userStore.ntrpText` |

---

### 📍 模块 J：全局 / 跨模块

| # | 问题 | 等级 | 文件 & 行号 | 复现 / 说明 | 建议 |
|---|------|------|------------|-------------|------|
| J-1 | **大量硬编码 `.font(.system(size:))` 未用 Typography** | P1 | 全局 100+ 处 | grep `\.font\(\.system\(size:` 可得完整列表 | 批量替换为 Typography.* 常量 |
| J-2 | **残留硬编码颜色** | P1 | 多文件 | `.white`、`Color.red`、`.black.opacity(...)` | 替换为 Theme.background / Theme.badge / Theme.shadow |
| J-3 | **Mock 数据仍分散在各 View 内** | P2 | HomeView, MyMatchesView, MessagesView 等 | 无法跨页面联动 | 抽到 `Models/MockData.swift` 统一管理 |
| J-4 | **iPhone SE 小屏适配未验证** | P2 | 全局 | 多处 `.frame(height: 60)` / `Spacer(height: xxl)` | SE 预览走查 + 响应式间距 |
| J-5 | **深色模式未适配** | P2 | 全局 | `.white` 背景在 dark mode 不可见 | Theme 统一 → 自动适配 |

---

## 二、修复执行计划

### 🔥 Batch 1 — P0 阻断性修复（必须先合）

> **目标**: 修完后所有主流程跑通，无数据错乱。
> **建议分支**: `fix/p0-round2`

| # | 任务 | 涉及文件 | 预估改动 | 依赖 |
|---|------|---------|---------|------|
| **B1-1** | 修 CreditScoreStore 取消扣分条件反转 (A-1) | `CreditScoreStore.swift` | 1 行条件翻转 | 无 |
| **B1-2** | RegisterView 加必填校验：name 非空、NTRP 1.0-7.0 (B-1) | `RegisterView.swift` | +15 行校验 + UI 提示 | 无 |
| **B1-3** | 修 chatUnreadCount 硬编码 → 绑定实际未读数 (C-1) | `HomeView.swift` | 改 @State → computed / binding | 无 |
| **B1-4** | MatchDetailView Preview 补 BookedSlotStore 环境 (D-1) | `MatchDetailView.swift` | +1 行 `.environment()` | 无 |
| **B1-5** | ChatDetailView "拒絕" 按钮补实现 (F-1) | `ChatDetailView.swift` | +10 行拒绝逻辑 | 无 |
| **B1-6** | MatchAssistantView "查看" 按钮跳 MatchDetailView (I-1) | `MatchAssistantView.swift` | +15 行 navigation | 无 |

**验收标准**:
- [ ] 开场前 3h 取消约球 → 扣 5 分
- [ ] 开场前 8h 取消约球 → 不扣分
- [ ] 注册时 name 为空 → 无法提交
- [ ] Tab 3 badge 随消息变化
- [ ] 预览中点报名不 crash
- [ ] 聊天内点"拒絕" → 邀请卡片消失
- [ ] 约球助手"查看" → 进入详情页

---

### ⚡ Batch 2 — P1 体验修复（拆 2 个 PR）

#### PR 2a: 数据 & 逻辑层

| # | 任务 | 涉及文件 | 预估改动 |
|---|------|---------|---------|
| **B2a-1** | MatchSchedule 支持跨午夜时间段 (A-2) | `MatchSchedule.swift` | +5 行 day rollover |
| **B2a-2** | CalendarService 加 hour/minute 边界校验 (A-3) | `CalendarService.swift` | +2 行 guard |
| **B2a-3** | LoginView WeChat/Apple 改为 toast "即將支持" (B-2) | `LoginView.swift` | 改 2 个 action |
| **B2a-4** | LoginView "立即註冊" 修正跳转目标 (B-3) | `LoginView.swift` | 改 destination |
| **B2a-5** | CreateMatchView 日期编辑 flag 改 @State (H-2) | `CreateMatchView.swift` | ~6 行 |
| **B2a-6** | CreateMatchView AA制费用非空校验 (H-1) | `CreateMatchView.swift` | +5 行 |
| **B2a-7** | EditProfileView 保存球场选择 (G-2) | `EditProfileView.swift` + `UserStore.swift` | +3 行 |
| **B2a-8** | signedUpMatchIDs 持久化 (C-3) | `HomeView.swift` | @State → @AppStorage |

#### PR 2b: UX & 交互层

| # | 任务 | 涉及文件 | 预估改动 |
|---|------|---------|---------|
| **B2b-1** | 满员约球按钮 "已額滿" 禁用灰态 (C-4) | `HomeView.swift` | +10 行解析 + 样式 |
| **B2b-2** | 邀请 badge 计数排除已拒绝 (E-2) | `MyMatchesView.swift` | 1 行改 count 源 |
| **B2b-3** | 接受邀请显示实际 players/NTRP (E-3) | `MyMatchesView.swift` | 改 Model + 赋值 |
| **B2b-4** | 空态页加跳转按钮 (E-4) | `MyMatchesView.swift` | +8 行 Button |
| **B2b-5** | 粉丝/互相关注可点击 (G-1) | `ProfileView.swift` | +Button 包装 + NavigationLink |
| **B2b-6** | ProfileView 统计数据去硬编码 (G-3) | `ProfileView.swift` | 绑定 Store |
| **B2b-7** | participantList 用 UUID key (D-2) | `MatchDetailView.swift` | 改 struct + ForEach |
| **B2b-8** | 报名留言传到聊天 (D-3) | `MatchDetailView.swift` | +3 行参数传递 |
| **B2b-9** | 未读数幂等清零 (F-2) | `ChatDetailView.swift` / `MessagesView.swift` | +5 行 flag |
| **B2b-10** | MatchAssistant 推荐文案读 UserStore (I-2) | `MatchAssistantView.swift` | 1 行 |
| **B2b-11** | 发起人管理实现"查看报名者" (E-1) | `MyMatchesView.swift` + 新 View | +30 行 |

**验收标准**:
- [ ] "23:00-01:00" 时间段正确解析为跨午夜
- [ ] 微信/Apple 登录不再直接进主页
- [ ] 满员约球卡片按钮为灰色 "已額滿"
- [ ] 粉丝/互相关注数可点击跳转
- [ ] 报名留言出现在聊天首条消息
- [ ] 进出聊天详情不会重复扣 unread

---

### ✨ Batch 3 — P2 打磨（每项一 commit，合到 develop）

| # | 任务 | 说明 |
|---|------|------|
| **B3-1** | Typography 批量替换 | grep 所有 `.font(.system(size:` → 替换为 Typography.* |
| **B3-2** | Theme 颜色批量替换 | 消除残留 `.white`、`Color.red`、`.black.opacity()` |
| **B3-3** | Toast 背景语义修正 (E-5) | `Theme.textBody` → 专用 toast 背景色 |
| **B3-4** | rejectedInvitationKeys 改 Codable (E-6) | JSON 编码替代 `\|` 分隔 |
| **B3-5** | 性别符号抽 helper (D-5) | `Gender.symbol` 计算属性 |
| **B3-6** | 费用符号统一 HK$ (H-3) | CreateMatchView + 展示处 |
| **B3-7** | chatMenu toast 竞态修复 (F-3) | 用 ID 匹配防误清 |
| **B3-8** | "查看約球詳情"/"查看群成員" 菜单项 disabled 化 (F-4) | 灰色文字 + 移除 toast |
| **B3-9** | Mock 数据集中到 MockData.swift (J-3) | 重构，不改功能 |
| **B3-10** | 登出后 NavigationStack 清理 (G-4) | path reset |
| **B3-11** | Accessibility labels 补全 (C-5) | 时间 Picker + 返回按钮 |
| **B3-12** | iPhone SE 走查 + 响应式间距 (J-4) | 预览验收 |
| **B3-13** | 深色模式适配 (J-5) | 依赖 B3-1/B3-2 完成后统一验证 |

---

## 三、执行优先级 & 里程碑

```
Week 1: Batch 1 (P0) ──────────────▶ PR 合入 main
         ↓
Week 2: Batch 2a (数据/逻辑) ──────▶ PR 合入 main
         Batch 2b (UX/交互)  ──────▶ PR 合入 main
         ↓
Week 3: Batch 3 (打磨) ───────────▶ 逐条 commit
         ↓
         ✅ 全流程验收（SE + 15 Pro，浅/深色模式）
```

---

## 四、验收检查表（全流程 Smoke Test）

### 主路径（P0 修完后必须通过）

- [ ] **注册**: 空姓名 → 被拦截 ✓ / 正常填写 → 进入主页 ✓
- [ ] **发现**: 首页浏览 → 筛选 → 报名 → 确认 → 聊天
- [ ] **详情**: 查看 → 报名（含留言） → 留言出现在聊天
- [ ] **我的约球**: 即将到来 / 已完成 / 邀请 三个 tab 切换
- [ ] **取消**: 开场前 3h 取消 → 扣 5 分 ✓ / 开场前 8h → 不扣分 ✓
- [ ] **聊天**: 发消息 → 发图片 → 未读清零 → 拒绝邀请
- [ ] **约球助手**: 查看推荐 → 点"查看" → 进详情
- [ ] **个人资料**: 编辑 → 保存（含球场） → 再编辑验证持久化
- [ ] **登出**: Settings → 登出 → 回到 LoginView

### 边界 case

- [ ] 满员约球 → 按钮 "已額滿" 禁用
- [ ] 过期约球 → 不可报名
- [ ] 跨午夜约球 → 时间正确解析
- [ ] 重复报名 → 被阻止
- [ ] 时间冲突 → toast 提示
- [ ] NTRP 校准 → 偏差 ≥ 0.5 时弹出建议
- [ ] 连续爽约 → 信用分持续下降

---

## 五、附录：问题总数统计

| 等级 | 数量 | 说明 |
|------|------|------|
| **P0** | 6 | 数据错乱 / 主流程阻断 |
| **P1** | 22 | 体验明显受损 |
| **P2** | 15 | 打磨项 |
| **合计** | **43** | — |
