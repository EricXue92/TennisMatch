# Let'stennis iOS App — UI/UX 全方位审计报告

**审计日期**：2026-04-22
**审计角色**：资深 iOS 产品经理 + 高级 UX 设计师
**审计范围**：前端 UI 功能逻辑、交互流程、UX 体验、视觉规范、代码设计

---

## 模块一：认证与注册流程

### 涉及页面
`LoginView` → `PhoneInputView` → `PhoneVerificationView` → `RegisterView`
`LoginView` → `EmailRegisterView` → `RegisterView`

### 1. 交互与功能逻辑

#### 严重问题

**P0 - OTP 验证形同虚设**
`PhoneVerificationView.swift:191-193` — "验证并登入"按钮不校验验证码内容，无论用户输入什么（甚至为空），点击都直接跳转 RegisterView。精心设计了 6 位输入框 + 60 秒倒计时，但验证环节完全缺失。

建议：至少做前端校验 `code.count == 6`，按钮在未填满时应 disabled + 灰色态。

**P0 - 违反 CLAUDE.md 禁止强解包规则**
`RegisterView.swift:533-534` — 使用了 `selectedGender!` 和 `ntrpValue!`。虽然上方有 guard 链保护，但违反了项目规范"禁止 `!` 强解包"。

建议：使用 `guard let` 或 `if let` 安全解包。

#### 中等问题

**P1 - Email 格式校验过于宽松**
`EmailRegisterView.swift:273` — 只检查 `@` 和 `.` 的存在，`a@.` 这样的无效地址也能通过。

**P1 - 发送验证码无前置校验**
`EmailRegisterView.swift:253` — `sendCode()` 不验证邮箱格式就启动倒计时，用户可以对空邮箱点"发送验证码"（按钮只检查 `!email.isEmpty`）。

**P1 - 缺少加载/发送中状态**
全部 5 个认证页面中，没有任何操作显示 ProgressView 或 loading indicator。用户点击"获取验证码"/"验证并登入"/"注册"/"完成设定"后没有任何即时视觉反馈，在弱网环境下用户会反复点击。

**P1 - 验证错误不会自动消失**
`RegisterView.swift:540` — `showValidationError` 设为 true 后永远不会自动复位。用户修正错误后，红色提示仍然停留。

#### 轻微问题

**P2 - Toast 样式不一致**
- LoginView toast 背景：`Theme.textDeep.opacity(0.92)` (深灰)
- PhoneVerificationView toast 背景：`Theme.primary.opacity(0.92)` (绿色)

**P2 - Timer 使用 Foundation Timer 而非 SwiftUI 风格**
`PhoneVerificationView.swift:227` 和 `EmailRegisterView.swift:258` — 使用 `Timer.scheduledTimer`。更推荐 `.onReceive(Timer.publish(...))` 或 `TimelineView`。

**P2 - LoginView 有 5 个 navigationDestination**
同一个 View 上挂载了 5 个 `navigationDestination(isPresented:)`，可能导致导航栈异常。

### 2. 用户体验

**操作效率**
- 手机注册需要 4 个页面（Login → Phone → OTP → Register），OTP 无实际校验等于白白多一步
- 邮箱注册是 3 个页面，相对合理

**直觉设计**
- 做得好：PhoneInputView 自动弹键盘、OTP 支持 `.oneTimeCode` 自动填充、国家码 Menu 紧凑、手机号脱敏显示
- 需改进：NTRP 输入是纯文本框（建议改 Slider/Picker）、RegisterView 缺少具体缺失项提示、性别只有男/女无"不愿透露"

### 3. 视觉与 UI 设计

**Apple HIG 违规**

| 组件 | 位置 | 实际大小 | 问题 |
|------|------|---------|------|
| 性别/年龄 Chip | RegisterView | ~21pt 高 | padding(.vertical, 4) 太小 |
| Tag 删除按钮 "×" | RegisterView:429 | ~12×12pt | 极难点击 |
| 时段 Tag 删除按钮 "×" | RegisterView:450 | ~12×12pt | 同上 |
| "+ 新增" 按钮 | RegisterView:466 | ~22pt 高 | padding(.vertical, 5) 不够 |
| footer 文字链接 | LoginView:236-268 | ~11pt 字号 | 文字过小 |

**严重 — 完全不支持 Dynamic Type**
`Typography.swift` 所有字号使用硬编码 `Font.system(size:)`，不会随系统辅助功能缩放。

**严重 — 不支持 Dark Mode**
整个 Theme 系统全部使用硬编码颜色，大量使用 `.background(.white)`。

### 4. 情感化与细节

**文案** — 整体良好，错误提示友好具体。

**动画**
- LoginView 入场动画精致：网球浮动 + 光晕脉冲 + 按钮交错出现
- OTP 光标闪烁是精心设计的细节
- 缺失：LoginView → PhoneInputView 暗色到白色视觉断裂、RegisterView 无入场动画

### 模块一总结

| 严重度 | 数量 | 关键项 |
|--------|------|--------|
| P0 | 2 | OTP 不校验、强制解包 |
| P1 | 4 | Email 校验宽松、无 loading 态、发验证码无前置检查、错误提示不消失 |
| P2 | 3 | Toast 不一致、Timer 风格、导航 destination 过多 |
| HIG 违规 | 3 | 点击区域不达标、无 Dynamic Type、无 Dark Mode |
| UX 优化 | 3 | 注册路径长、NTRP 输入方式、登录→注册视觉断裂 |

---

## 模块二：首页 + 约球列表 + 约球详情

### 涉及页面
`HomeView` (1968 行) / `MatchDetailView` (939 行)

### 1. 交互与功能逻辑

#### 严重问题

**P0 - HomeView 是一个"上帝对象" (God Object)**
HomeView.swift 共 1968 行，包含 40+ 个 @State 属性（第 18-61 行），塞入了 5 个 Tab 容器、Drawer、筛选面板、卡片列表、推荐区域、报名确认 Sheet、报名成功页、统计头部、Mock 数据定义等所有逻辑。任何一个 @State 变化都会触发 body 重新求值，性能隐患大。

**P0 - 统计数据硬编码，与 UserStore 脱节**
`HomeView.swift:478-479`：`statCard(label: "場次", value: "28")` 和 `statCard(label: "NTRP", value: "3.5")` 是硬编码。信譽積分正确读取了 `creditScoreStore.score`，但场次和 NTRP 完全写死。

#### 中等问题

**P1 - "拉球"类型缺失于筛选器**
`HomeView.swift:1404`：`matchFilterOptions = ["全部", "單打", "雙打"]`，但 MatchType 包含 `.rally`。

**P1 - 没有下拉刷新**
homeTab 的 ScrollView 没有 `.refreshable`。

**P1 - 报名流程 Sheet → FullScreenCover 链式跳转脆弱**
三层 modal 串联 (`sheet` → `fullScreenCover` → `navigationDestination`) 容易导致动画丢失、状态竞争。

**P1 - 导航目的地过多（11 个 navigationDestination）**
同一个 View 挂载了 11 个 navigationDestination，可能出现导航栈污染。

**P1 - 重复代码：报名确认 & 成功页各写了两份**
- `SignUpConfirmSheet` (HomeView) vs `SignUpConfirmSheetForDetail` (MatchDetailView)
- `SignUpSuccessView` (HomeView) vs `SignUpSuccessViewForDetail` (MatchDetailView)

**P1 - Mock 日期数据会过期**
固定日期如 "04/22"、"04/23"，几天后 isExpired 筛选会清空列表。

### 2. 用户体验

**P1 - 汉堡菜单隐藏了重要功能**
赛事、约球助理、评价、通知、封锁名单、设定等全在 Drawer 内。Apple HIG 反对 hamburger menu。

**P1 - 空状态缺乏引导**
筛选无结果时只显示 "🎾 沒有符合條件的約球"，没有"调整筛选"或"发起约球"按钮。

**P1 - 卡片整体可点击 vs 报名按钮冲突**
整张卡片 `.onTapGesture` 跳转详情，但内含"报名"按钮，容易误触。

**P2 - 推荐球友数据全部硬编码**
10 个推荐球友与用户偏好完全无关。

**P2 - "关注"按钮在不同页面样式逻辑相反**
- 推荐卡片：未关注=绿色实心，已关注=透明边框
- MatchDetailView：未关注=透明边框，已关注=绿色实心

### 3. 视觉与 UI 设计

**P1 - Tab Bar 使用 Emoji 而非 SF Symbols**
🎯🗓💬👤 无法支持 selected/unselected 颜色切换，VoiceOver 会读出 emoji 名称。

**P1 - 多个触控区域不达标 (<44pt)**
筛选 Chip (30pt)、性别筛选 (28pt)、星期按钮 (36pt)、球场删除×(~12pt)、NTRP 滑块 thumb (24pt)。

### 4. 情感化与细节

**做得好**：时段冲突拦截、自动取消逻辑、日历集成、报名留言传递、满员通知。
**缺失**：无 haptic feedback、无骨架屏、Drawer 不支持手势关闭、首页无入场动画。

### 模块二总结

| 严重度 | 数量 | 关键项 |
|--------|------|--------|
| P0 | 2 | God Object 架构、统计数据硬编码 |
| P1 | 9 | 拉球筛选缺失、无下拉刷新、modal 链脆弱、11个导航目的地、重复代码×2、Mock 过期、汉堡菜单、空状态无引导、关注按钮不一致 |
| P2 | 5 | NTRP 滑块边界、Tab 2 幽灵页面、推荐硬编码、Tab Bar padding、筛选触控区域 |
| HIG 违规 | 3 | Emoji Tab 图标、多处 <44pt 触控区域、Tab Bar 过高 |
| UX 优化 | 4 | 卡片点击冲突、无 haptic、无骨架屏、无入场动画 |

---

## 模块三：发布约球 + 我的约球

### 涉及页面
`CreateMatchView` (701 行) / `MyMatchesView` (1354 行)

### 1. 交互与功能逻辑

#### 严重问题

**P0 - 发布约球无必填项校验**
`CreateMatchView.swift:548-554`：提交按钮只校验费用金额，日期/时间/球场全部可以为空。确认页展示了"未選擇"和"--:--"却仍然允许发布。

**P0 - 缺少"拉球"比赛类型**
`CreateMatchView.swift:157-163`：只有"單打"和"雙打"，与 MatchType 枚举和 RegisterView 不一致。

#### 中等问题

**P1 - 时间选择器 1 秒后自动关闭**
`CreateMatchView.swift:281-287`：用户选一个值后 1 秒自动关闭 wheel picker，体验差。

**P1 - 球场选择器复用多选组件但只取第一个**
`CreateMatchView.swift:79-84`：CourtPickerView 设计为多选，但只取 `courtPickerSelection.first`。

**P1 - 发布成功无任何反馈**
`publishMatch()` 直接 dismiss，无成功 toast 或动画。

**P1 - "编辑约球"和"关闭报名"是假功能**
`MyMatchesView.swift:240, 246`：只弹出"即將推出" toast，降低用户信任。

**P1 - 报名者列表是完全伪造的数据**
`MyMatchesView.swift:261-262`：无论哪场约球都显示相同的硬编码名字列表。

**P1 - 接受邀请时性别硬编码为男性**
`MyMatchesView.swift:353`：所有邀请者在聊天中都显示为 ♂。

**P1 - "明天" 标签是硬编码的**
`MyMatchesView.swift:866`：`dateLabel: "明天 · 04/23（三）"` 只在 04/22 正确。

**P1 - 已完成约球无法写评论**
CompletedMatchReviewSheet 是纯展示，没有"寫評論"按钮。评级体系闭环断裂。

#### 轻微问题

**P2 - NTRP 范围滑块代码完全重复**
CreateMatchView 和 HomeView 有几乎一样的双滑块实现，应提取共享组件。

**P2 - 取消确认对话框文案过长**
7 行完整规则说明放在 alert message 中，过于拥挤。

**P2 - 邀请拒绝持久化方式脆弱**
@AppStorage 存储 JSON 编码的拒绝列表，有大小限制。

### 2. 用户体验

**做得好**：
- MyMatchesView 空状态使用 ContentUnavailableView + 引导按钮
- 取消约球流程完善：阶梯扣分 + 通知 + 冻结/封号警告
- 时段冲突检测贯穿接受邀请流程
- Toast 系统设计好：`task(id:)` 自动消失，新 toast 替换旧 toast

**需改进**：
- 发布表单缺乏必填标识（无红色 * 或 badge）
- 日期选择和时间选择的关闭行为不一致
- 发起人管理操作层级过深（3 步 vs 非发起人 2 步）
- 无草稿保存功能

### 3. 视觉与 UI 设计

CreateMatchView 所有交互区域都达到 44pt 标准。
MyMatchesView 按钮虽然视觉小但用了 `frame(minHeight: 44)` 补救。
状态 badge 颜色区分清晰：绿色(已确认)、橙色(等待中)、灰色(已完成)、红色(已自动取消)。

### 4. 情感化与细节

**做得好**：取消惩罚系统设计完整（阶梯扣分 + 冻结 + 封号 + 通知）。
**缺失**：CreateMatchView 无任何动画、无草稿保存、已完成约球无法互评。

### 模块三总结

| 严重度 | 数量 | 关键项 |
|--------|------|--------|
| P0 | 2 | 发布无必填校验、缺拉球类型 |
| P1 | 8 | 时间选择器自动关闭、球场单选复用多选、发布无成功反馈、假功能按钮、报名者假数据、性别硬编码♂、"明天"硬编码、无法写评论 |
| P2 | 3 | NTRP 滑块重复代码、取消 alert 过长、@AppStorage JSON |
| UX 优化 | 3 | 必填标识缺失、选择器关闭行为不一致、发起人操作层级深 |

---

## 全局性问题汇总（跨模块）

### 架构层面
1. **无 Dark Mode 支持** — Theme 全部硬编码颜色，`.background(.white)` 遍布
2. **无 Dynamic Type 支持** — Typography 全部使用 `Font.system(size:)` 硬编码
3. **HomeView God Object** — 1968 行 + 40 个 @State，需要拆分

### 设计一致性
4. **Toast 样式不统一** — 3 种不同的 toast 实现（LoginView / PhoneVerificationView / MyMatchesView）
5. **"关注"按钮样式在不同页面逻辑相反**
6. **NTRP 滑块代码重复** — HomeView 和 CreateMatchView 各写了一份
7. **报名确认/成功页重复** — HomeView 和 MatchDetailView 各写了一份

### 功能完整性
8. **"拉球"类型全链路缺失** — MatchType 有定义但筛选和创建都不支持
9. **所有成功操作无 haptic feedback**
10. **无下拉刷新**
11. **Mock 数据会随时间过期**

---

## 模块四：聊天系统

### 涉及页面
`MessagesView` / `ChatDetailView`

### 1. 交互与功能逻辑

**P1 - "查看約球詳情"和"查看群成員"是禁用占位符**
`ChatDetailView.swift:176-179` — confirmationDialog 里的 `.disabled(true)` 按钮在 iOS 上仍可点击，只是不执行 action。用户点击后没有任何提示。

**P1 - "退出群聊"和"刪除聊天"只 dismiss 不移除数据**
`ChatDetailView.swift:185, 214` — 点击后只调用 `dismiss()`，不从父级 chats 数组中移除，返回列表后聊天依然存在。

**P1 - "封鎖對方"只 dismiss，无实际封锁**
`ChatDetailView.swift:221-222` — 确认封锁后仅 dismiss，未标记该用户为已封锁。

**P1 - 个人聊天中 hardcoded 用户资料**
`ChatDetailView.swift:189-204, 304-319` — 查看对方资料时所有字段写死（gender=.male, ntrp="3.5", reputation=88, bio="熱愛網球"）。两处重复构造完全相同的 PublicPlayerData。

**P2 - mockMessages 和 mockChatsInitial 均为空**
`ChatDetailView.swift:633` / `MessagesView.swift:270` — 无演示数据，聊天 Tab 永远空状态。

### 2. 用户体验

**P1 - 发送按钮始终高亮**
`ChatDetailView.swift:595-603` — 输入框为空时"發送"按钮仍然绿色可点击，虽内部有 guard 但视觉误导。

**P2 - 日期标签硬编码"今天"**
`ChatDetailView.swift:111` — 无论实际日期如何。

**P2 - Photo picker 无预览确认**
`ChatDetailView.swift:566-579` — 选择图片直接发送，无法预览或取消。

**P2 - 第一条聊天用卡片样式，其余用行样式，无功能差异**
`MessagesView.swift:37-66` — 视觉区分不明确。

### 3. 视觉设计

**P1 - 多处硬编码 `.white` 背景**
`MessagesView.swift:72` / `ChatDetailView.swift:607, 329` — Dark Mode 不适配。

**P2 - 邀请卡"接受"按钮 26pt 高度**
`ChatDetailView.swift:490` — 低于 HIG 44pt 最小触控目标。

### 4. 亮点

- 时段冲突拦截（ChatDetailView:464-467）
- 签到留言自动发送（ChatDetailView:136-146）
- matchContext 可关闭卡片
- swipe-to-delete + 确认弹窗
- 空状态使用 ContentUnavailableView

### 模块四总结

| 严重度 | 数量 | 关键项 |
|--------|------|--------|
| P1 | 5 | 占位功能、退出/封锁无实际操作、hardcoded 用户资料、发送按钮始终高亮 |
| P2 | 6 | 空 mock 数据、日期硬编码、photo 无确认、卡片样式差异、.white 背景、按钮高度 |

---

## 模块五：个人资料 + 社交

### 涉及页面
`ProfileView` / `EditProfileView` / `PublicProfileView` / `FollowingView` / `FollowerListView` / `MutualFollowListView` / `FollowStore` / `UserStore`

### 1. 交互与功能逻辑

**P0 - 三套重复的 Player 数据模型**
`FollowedPlayer`、`FollowerPlayer`、`MutualPlayer` 结构体完全相同（name, gender, ntrp, latestActivity），各自 private 定义且三份 mock 数据里同一批人重复。

**P0 - FlowLayout 重复实现**
`PublicProfileView.swift:331-360` 的 `FlowLayoutPublic` 与 `RegisterView` 中的 `FlowLayout` 逻辑完全相同。

**P1 - PublicPlayerData 在 4+ 处 hardcode 构造**
`FollowingView:128-143` / `FollowerListView:112-128` / `MutualFollowListView:129-144` / `ChatDetailView:189-204` — 同一球友在不同页面 reputation/bio/matchCount 值不一致（85/88/90）。

**P1 - FollowStore.mutualCount 和 followerCount 是静态值**
`FollowStore.swift:21-22, 28-29` — 取消关注后计数不变化。

**P1 - EditProfileView 偏好时段和球友水平不保存**
`EditProfileView.swift:298-317` — `preferredSlots` 和 `partnerLevelLow/High` 是本地 @State，保存按钮不同步到 UserStore，退出后丢失。

**P2 - ProfileView "出席率" "總場次" "本月場次" 硬编码**
`ProfileView.swift:261, 321-322` — 写死 "92%"、"28"、"5"。

**P2 - PublicProfileView 私信按钮缺少 navigationDestination**
`PublicProfileView.swift:281-288` — 创建了 MockChat 但无导航接收器，点击无效。

### 2. 用户体验

**P1 - EditProfileView 无"未保存提醒"**
修改资料后点返回直接 dismiss，修改丢失无确认。

**P1 - 粉丝列表取消互关无确认弹窗**
`FollowerListView.swift:88-105` — FollowingView 和 MutualFollowListView 都有确认，FollowerListView 没有，交互不一致。

**P2 - 关注/粉丝/互关列表的 row 代码 90% 重复**
三个文件 playerRow 几乎一样。

### 3. 视觉设计

**P2 - "理想球友"标签始终显示**
`ProfileView.swift:188-194` — 不论用户实际状态如何都显示金色标签。

### 4. 亮点

- NTRP 校准系统设计精良（漂移检测 + 三种响应 + dismiss 记忆）
- EditProfileView 的 draft pattern（本地修改不直接写 store）
- 用户名唯一性检查
- 三页空状态均有处理
- 取消关注有确认弹窗

### 模块五总结

| 严重度 | 数量 | 关键项 |
|--------|------|--------|
| P0 | 2 | 三套重复数据模型、FlowLayout 重复 |
| P1 | 5 | PublicPlayerData 构造不一致、FollowStore 静态计数、偏好时段不保存、无未保存提醒、取消互关无确认 |
| P2 | 5 | 硬编码统计、私信按钮无效、row 代码重复、理想球友标签、navBar .white 背景 |

---

## 模块六：赛事 + 约球助手

### 涉及页面
`TournamentView` / `TournamentDetailView` / `CreateTournamentView` / `MatchAssistantView`

### 1. 交互与功能逻辑

**P1 - TournamentDetailView "关注"按钮不走 FollowStore**
`TournamentDetailView:308, 510-519` — 使用本地 @State，与全局 FollowStore 无关联。

**P1 - 赛事可重复报名**
`TournamentDetailView:588-589` — 无 guard 防止重复点击报名。

**P1 - 报名不更新 participants 和 playerList**
`TournamentDetailView:348-351, 544` — 报名后参赛人数和选手列表不变化。

**P1 - organizer DM 性别硬编码**
`TournamentDetailView:357` — 联系发起人时硬编码 `"♂"` 和 `Theme.genderMale`。

**P2 - CreateTournamentView 发布后无成功反馈**
`CreateTournamentView:625-628` — 直接 dismiss，无 toast 或 success 页面。

**P2 - MatchAssistantView endHour 可能超过 24**
`MatchAssistantView:185, 195` — startHour=23 时 endHour=25，显示 "23:00 - 25:00"。

### 2. 用户体验

**P1 - 赛事规则只有单行 TextField**
`CreateTournamentView:413` — 多条规则无法方便输入。

**P2 - CreateTournamentView 无"未保存提醒"**
填写大量信息后点返回直接丢失。

### 3. 视觉设计

**P2 - "建立賽事"按钮 28pt、报名按钮 26pt 高度**
`TournamentView:108, 225` — 低于 44pt 触控目标。

### 4. 亮点

- 智能赛制推荐（根据人数自动推荐）
- 日历集成（CalendarService）
- 赛事卡片用不同渐变色区分
- 确认发布有信息确认 sheet
- 匹配推荐附带可读理由

### 模块六总结

| 严重度 | 数量 | 关键项 |
|--------|------|--------|
| P1 | 5 | 关注不走 Store、重复报名、报名不更新、性别硬编码、规则单行输入 |
| P2 | 4 | 发布无反馈、endHour 溢出、无未保存提醒、按钮高度 |

---

## 模块七：设置 + 信息页面

### 涉及页面
`SettingsView` / `HelpView` / `NotificationsView` / `ReviewsView` / `AchievementsView`

### 1. 交互与功能逻辑

**P1 - Settings 通知开关和隐私选项不持久化**
`SettingsView.swift:13-17` — 所有 Toggle 和 Picker 使用本地 @State，退出页面后全部丢失。应使用 @AppStorage。

**P1 - 手机号码硬编码 "+86 138****8888"**
`SettingsView.swift:95` — 与用户实际注册号码无关。

**P1 - 修改密码不验证当前密码**
`SettingsView.swift:263-268` — 点击提交直接显示"密碼修改成功"，不验证 currentPassword。

**P1 - LinkedAccountsSheet 关联状态不持久化**
`SettingsView.swift:329-331` — 本地 State，关闭 sheet 后重置。

**P1 - 评价不写入 RatingFeedbackStore**
`ReviewsView.swift:81-88` — 提交评价只从本地数组移除，不影响被评价者的 NTRP 校准。

**P2 - NotificationsView 点击通知生成的 MatchDetailData 全部 hardcoded**
`NotificationsView.swift:128-195` — 固定日期/地点，与通知内容可能不匹配。

**P2 - 文字解析逻辑脆弱**
`NotificationsView.swift:199-225` — 依赖空格分割和中文括号提取数据。

### 2. 用户体验

**P2 - ChangePasswordSheet toast 1.2 秒自动 dismiss**
`SettingsView.swift:266-268` — 时间太短。

**P2 - AchievementsView 无详情交互**
点击徽章无反应，没有达成进度展示。

**P2 - ReviewsView 评价默认 5 星无校验**
`ReviewsView.swift:15, 267` — 用户不操作直接提交总是 5 星。

### 3. 亮点

- 退出登录有确认弹窗
- LinkedAccountsSheet "至少保留一种"保护
- HelpView FAQ 手风琴交互
- ReviewsView 评价表单完整（星级 + 多行文字）
- AchievementsView 已解锁/未解锁视觉区分
- NotificationsView 全部已读 + 未读圆点

### 模块七总结

| 严重度 | 数量 | 关键项 |
|--------|------|--------|
| P1 | 5 | 设置不持久化、手机号硬编码、密码不验证、关联状态不存、评价不入 Store |
| P2 | 5 | 通知 hardcoded detail、文字解析脆弱、toast 过快、成就无详情、评价默认 5 星 |

---

## 全局性问题汇总（跨模块，更新版）

### 架构层面
1. **无 Dark Mode 支持** — Theme 全部硬编码颜色，`.background(.white)` 遍布各页面
2. **无 Dynamic Type 支持** — Typography 全部使用 `Font.system(size:)` 硬编码
3. **HomeView God Object** — 1968 行 + 40 个 @State，需要拆分
4. **三套重复 Player 数据模型** — FollowedPlayer / FollowerPlayer / MutualPlayer 完全相同
5. **FlowLayout 重复实现** — RegisterView 和 PublicProfileView 各有一份

### 设计一致性
6. **Toast 样式不统一** — 至少 4 种不同的 toast 实现
7. **"关注"按钮样式在不同页面逻辑相反**
8. **NTRP 滑块代码重复** — HomeView、CreateMatchView、EditProfileView 各写了一份
9. **报名确认/成功页重复** — HomeView 和 MatchDetailView 各写了一份
10. **PublicPlayerData 在 4+ 处 hardcode 构造且值不一致**

### 功能完整性
11. **"拉球"类型全链路缺失** — MatchType 有定义但筛选和创建都不支持
12. **所有成功操作无 haptic feedback**
13. **无下拉刷新**
14. **Mock 数据会随时间过期**
15. **FollowStore 计数是静态值** — mutualCount/followerCount 不随操作变化
16. **多个 Store 数据不持久化** — Settings 开关、关联帐号、偏好时段等退出后丢失
17. **评价不写入校准系统** — ReviewsView → RatingFeedbackStore 断链

---

## 审计完成统计

| 模块 | P0 | P1 | P2 | 总计 |
|------|-----|-----|-----|------|
| 一：认证与注册 | 2 | 4 | 3 | 9 |
| 二：首页 + 约球 | 2 | 9 | 5 | 16 |
| 三：发布 + 我的约球 | 2 | 8 | 3 | 13 |
| 四：聊天系统 | 0 | 5 | 6 | 11 |
| 五：个人资料 + 社交 | 2 | 5 | 5 | 12 |
| 六：赛事 + 助手 | 0 | 5 | 4 | 9 |
| 七：设置 + 信息页 | 0 | 5 | 5 | 10 |
| **合计** | **8** | **41** | **31** | **80** |
