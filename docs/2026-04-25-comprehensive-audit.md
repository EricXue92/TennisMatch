# TennisMatch 综合审计报告

> **审计日期**：2026-04-25
> **审计范围**：~50 个 Swift 文件
> **审计维度**：状态管理 / 并发安全 / 时间·性能·HIG / UX 逻辑
> **目标平台**：iOS 17+（SwiftUI + `@Observable`）

---

## 一、综合评分

| 维度 | 分数 | 关键瓶颈 |
|---|---|---|
| **代码质量** | **6.5 / 10** | 状态分层混乱（`HomeView` 27 个 `@State`）、时间字段仍以 String 主导、DateFormatter 重复构造 12+ 处 |
| **用户体验** | **6.0 / 10** | 取消无 5s 撤销、表单错误反馈缺失、空状态遮挡邀请、过期判断结果可能不一致 |
| **架构清晰度** | 7 / 10 | 7 个 Store 注入合理，但缺协调层、`acceptedMatches` 多处持有 |
| **HIG 合规** | 5 / 10 | 强制 `.preferredColorScheme(.light)`、固定 `.system(size:)` 45+ 处、24pt 按钮、`Color.white` 硬编码 |
| **并发安全** | 6 / 10 | 报名/取消乐观更新无回滚；按钮无防抖；Store 无显式 `@MainActor` |

---

## 二、关键问题（按严重度 P0 → P2）

### 🔴 P0 — 数据正确性 / 用户损失风险

#### 1. 时间过期判断散落，结果可能不一致
- **现象**：`MatchDetailView.swift:527-532`、`MatchSchedule.swift:71-80`、`MyMatchesView.swift:276-281` 各自从字符串解析 `isExpired`，格式（`04/19` vs `2026/04/19`）一旦漂移，详情页与"我的约球"对同一场显示相反结果。
- **Fix**：`MatchSchedule.isExpired(start: Date)` 入参换 `Date`；`SignUpMatchInfo` / `MatchDetailData` 持久化 `startDate: Date`,从此弃用字符串拼接。

#### 2. 报名/取消乐观更新无回滚
- **现象**：`HomeView.swift:117-121` 直接 `matches[idx].currentPlayers += 1` + 写多个 Store；`MyMatchesView.swift:284-289` 取消同样无 try/catch。后端接入后任一失败 UI 即永久错乱。
- **Fix**：包裹 `Task { do { snap = state; await api...; } catch { state = snap } }`,或先进 `pending` 中间态。

#### 3. 报名按钮无防抖 / 无 loading
- **现象**：`SignUpConfirmSheet.swift:50-62` 按钮无 `.disabled` / 无 `isSubmitting`；`MatchDetailView.swift:418` 同。快速双击 → `currentPlayers += 2`。
- **Fix**：`@State var isSubmitting`,`.disabled(isSubmitting)`,按钮内部切到 ProgressView。

#### 4. 取消约球无 5s 撤销窗口
- **现象**：`MyMatchesView.swift:273-334` 用户连按"確認取消"立即扣信誉、解 BookedSlot、推通知,无法恢复。距开场 <2h 直接 -2 分。
- **Fix**：取消后 toast + "撤销"按钮,5s 内回滚事务。

---

### 🟡 P1 — UX / 性能

#### 5. `acceptedMatches` 在多个 View 之间靠 `@Binding` 链路传递
- **现象**：`HomeView.swift:40` 起,3+ 处可写。`signedUpMatchIDs` 与 `BookedSlotStore` 双重真理（`HomeView:46, 118-119`）,取消时易脱节。
- **Fix**：抽 `@Observable BookingStore`,注入 environment,唯一入口管理 `signedUpMatchIDs / acceptedMatches / bookedSlots`。

#### 6. `HomeView` 单文件 1220+ 行 / 27 个 `@State` / `filteredMatches` 每帧重算
- **现象**：`HomeView.swift:13-54, 403-449, 478` `body` 内做 filter+sort,Tab 切换时全树评估。
- **Fix**：tab 拆子 View；filter 逻辑移到 `@Observable MatchFilterModel`；用 `onChange(of:)` 缓存到 `@State cachedFiltered`。

#### 7. 列表无虚拟滚动 / 无 LazyVStack
- **现象**：`HomeView.swift:451-491`、`MyMatchesView.swift:10+`、`RecommendedPlayersSection.swift:15-35` 均 `VStack + ForEach`。当前 mock 数据小,但接入后端后立刻卡顿。
- **Fix**：列表换 `LazyVStack` 或 `List { ... }.listStyle(.plain)`。

#### 8. 表单字段验证错误不显示 toast
- **现象**：`CreateMatchView.swift:432-436, 468-485` 所有错误写到 `validationMessage`,但 toast 仅在 `showCostError=true` 弹出。日期/球场/NTRP 校验失败 → 静默。
- **Fix**：统一改 `@State showValidationError: Bool` + 公共 toast；必填字段 UI 加 `*`。

#### 9. 空状态遮挡邀请
- **现象**：`MyMatchesView.swift:187-247` "即將到來"若 `acceptedMatches` 空但 `visibleInvitations` 非空,仍显示 `ContentUnavailableView`,邀请被挤到下方。
- **Fix**：仅在三类全空时显示 ContentUnavailable；有邀请则显示"你有 N 條新邀請"行动入口。

---

### 🟢 P2 — HIG / 工艺

#### 10. 强制浅色模式
- **现象**：`TennisMatchApp.swift:36` `.preferredColorScheme(.light)` 全局禁用 Dark Mode。Theme 已定义完整 light/dark 色板（`Theme.swift:1-147`）,白白浪费。
- **Fix**：删除该 modifier,让系统决定。

#### 11. Dark-Mode 破坏色硬编码
- **现象**：`LoginView.swift:178/182/311/320/393`、`RecommendedPlayersSection.swift:71`、`MessagesView.swift:42` 用 `Color.white` / `Color.white.opacity(...)`。
- **Fix**：统一换 `Theme.surface` / `Theme.textPrimary`。

#### 12. 固定 `.font(.system(size:))` 45+ 处,无 Dynamic Type
- **现象**：`ChatDetailView:167/179/361/381/414`、`HomeView.swift:374`（10pt）等。视障用户和大字体偏好用户体验直接崩坏。
- **Fix**：换 Theme 提供的语义字体或 `.font(.body)/.caption/.headline`。

#### 13. 触摸目标 < 44pt
- **现象**：`RecommendedPlayersSection.swift:72` 关注按钮 `frame(width: 60, height: 24)`、`:47` 头像 36pt 无 padding。
- **Fix**：至少 `.frame(minHeight: 44)` 或 `.contentShape(Rectangle())` + padding。

#### 14. DateFormatter 每次构造
- **现象**：`ChatDetailView.swift:88`、`HomeView.swift:719-720`、`MyMatchesView.swift:1128` 等 12+ 处 `let formatter = DateFormatter()` 在方法内。
- **Fix**：抽 `enum AppDateFormatter { static let display: DateFormatter = { ... }() }` 静态缓存。

#### 15. Store 无显式 `@MainActor`
- **现象**：`BookedSlotStore.swift:26`、`UserStore.swift:15`、`FollowStore.swift:14` 等仅靠 `@Observable` 隐式隔离。
- **Fix**：`@Observable @MainActor final class XxxStore`,意图清晰。

#### 16. 残留 `DispatchQueue.main.asyncAfter`
- **现象**：`RegisterView.swift:548-555`、`PhoneInputView`、`PhoneVerificationView`、`EmailRegisterView` 用旧 GCD 模拟延迟。
- **Fix**：换 `Task { try? await Task.sleep(for: .milliseconds(800)); ... }`。

---

## 三、必须补的 5 个测试场景

```swift
// 1. 时间冲突 — 跨午夜
"23:00 - 01:00" 与 "00:30 - 02:30" 应识别为冲突
→ MatchScheduleTests.testCrossMidnightConflict()

// 2. 重复报名防抖
快速 5 次点击 SignUpConfirmSheet 的 "確認報名"
→ 期望: currentPlayers 仅 +1,signedUpMatchIDs 仅含一次

// 3. 取消失败回滚
mock cancelMatch 抛错
→ 期望: acceptedMatches 还原,creditScore 不扣,BookedSlotStore 不释放

// 4. 过期一致性
同一 MatchDetailData 在 MatchDetailView / MyMatchesView / HomeView
→ isExpired 必须返回相同值(属性化测试 / property-based test)

// 5. 跨时区 boundary
模拟 TimeZone(identifier: "Asia/Tokyo") 与 "Australia/Sydney"
解析 "04/19 23:00" 不应漂移到 04/20
→ MatchScheduleTests.testTimezoneStability()
```

---

## 四、重构 Roadmap（建议执行顺序）

```
Phase 1 — 快速修复（可优先实施）
├─ 删除 .preferredColorScheme(.light)
├─ DateFormatter 抽静态缓存
├─ SignUpConfirmSheet 加 isSubmitting + disable
├─ Stores 加 @MainActor
└─ 表单 toast 统一

Phase 2 — 核心数据流
├─ SignUpMatchInfo / MatchDetailData 引入 startDate: Date
├─ 抽 BookingStore 统一 acceptedMatches + signedUpMatchIDs + bookedSlots
├─ 取消流程加 5s 撤销
└─ 报名/取消加 try/catch 回滚

Phase 3 — 架构与性能
├─ HomeView 拆子 View,filter 抽 ViewModel
├─ 列表换 LazyVStack / List
├─ Dynamic Type — .system(size:) 全部换语义字体
└─ 引入 AsyncImage + Kingfisher / Nuke 缓存
```

---

## 五、亮点（值得保留）

- ✓ `MatchSchedule.dateRange` 跨午夜处理逻辑正确（`:123-126`）
- ✓ `MyMatchesView` toast `.task(id:)` 正确绑定生命周期
- ✓ `BookedSlotStore.conflict(excluding:)` 排除自身设计合理
- ✓ Theme 系统已搭建完整 light/dark 色板,下一步只需"启用 + 全覆盖"
- ✓ 7 个 Store 通过 environment 注入,比 EnvironmentObject 单例更优

---

## 六、核心结论

主要风险集中在两处:

1. **时间字段字符串化** — `SignUpMatchInfo.dateTime: String` 是整个系统的隐性炸弹,所有派生计算（过期、冲突、跨午夜、跨时区）都构建在易碎的正则解析之上。
2. **乐观更新无回滚** — 当前 mock 阶段看似工作正常,但接入后端那一天就会暴雷:任何网络抖动都会让 UI 与服务端永久脱钩。

**建议把 Phase 1 + Phase 2 当作"接后端前的 must-have"。**
