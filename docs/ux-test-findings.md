# Let's Tennis — UX 测试与修复计划

> 分支:`fix/ux-test-fixes`
> 角色定位:资深 iOS QA,按功能模块从关键路径往边界情况扫
> **严重等级:P0 (阻断主流程 / 数据错乱) · P1 (体验明显受损) · P2 (打磨项)**

---

## 一、已发现的问题清单(按模块)

### 📍 模块 1:首页 HomeView + 约球发布/报名

| # | 问题 | 等级 | 复现 | 建议 |
|---|---|---|---|---|
| 1.1 | Tab 2 "一鍵約球" 仍是 `placeholderTab`,核心功能缺失 | **P0** | 点击底部第 3 个 tab | 接入 `MatchAssistantView` 或正式实现一键匹配流 |
| 1.2 | 报名后取消回调用 `name + location` 匹配 (`HomeView.swift:54-61`),若两个约球同名同地会错改数据 | **P0** | 创建两条"莎拉·維園"的约球,取消其中一条 | 改用 `match.id`(UUID)回传,而不是 name/location |
| 1.3 | 约球列表未按日期排序;接受邀请后插入 `acceptedMatchItems` 永远置顶 | P1 | 接受 04/27 邀请 → 仍排在 04/19 前 | 按 `dateLabel` 解析成 `Date` 后统一排序 |
| 1.4 | 报名成功后回到列表,"報名中"按钮仍可再次点击,依赖 `signedUpMatchIDs` 去重但首页卡片视觉无变化 | P1 | 报名 → 返回 → 再次点"報名" | 卡片需显示 "已報名" 灰态,按钮禁用 |
| 1.5 | `SignUpSuccessView` 的"加入日曆"是 TODO (`MyMatchesView.swift:726`, `MatchDetailView.swift:647`) | P1 | 报名成功 → 点加入日历无反应 | 调 EventKit `EKEventStore.saveEvent`,首次使用弹权限 |
| 1.6 | 无空态:"我的約球"全空时只显示空白 `VStack` | P1 | 全拒邀请、全取消约球 | 加 `ContentUnavailableView` 引导用户去首页约球 |

### 📍 模块 2:约球详情 MatchDetailView

| # | 问题 | 等级 | 复现 | 建议 |
|---|---|---|---|---|
| 2.1 | 返回按钮用 `Text("←")` (`MatchDetailView.swift:41-44`),不符合 iOS HIG,也不自动镜像 RTL | **P0** | 进入详情看左上角 | 换 SF Symbol `chevron.left` + `.font(.system(size:17, weight:.medium))` |
| 2.2 | 报名成功后跳 ChatDetail 传入 `acceptedMatches: .constant([])` (`MatchDetailView.swift:363`),绑定与外层脱节,聊天里"確認到場"永远无效 | **P0** | 详情页报名成功 → 进入聊天 → 邀请卡片不会显示"已確認" | 把 `@Binding var acceptedMatches` 一路透传下来 |
| 2.3 | 详情页 `participantList` 是静态 struct,报名成功后不会把自己加入参加者列表 | P1 | 看 1/2 人 → 报名 → 仍然 1/2 人 | 改用 `@State` 的参加者数组,在 `onConfirm` 里 append 当前用户 |
| 2.4 | `isFollowing` 是 `@State` 局部状态,与 ProfileView 的 "關注 23" 不联动 | P1 | 关注对方 → 回 Profile 看关注数 | 抽出全局 `FollowStore` (ObservableObject),或用 `.environment` 注入 |
| 2.5 | 大量硬编码颜色 `Color(hex: 0x218C21)`, `0x666666`, `0xE0E0E0` (`MatchDetailView.swift:118,123,131,294,303,308,320`),违反 CLAUDE.md 规则 #2 | P1 | grep | 统一替换成 `Theme.primary` / `Theme.textBody` / `Theme.inputBorder` |
| 2.6 | 报名弹窗里"給發起人留言"输入的 `message` 从未被读取,点确认后丢失 | P1 | 输入留言 → 确认 | 将 message 塞进 `MockChat.lastMessage` 或 matchContext 带过去 |
| 2.7 | 已满员的约球没有单独状态(按钮依旧是绿色"報名"),点下去才报错 | P1 | 把 players 改为 `2/2` | 通过 `players` 解析 current/max,满员时按钮显示"已額滿"且禁用 |

### 📍 模块 3:我的约球 MyMatchesView

| # | 问题 | 等级 | 复现 | 建议 |
|---|---|---|---|---|
| 3.1 | 发起人管理 ActionSheet 里 "編輯約球 / 查看報名者 / 關閉報名" 三项全是 TODO (`MyMatchesView.swift:110-117`) | **P0** | 自己发起的约球 → 管理 | 至少接空 View 或明确"即將推出"提示,不能直接静默无响应 |
| 3.2 | 接受邀请时 `AcceptedMatchInfo` 用固定 `time: "10:00"` (`MyMatchesView.swift:452`),真实邀请的时间丢失 | **P0** | 艾美 04/22 邀请本来 14:00 | 邀请 Model 里就要带 `time` 字段,不从字符串解析 |
| 3.3 | `acceptedMatchItems` 里 `endHour = startHour + 2` 硬编码 2 小时 (`MyMatchesView.swift:38`),双打/单打时长不一定 | P1 | 接受一条 2h 以外的邀请 | 邀请模型里带 duration,或让 endTime 由模型直接给 |
| 3.4 | 标题反向解析用 `replacingOccurrences(of: " 發起的單打/雙打"...)`(`MyMatchesView.swift:88-91`)非常脆,若日后"發起的混雙"就漏掉 | P1 | 新增 matchType "混雙" | Model 里直接存 `organizerName`,不要从 title 反解 |
| 3.5 | 两个 Toast overlay (`showCancelledToast` / `showRejectToast`)同时可能出现并重叠 | P2 | 快速拒绝 + 取消 | 抽成单一 toast 队列 |
| 3.6 | 拒绝邀请仅 `rejectedInvitations.insert`,下次进入 App 又会出现(未持久化) | P2 | 拒绝 → 切 tab → 回来 | 持久化到 `@AppStorage` 或后端 |

### 📍 模块 4:聊天 ChatDetail + Messages

| # | 问题 | 等级 | 复现 | 建议 |
|---|---|---|---|---|
| 4.1 | `organizerName` 用空格分割 title (`ChatDetailView.swift:32`),发起人名字含空格就错 | P1 | name = "小 明" | title 拼接处加分隔符如 ` · `,或直接存 organizerName 字段 |
| 4.2 | `allMessages` 是 computed,每次重绘都遍历 `mockMessages` + `sentMessages`,消息多时性能下滑 | P2 | 长聊天 | 用 `@State` 聚合,只在新消息时 append |
| 4.3 | 图片上传 PhotosPicker 流程选完后没有在气泡中显示 `selectedPhotoData` | P1 | 点 📷 选图 → 发送 | 新增 `ChatBubble.image(Data)` 类型并渲染 |
| 4.4 | 系统消息 `matchContext` 一旦进入就无法清除(没有关闭按钮) | P2 | 从报名成功跳聊天 | 给系统卡片加 ✕,或只在首次展示 |
| 4.5 | Messages 列表未读数与 `totalUnread` 的同步依赖手动 `-=`,进入详情后若返回再进入会重复扣减 | P1 | 反复点同一会话 | 用会话级 `unreadCount = 0` 幂等清零 |

### 📍 模块 5:Profile / Settings / 其他

| # | 问题 | 等级 | 复现 | 建议 |
|---|---|---|---|---|
| 5.1 | `ProfileView.ignoresSafeArea(edges: .top)` 作为 tab 子视图会让整机顶部 Status Bar 穿透,影响系统时间可读性 | P1 | 切到 Profile tab,浅色背景处看不清电量 | 只让 headerSection 背景延伸,不对整个 view `ignoresSafeArea` |
| 5.2 | 关注/粉丝/互相关注数硬编码 "23/18/12" ,点击无跳转 | P1 | 点"粉絲" | 绑定到 FollowStore,并加 `NavigationLink → FollowingView` |
| 5.3 | SettingsView 的"退出登录"如果点了当前没有返回 LoginView 的流程 | **P0** | 点登出 | 在 `TennisMatchApp` 注入 `@AppStorage("isLoggedIn")`,退出后切回 LoginView |
| 5.4 | `EditProfileView` 的修改是否持久化待验证(尤其是昵称→影响 Chat 里"我") | P1 | 改昵称 → 约球卡片 | 统一从 `UserStore` 读取 |
| 5.5 | NotificationsView / ReviewsView / AchievementsView 全空时均无空态提示 | P2 | 新账号 | 同 1.6 加 `ContentUnavailableView` |
| 5.6 | BlockList 解除拉黑后,对应用户在 FollowingView 没有恢复可见(若曾互相关注) | P2 | 互相关注 → 拉黑 → 解除 | 解除时同步 FollowStore |

### 📍 模块 6:全局 / 跨模块

| # | 问题 | 等级 | 建议 |
|---|---|---|---|
| 6.1 | 多处 `Color(hex: 0x...)` / 字号 12/13/14 硬编码,违反 CLAUDE.md 规则 #2 | P1 | 批量替换为 `Theme.*` / `Typography.*` |
| 6.2 | 日期全为字符串,不能比较/排序/过滤 | P1 | 新增 `MatchDate` 类型(或直接 `Date`),展示层再 `formatted(...)` |
| 6.3 | Mock 数据分散在各 View 内 `private let`,无法跨页面联动 | P1 | 抽到 `Models/MockData.swift`,视图通过 Store 读 |
| 6.4 | 无 iPhone SE 的实际验收截图;多处 `.frame(height: 60)` / `Spacer().frame(height: xxl)` 在小屏可能超出 | P2 | 在 SE 预览过一遍;必要处改响应式间距 |
| 6.5 | 无深色模式验证;不少 `.white` / `Color(hex:)` 背景在 dark mode 不适配 | P2 | 通一遍深色预览;硬编码色改 Theme |

---

## 二、修复执行建议

### 🔥 Batch 1 — P0 修复(先合这批,这是 ship-blocker)

| # | 任务 | 影响文件 | 预估改动 |
|---|---|---|---|
| B1-1 | 修首页取消回调为 UUID 匹配 | `HomeView.swift`, `MyMatchesView.swift` | +回调签名 `(UUID) -> Void` |
| B1-2 | MatchDetail → ChatDetail 传 `@Binding acceptedMatches` | `MatchDetailView.swift`, 调用方 | 改构造参数 |
| B1-3 | MatchDetail 返回按钮换 `chevron.left` SF Symbol | `MatchDetailView.swift:41` | 3 行 |
| B1-4 | Tab 2 "一鍵約球" 接 `MatchAssistantView` | `HomeView.swift:62` | 1 行 |
| B1-5 | 发起人管理 ActionSheet 三项 TODO 至少跳到占位页 / Toast "即將推出" | `MyMatchesView.swift:110-117` | 3 个 handler |
| B1-6 | 邀请 Model 增补 `time`/`duration`;`acceptedMatches.append` 不再用 "10:00" | `MyMatchesView.swift:446-454` | 数据模型+2 行 |
| B1-7 | SettingsView 登出 → 回到 LoginView | `TennisMatchApp.swift` + `SettingsView.swift` | 加 `@AppStorage("isLoggedIn")` 根切换 |

### ⚡ Batch 2 — P1 体验一致性

| # | 任务 |
|---|---|
| B2-1 | 抽 `FollowStore`(关注/粉丝/互相关注),Profile/MatchDetail/Following 联动 |
| B2-2 | 抽 `UserStore`(昵称/性别/NTRP),EditProfile 写入,其他读 |
| B2-3 | 报名后首页卡片改 "已報名" 禁用;MatchDetail `participantList` 动态追加 |
| B2-4 | 报名留言带到 Chat matchContext / 或首条发送消息 |
| B2-5 | 满员约球按钮 "已額滿" 禁用 |
| B2-6 | "加入日曆"接 EventKit(2 处:MyMatches / MatchDetail 的 SuccessView) |
| B2-7 | 聊天图片气泡渲染 |
| B2-8 | 未读数幂等清零 |
| B2-9 | ProfileView 去除全局 `ignoresSafeArea(edges: .top)`,只让 header 背景延伸 |
| B2-10 | 日期统一用 `Date`,排序"我的約球"和首页列表 |
| B2-11 | 硬编码色/字号全部替换为 `Theme.*` / `Typography.*` |
| B2-12 | 所有列表空态加 `ContentUnavailableView` |

### ✨ Batch 3 — P2 打磨

| # | 任务 |
|---|---|
| B3-1 | Toast 统一成队列式管理器(避免叠加) |
| B3-2 | 拒绝邀请、拉黑、关注等状态 `@AppStorage` 持久化(demo 阶段够用) |
| B3-3 | iPhone SE 实机走查所有页面 |
| B3-4 | 深色模式 Preview 通检,修复配色 |
| B3-5 | RTL 布局:所有 `chevron.left` 依赖系统镜像,避免 `Text("←")` |
| B3-6 | 信譽分点击显示来源 / 历史 |

---

## 三、合并与验证流程

1. **Batch 1 先合成一个单独的 PR**(`fix/p0-blockers`),并在每条修复后添加最小 mock 验证——这批修完后,"首页 → 报名 → 聊天 → 確認到場" 主干路径才真正跑通。
2. **Batch 2 拆成两个 PR**:`refactor/stores`(FollowStore/UserStore + Theme 替换)先合,再走 `feat/p1-ux-polish`(卡片状态 / 留言 / 空态)。
3. **Batch 3 可作为 "ship 前清单",不单独开分支**,每项一 commit 合到 develop。
4. 每合一个 Batch,按 CLAUDE.md 要求在 iPhone SE 和 15 Pro Preview 各跑一遍,顺便验证浅/深色。
