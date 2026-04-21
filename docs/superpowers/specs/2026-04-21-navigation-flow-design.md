# Let's Tennis — 全局导航流设计

## 概述

本文档定义 Let's Tennis App 中所有按钮的点击目标和页面间的连接关系。核心设计原则：**约球和找球双向同等重要**，报名后立刻进入沟通环节，缩短从"发现"到"打球"的路径。

---

## 一、主流程：约球生命周期

### 1.1 发起者路径

```
首页 [+一键约球]
  → CreateMatchView (fullScreenCover)
    → 发布成功 → 回到首页，卡片出现在列表
      → 收到报名通知（NotificationsView）
        → 点通知 → MatchDetailView（发起者视角）
          → [管理] → ActionSheet：编辑约球 / 查看报名者 / 关闭报名 / 取消约球
          → 约球群聊（自动创建）
```

### 1.2 参与者路径

```
首页 → 点击约球卡片
  → MatchDetailView
    → [报名] → 确认弹窗 → 成功页 → 自动跳到约球群聊 (ChatDetailView)
    → [私信] → 一对一私聊 (ChatDetailView)
    → [关注] → 关注发起者（按钮就地切换为"已关注"）
```

### 1.3 关键规则

- "报名"进**约球群聊**，"私信"进**一对一私聊**，两个是不同的聊天室
- 聊天列表（MessagesView）用标签区分"约球群聊"和"个人私信"
- "管理"用 ActionSheet 弹出，不跳新页面
- "关注"是关注**人**，不是收藏帖子。理由：约球帖子有时效性，关注人才能持续看到新动态

---

## 二、Tab 栏导航

### Tab 0：首页 (HomeView)

| 元素 | 动作 | 目标 | 状态 |
|------|------|------|------|
| 约球卡片 [点击] | push | MatchDetailView | 已有 |
| 约球卡片 [报名] | sheet → fullScreenCover | 确认弹窗 → 成功页 → 群聊 | 需改终点 |
| [筛选] | toggle | 筛选面板 | 已有 |
| [侧边栏] | overlay | 抽屉菜单 | 已有(菜单项需连通) |

### Tab 1：我的约球 (MyMatchesView)

| 元素 | 动作 | 目标 | 状态 |
|------|------|------|------|
| 约球卡片 [点击] | push | MatchDetailView | 需新增 |
| [管理] | ActionSheet | 编辑约球 / 查看报名者 / 关闭报名 / 取消约球 | 需新增 |
| [取消] | Alert | 确认取消 → toast | 已有 |
| [聊天] | push | ChatDetailView | 已有 |
| 邀请 [接受] | 状态更新 | 加入约球，跳到群聊 | 需改终点 |
| 邀请 [拒绝] | 动画移除 | 卡片消失 + toast 提示 | 需新增 |

### Tab 2：一键约球（中间按钮）

| 元素 | 动作 | 目标 | 状态 |
|------|------|------|------|
| [+] | fullScreenCover | CreateMatchView | 已有 |

### Tab 3：聊天 (MessagesView)

| 元素 | 动作 | 目标 | 状态 |
|------|------|------|------|
| 聊天卡片 [点击] | push | ChatDetailView | 已有 |
| [左滑删除] | swipe | 删除聊天 | 已有 |

### Tab 4：我的 (ProfileView)

| 元素 | 动作 | 目标 | 状态 |
|------|------|------|------|
| [编辑资料] | push | EditProfileView | 已有 |
| [设定] | push | SettingsView | 需连通 |
| 赛事记录 [全部] | push | TournamentView（筛选"已完成"） | 需连通 |
| 成就徽章 [全部] | push | AchievementsView | 需新增 |

---

## 三、赛事模块

```
侧边栏 [赛事]
  → TournamentView (fullScreenCover)
    → 赛事卡片 [点击] → TournamentDetailView
      → [立即报名] → 确认弹窗 → 成功页 → 跳到赛事群聊
      → [关注] → 关注组织者（就地切换状态）
    → [+ 建立赛事] → CreateTournamentView
      → 发布成功 → 回到赛事列表
```

- 赛事报名流程与约球报名**对称**：确认弹窗 → 成功页 → 自动跳群聊
- 赛事也自动创建群聊，方便参赛者沟通

---

## 四、侧边栏菜单项

### 4.1 导航表

| 菜单项 | 目标页面 | 展示方式 |
|--------|---------|---------|
| 赛事 | TournamentView | fullScreenCover（已有） |
| 约球助理 | MatchAssistantView | push 导航 |
| 评价 | ReviewsView | push 导航 |
| 通知 | NotificationsView | push 导航 |
| 关注 | FollowingView | push 导航 |
| 封锁名单 | BlockListView | push 导航 |
| 邀请好友 | InviteFriendsView | push 导航 |
| 设定 | SettingsView | push 导航 |
| 帮助 | HelpView | push 导航 |

### 4.2 各页面详细定义

#### MatchAssistantView（约球助理）

智能推荐匹配的约球，基于用户 NTRP、常去球场、空闲时间。

- 页面结构：推荐约球卡片的 feed 列表
- 推荐卡片 [点击] → MatchDetailView（复用）
- 推荐卡片 [报名] → 报名流程（复用）

#### ReviewsView（评价）

查看别人对你的评价 + 你待评价的球友。

- 页面结构：两个 Tab — "收到的评价" / "待评价"
- 收到的评价：评分 + 短评列表
- 待评价卡片 [点击] → 评价填写弹窗（sheet）：评分（1-5星） + 短评文本框 + 提交按钮
- 提交后卡片从"待评价"消失，toast 提示成功

#### NotificationsView（通知）

只做约球相关通知（聚焦核心功能）。

- 通知类型：
  - 有人报名了你的约球
  - 你的报名被接受
  - 约球被取消
  - 约球时间/地点变更
- 通知卡片 [点击] → 跳转到对应的 MatchDetailView
- 支持标记已读 / 全部已读

#### FollowingView（关注）

你关注的球友的动态流。

- 页面结构：球友列表，每人显示头像、名字、NTRP、最新动态
- 球友行 [点击] → PublicProfileView（新页面）
- 动态卡片 [点击] → MatchDetailView（复用）
- 球友行 [取消关注] → 确认 Alert → 从列表移除

#### PublicProfileView（球友公开主页）

展示他人资料的只读版本。

- 页面结构：复用 ProfileView 的布局，但去掉"编辑资料"
- [关注 / 取消关注] 按钮
- [私信] → ChatDetailView（一对一私聊）
- [封锁] → 确认 Alert → 封锁该用户
- 该球友发布的约球历史列表
- 约球卡片 [点击] → MatchDetailView

#### BlockListView（封锁名单）

被封锁的用户列表。

- 页面结构：简单用户行列表
- 用户行 [解除封锁] → 确认 Alert → 从列表移除

#### InviteFriendsView（邀请好友）

生成邀请链接 / 分享。

- 页面结构：邀请码展示 + 分享按钮
- [分享] → iOS 原生 ShareSheet（UIActivityViewController）
- 支持分享到微信、短信、复制链接等

#### SettingsView（设定）

App 设置项。进入方式：侧边栏"设定" 或 个人中心"设定"按钮，指向同一个页面。

- 页面结构：分组列表
  - 账号与安全（手机号、密码、关联账号）
  - 通知偏好（约球提醒、聊天消息、赛事更新）
  - 隐私设置（谁能看到我的资料、谁能私信我）
  - 关于我们（版本号、用户协议、隐私政策）
  - [退出登录] → 确认 Alert → 清除导航栈，回到 LoginView

#### HelpView（帮助）

FAQ + 联系客服。进入方式：侧边栏"帮助" 或 登录页"联系客服"，指向同一个页面。

- 页面结构：FAQ 折叠列表（DisclosureGroup）
- [联系客服] → 打开系统邮件（mailto:）或跳转客服页面

---

## 五、登录模块

```
LoginView
  ├─ [手机号码登录] → PhoneVerificationView → RegisterView → HomeView（已有）
  ├─ [微信登录] → 微信 SDK 授权 → 首次：RegisterView / 已注册：HomeView
  ├─ [Apple 登录] → Apple Sign In → 首次：RegisterView / 已注册：HomeView
  ├─ [立即注册] → PhoneVerificationView（复用，走注册流程）
  └─ [联系客服] → HelpView（复用）
```

### 登录方式实现

| 方式 | 技术方案 |
|------|---------|
| 手机号 | 现有流程：验证码验证 |
| 微信登录 | 微信 SDK（WechatOpenSDK），授权回调获取用户信息 |
| Apple 登录 | iOS 原生 AuthenticationServices 框架 |

### 新/老用户分流逻辑

- 三种方式授权成功后，检查后端是否已存在该用户
- 新用户 → RegisterView 补全资料（头像、名字、NTRP 等）
- 老用户 → 直接进入 HomeView

### 退出登录

- SettingsView [退出登录] → 确认 Alert → 清除用户状态 → 回到 LoginView

---

## 六、ChatDetailView 补全

现有"..."按钮的操作菜单：

- **约球群聊时：**
  - 查看约球详情 → MatchDetailView
  - 查看群成员
  - 静音通知（开关）
  - 退出群聊 → 确认 Alert

- **一对一私聊时：**
  - 查看对方资料 → PublicProfileView
  - 静音通知（开关）
  - 封锁对方 → 确认 Alert → BlockListView 新增
  - 删除聊天 → 确认 Alert

---

## 七、新增页面清单

| 新页面 | 触发入口 | 展示方式 |
|--------|---------|---------|
| MatchAssistantView | 侧边栏"约球助理" | push |
| ReviewsView | 侧边栏"评价" | push |
| NotificationsView | 侧边栏"通知" | push |
| FollowingView | 侧边栏"关注" | push |
| PublicProfileView | 关注列表 / 聊天"..." | push |
| BlockListView | 侧边栏"封锁名单" | push |
| InviteFriendsView | 侧边栏"邀请好友" | push |
| SettingsView | 侧边栏"设定" / 个人中心"设定" | push |
| HelpView | 侧边栏"帮助" / 登录页"联系客服" | push |
| AchievementsView | 个人中心成就"全部" | push |

共 10 个新页面。

---

## 八、现有页面改动清单

| 页面 | 改动内容 |
|------|---------|
| HomeView | 侧边栏菜单项全部连通；报名成功后终点改为群聊 |
| MatchDetailView | 连通"报名"(→确认→成功→群聊)、"私信"(→一对一聊天)、"关注"(就地切换) |
| TournamentDetailView | 连通"立即报名"(→确认→成功→赛事群聊)、"关注"(就地切换) |
| MyMatchesView | "管理"改为 ActionSheet；"拒绝"邀请加逻辑(卡片消失+toast)；"接受"邀请跳群聊 |
| ChatDetailView | "..."按钮弹出操作菜单（群聊/私聊两套选项） |
| ProfileView | 连通"设定"→SettingsView；赛事"全部"→TournamentView；成就"全部"→AchievementsView |
| LoginView | 实现微信登录(微信SDK)、Apple登录(AuthenticationServices)、"立即注册"→PhoneVerificationView、"联系客服"→HelpView |

共 7 个现有页面改动。

---

## 九、导航方式规范

| 场景 | 方式 | 理由 |
|------|------|------|
| 页面间正常跳转 | NavigationStack push | 保留返回手势 |
| 创建类流程 | fullScreenCover + 内嵌 NavigationStack | 独立流程，完成后 dismiss |
| 确认/选择类小弹窗 | sheet | 半屏弹出，操作后收回 |
| 快速操作选项 | ActionSheet / confirmationDialog | 不离开当前页，弹出选项 |
| 状态切换 | 就地按钮状态变化 | 如"关注"→"已关注"，无需跳转 |
