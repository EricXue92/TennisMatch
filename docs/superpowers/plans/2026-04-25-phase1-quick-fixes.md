# Phase 1 Quick Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地 `docs/2026-04-25-comprehensive-audit.md` Phase 1 的 5 个快速修复(Dark Mode 释放、DateFormatter 缓存、报名按钮防抖、Store @MainActor、表单 toast 统一)。

**Architecture:**
- 不引入新依赖,不改架构,只做工艺级修复。
- 新增一个 `Models/AppDateFormatter.swift` 集中缓存 DateFormatter,迁移 21 个调用点。
- 复用项目已有的 `Components/ToastModifier.swift` 替换 `CreateMatchView` 内联校验提示。

**Tech Stack:** SwiftUI / iOS 17+ / `@Observable` 宏 / 手动 + Xcode 构建验证(无测试目标)。

**Verification baseline:**
- 构建命令:`xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build`
- 运行项目并人工对照各 Task 的 "Manual verify" 清单。

**Commit style:** 每个 Task 一个 commit,前缀按已有项目风格 `fix(scope):` / `refactor(scope):`。

---

## File Structure

| 文件 | 改动 | 责任 |
|---|---|---|
| `TennisMatch/TennisMatchApp.swift` | Modify L36 | 移除强制浅色模式 |
| `TennisMatch/Models/AppDateFormatter.swift` | **Create** | 集中缓存 DateFormatter 静态实例 |
| `TennisMatch/Models/{User,FollowStore,BookedSlotStore,NotificationStore,CreditScoreStore,RatingFeedbackStore,TournamentStore}.swift` | Modify class 声明行 | 显式 `@MainActor` |
| `TennisMatch/Models/CreditScoreStore.swift` | Modify L96-100 | 用缓存 Formatter |
| `TennisMatch/Models/NotificationStore.swift` | Modify L93-99 | 用缓存 Formatter |
| `TennisMatch/Models/RatingFeedbackStore.swift` | Modify L106-110 | 用缓存 Formatter |
| `TennisMatch/Models/TournamentStore.swift` | Modify L25-27 | 用缓存 Formatter |
| `TennisMatch/Models/CalendarService.swift` | Modify L68, L126 | 用缓存 Formatter |
| `TennisMatch/Views/CreateMatchView.swift` | Modify L51-52, L309-312, L432-436, L464-496, L591-598 | 缓存 Formatter + toast 统一 |
| `TennisMatch/Views/CreateTournamentView.swift` | Modify L678 | 用缓存 Formatter |
| `TennisMatch/Views/ChatDetailView.swift` | Modify L88-90, L156, L478, L521, L583 | 用缓存 Formatter |
| `TennisMatch/Views/HomeView.swift` | Modify L719 | 用缓存 Formatter |
| `TennisMatch/Views/MyMatchesView.swift` | Modify L1128, L1156, L1678 | 用缓存 Formatter |
| `TennisMatch/Views/NotificationsView.swift` | Modify L131 | 用缓存 Formatter |
| `TennisMatch/Views/Home/MockMatchData.swift` | Modify L74 | 用缓存 Formatter |
| `TennisMatch/Views/ProfileView.swift` | Modify L78 | 用缓存 Formatter |
| `TennisMatch/Components/SignUpConfirmSheet.swift` | Modify struct + Button | 加 `isSubmitting` 防抖 |

---

## Task 1: 删除 `.preferredColorScheme(.light)`

**Why:** 全局禁用了 Dark Mode,Theme 已经定义完整 light/dark 色板(Theme.swift:1-147),恢复系统默认即可让 dark 用户立刻受益。

**Files:**
- Modify: `TennisMatch/TennisMatchApp.swift:36`

- [ ] **Step 1: 删除 `.preferredColorScheme(.light)` 修饰符**

将 `TennisMatchApp.swift:36` 这一行 `.preferredColorScheme(.light)` 删除。删除后 L35-46 应该是这样:

```swift
            }
            .environment(\.locale, localeManager.currentLocale)
            .environment(localeManager)
            .environment(followStore)
            .environment(userStore)
            .environment(bookedSlotStore)
            .environment(notificationStore)
            .environment(creditScoreStore)
            .environment(ratingFeedbackStore)
            .environment(tournamentStore)
        }
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Manual verify**

  1. 在模拟器或设备上运行 App
  2. 系统设置 → 显示与亮度 → 切到"深色"
  3. 进入 App,确认背景/文字仍然清晰可读(Theme.surface / Theme.textPrimary 应自动适配)
  4. **若发现某些 View 在深色下不可读**(预期会有,Login/Messages 等),不在此 Task 修,记入 Phase 1.5 待办,这个 Task 只验证主题切换被启用了

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/TennisMatchApp.swift
git commit -m "fix(theme): remove forced .light color scheme to enable Dark Mode"
```

---

## Task 2: 创建 `AppDateFormatter` 缓存

**Why:** 21 处 `let formatter = DateFormatter()` 散落,每帧/每次调用都重建,既慢又容易在 locale/timezone 上漂移。集中缓存。

**Files:**
- Create: `TennisMatch/Models/AppDateFormatter.swift`

- [ ] **Step 1: 创建 AppDateFormatter**

新建文件 `TennisMatch/Models/AppDateFormatter.swift`,完整内容:

```swift
//
//  AppDateFormatter.swift
//  TennisMatch
//
//  集中缓存的 DateFormatter 实例。
//
//  ⚠️ 不要在调用方 `let formatter = DateFormatter()`。
//  DateFormatter 构造昂贵 + locale/timezone 可能漂移,统一从这里取。
//
//  规则:
//  - 业务展示用格式(如 "MM/dd")—— 用 currentLocale,跟随用户系统语言
//  - 解析/序列化用格式 —— 锁 en_US_POSIX,避免阿拉伯/中文数字漂移
//

import Foundation

enum AppDateFormatter {
    /// 业务最常用 — "MM/dd" 月日,跟随当前 locale。
    static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd"
        return f
    }()

    /// "yyyy/MM/dd" 完整日期,跟随当前 locale。
    static let yearMonthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    /// "HH:mm" 24 小时时刻,跟随当前 locale。
    static let hourMinute: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// "yyyy-MM-dd HH:mm" — 用于解析/序列化,锁 POSIX 防漂移。
    static let posixDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
```

- [ ] **Step 2: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -10`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Models/AppDateFormatter.swift
git commit -m "refactor(date): add AppDateFormatter shared formatter cache"
```

---

## Task 3: 迁移 `MM/dd` 调用点到 `AppDateFormatter.monthDay`

**Why:** 大部分 site 都是 "MM/dd",一次性迁移,移除 17 个内联实例化。

**Files:**
- Modify: `TennisMatch/Models/CreditScoreStore.swift:96-100`
- Modify: `TennisMatch/Models/NotificationStore.swift:93-99`(只迁内部那个 fmt)
- Modify: `TennisMatch/Models/RatingFeedbackStore.swift:106-110`
- Modify: `TennisMatch/Views/CreateMatchView.swift:309-312, 591-594`
- Modify: `TennisMatch/Views/MyMatchesView.swift:1128, 1156, 1678`(若是 MM/dd)
- Modify: `TennisMatch/Views/NotificationsView.swift:131`
- Modify: `TennisMatch/Views/Home/MockMatchData.swift:74`
- Modify: `TennisMatch/Views/ProfileView.swift:78`

> **执行注意:** 每个 site 替换前先 `Read` 上下文 5 行,确认 `dateFormat` 是 `"MM/dd"` 才替换。如果格式不是 MM/dd,跳过留给后续 Task。

- [ ] **Step 1: 替换 `CreditScoreStore.swift:96-100`**

Original:
```swift
    private static var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: .now)
    }
```

Replace with:
```swift
    private static var todayLabel: String {
        AppDateFormatter.monthDay.string(from: .now)
    }
```

- [ ] **Step 2: 替换 `RatingFeedbackStore.swift:106-110`**

Original:
```swift
    private static var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: .now)
    }
```

Replace with:
```swift
    private static var todayLabel: String {
        AppDateFormatter.monthDay.string(from: .now)
    }
```

- [ ] **Step 3: 替换 `NotificationStore.swift:94-95`**

Original (in `mockSeed` static let):
```swift
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd"
        func d(_ offset: Int) -> String {
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { return "01/01" }
            return fmt.string(from: date)
        }
```

Replace with:
```swift
        func d(_ offset: Int) -> String {
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { return "01/01" }
            return AppDateFormatter.monthDay.string(from: date)
        }
```

- [ ] **Step 4: 替换 `CreateMatchView.swift:307-312` `dateFormatted`**

Original:
```swift
    private var dateFormatted: String {
        if !dateWasEdited { return "選擇日期" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: selectedDate)
    }
```

Replace with:
```swift
    private var dateFormatted: String {
        if !dateWasEdited { return "選擇日期" }
        return AppDateFormatter.monthDay.string(from: selectedDate)
    }
```

- [ ] **Step 5: 替换 `CreateMatchView.swift:591-598` `confirmDateText`**

Original:
```swift
    private var confirmDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let dateStr = dateWasEdited ? formatter.string(from: selectedDate) : "未選擇"
        let startStr = startTimeEdited ? selectedStartTime : "--:--"
        let endStr = endTimeEdited ? selectedEndTime : "--:--"
        return "\(dateStr)  \(startStr) ~ \(endStr)"
    }
```

Replace with:
```swift
    private var confirmDateText: String {
        let dateStr = dateWasEdited
            ? AppDateFormatter.monthDay.string(from: selectedDate)
            : "未選擇"
        let startStr = startTimeEdited ? selectedStartTime : "--:--"
        let endStr = endTimeEdited ? selectedEndTime : "--:--"
        return "\(dateStr)  \(startStr) ~ \(endStr)"
    }
```

- [ ] **Step 6: 替换其余 site (MyMatches / Notifications / MockMatchData / Profile)**

  对每个 site:
  1. 用 `Read` 读取该行附近 ±5 行
  2. 确认是 `let f/formatter = DateFormatter(); f.dateFormat = "MM/dd"; return f.string(from: ...)` 模式
  3. 用 `AppDateFormatter.monthDay.string(from: ...)` 替换整段
  4. 若上下文有 `Locale(identifier:)` 或 `TimeZone` 设置,**不要替换**,跳过留给 Task 4

  具体 site:
  - `Views/MyMatchesView.swift:1128` (上下 10 行)
  - `Views/MyMatchesView.swift:1156`
  - `Views/MyMatchesView.swift:1678`
  - `Views/NotificationsView.swift:131`
  - `Views/Home/MockMatchData.swift:74`
  - `Views/ProfileView.swift:78`

- [ ] **Step 7: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -10`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: 跑 ripgrep 检查残留**

Run: `grep -rn "DateFormatter()" TennisMatch/Models TennisMatch/Views | grep -v "AppDateFormatter"`
Expected: 仅剩 yyyy/MM/dd、HH:mm、或带 Locale 的 site(留给 Task 4 处理)。

- [ ] **Step 9: Commit**

```bash
git add -u
git commit -m "refactor(date): migrate MM/dd sites to AppDateFormatter.monthDay"
```

---

## Task 4: 迁移 `yyyy/MM/dd` 与其他格式 site

**Why:** 把剩下的 yyyy/MM/dd 也归到缓存。带特殊 Locale/TimeZone 的(如 CalendarService)谨慎处理。

**Files:**
- Modify: `TennisMatch/Models/TournamentStore.swift:25-27`
- Modify: `TennisMatch/Views/ChatDetailView.swift:88-90`
- Modify: `TennisMatch/Views/CreateTournamentView.swift:678`
- Modify: `TennisMatch/Views/HomeView.swift:719`
- Modify: `TennisMatch/Views/ChatDetailView.swift:156, 478, 521, 583`(逐个看格式)

- [ ] **Step 1: 替换 `TournamentStore.swift:25-27`**

Original:
```swift
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateRange = "\(formatter.string(from: info.startDate)) - \(formatter.string(from: info.endDate))"
```

Replace with:
```swift
        let f = AppDateFormatter.yearMonthDay
        let dateRange = "\(f.string(from: info.startDate)) - \(f.string(from: info.endDate))"
```

- [ ] **Step 2: 替换 `ChatDetailView.swift:87-91` `dateSeparatorLabel`**

Original:
```swift
    private func dateSeparatorLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return "今天 — \(formatter.string(from: Date()))"
    }
```

Replace with:
```swift
    private func dateSeparatorLabel() -> String {
        "今天 — \(AppDateFormatter.yearMonthDay.string(from: Date()))"
    }
```

- [ ] **Step 3: 处理 `ChatDetailView.swift` 余下 4 处 (L156, L478, L521, L583)**

  对每处:
  1. `Read` 上下 8 行
  2. 看 `dateFormat`,匹配:
     - `"MM/dd"` → `AppDateFormatter.monthDay`
     - `"yyyy/MM/dd"` → `AppDateFormatter.yearMonthDay`
     - `"HH:mm"` → `AppDateFormatter.hourMinute`
     - 其他特殊格式 → **保留原样**,在文件顶端注释 `// TODO(Phase1.5): 迁移到 AppDateFormatter`

- [ ] **Step 4: 处理 `HomeView.swift:719`、`CreateTournamentView.swift:678`**

  同上策略,Read → 匹配 → 替换或保留 TODO。

- [ ] **Step 5: 处理 `CalendarService.swift:68, 126`**

  这两个 site 上下文有 `Locale(identifier: "en_US_POSIX")`(根据先前扫描结果),用于 ICS 文件序列化。**不要直接换缓存**:
  1. `Read` 看完整格式
  2. 若是 `"yyyy-MM-dd HH:mm"` POSIX,换 `AppDateFormatter.posixDateTime`
  3. 若是 ICS 专用如 `"yyyyMMdd'T'HHmmss"`,**保留原样**(ICS 文件唯一调用点,不重复)

- [ ] **Step 6: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -10`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Manual verify**

  1. 跑 App
  2. 进 Notifications / MyMatches / Profile / 创建赛事 等页面
  3. 确认所有日期标签显示正常(没出现 "1970" 或空白)

- [ ] **Step 8: Commit**

```bash
git add -u
git commit -m "refactor(date): migrate remaining DateFormatter sites to AppDateFormatter"
```

---

## Task 5: Stores 加 `@MainActor`

**Why:** 7 个 `@Observable` Store 都期望从主线程访问,但目前是隐式假设。显式标记 `@MainActor` 让编译器在未来误用 `Task.detached` 时报错,而不是 runtime crash。

**Files:**
- Modify: `TennisMatch/Models/UserStore.swift:15-16`
- Modify: `TennisMatch/Models/FollowStore.swift:14-15`
- Modify: `TennisMatch/Models/BookedSlotStore.swift:26-27`
- Modify: `TennisMatch/Models/NotificationStore.swift:63-64`
- Modify: `TennisMatch/Models/CreditScoreStore.swift:30-31`
- Modify: `TennisMatch/Models/RatingFeedbackStore.swift:52-53`
- Modify: `TennisMatch/Models/TournamentStore.swift:11-12`

- [ ] **Step 1: UserStore**

Change line 15-16 from:
```swift
@Observable
final class UserStore {
```
To:
```swift
@Observable
@MainActor
final class UserStore {
```

- [ ] **Step 2: FollowStore**

Change line 14-15 from:
```swift
@Observable
final class FollowStore {
```
To:
```swift
@Observable
@MainActor
final class FollowStore {
```

- [ ] **Step 3: BookedSlotStore**

Change line 26-27 from:
```swift
@Observable
final class BookedSlotStore {
```
To:
```swift
@Observable
@MainActor
final class BookedSlotStore {
```

- [ ] **Step 4: NotificationStore**

Change line 63-64 from:
```swift
@Observable
final class NotificationStore {
```
To:
```swift
@Observable
@MainActor
final class NotificationStore {
```

- [ ] **Step 5: CreditScoreStore**

Change line 30-31 from:
```swift
@Observable
final class CreditScoreStore {
```
To:
```swift
@Observable
@MainActor
final class CreditScoreStore {
```

- [ ] **Step 6: RatingFeedbackStore**

Change line 52-53 from:
```swift
@Observable
final class RatingFeedbackStore {
```
To:
```swift
@Observable
@MainActor
final class RatingFeedbackStore {
```

- [ ] **Step 7: TournamentStore**

Change line 11-12 from:
```swift
@Observable
final class TournamentStore {
```
To:
```swift
@Observable
@MainActor
final class TournamentStore {
```

- [ ] **Step 8: 构建验证 — 预期会有编译错误**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -40`

Expected: 可能出现错误 `Call to main actor-isolated initializer 'init' in a synchronous nonisolated context` —— 来自 `TennisMatchApp.swift:14-20` 的 `@State private var followStore = FollowStore()` 等。

如果出现该错误:`@main struct TennisMatchApp` 默认是 `@MainActor` (App protocol 要求),理论上初始化应该 OK。如果仍报错,说明编译器认为 property initialization 在 `nonisolated` 上下文。修复方式:把 store 改为 `lazy` 或在 init 里赋值:

```swift
@main
struct TennisMatchApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var localeManager = LocaleManager.shared
    @State private var followStore: FollowStore
    @State private var userStore: UserStore
    // ... 其他 store 同样

    init() {
        _followStore = State(initialValue: FollowStore())
        _userStore = State(initialValue: UserStore())
        // ...
    }
}
```

但优先尝试不动:Swift 6 之前,`App` 的 property initialization 通常在 main actor 上,可能能直接编译通过。

- [ ] **Step 9: 修复其他编译错误**

如果错误来自:
- **Store 内部的 `static let mockSeed = ...` 引用 `Calendar.current` 等**:这些都是 main-actor-safe 的,通常没问题
- **某个 closure 调用 store 方法但没标 `@MainActor`**:把 closure 加 `@MainActor` 或包 `Task { @MainActor in ... }`
- **静态属性如 `mockSeed`**:可能要标 `nonisolated(unsafe)` 或拆出来

每个错误读编译器给的精确建议,选最小侵入的修复。如果某个 Store 加 `@MainActor` 引发超过 5 处级联修改,**回退该 Store 的 `@MainActor`**,在文件顶端加注释 `// TODO(Phase1.5): @MainActor 暂缓 — 触发级联修改` 跳过。

- [ ] **Step 10: 全量构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -10`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 11: Manual verify**

跑一次 App,验证启动 → 登录 → 浏览首页 → 进入"我的约球"无 crash 或空数据。

- [ ] **Step 12: Commit**

```bash
git add -u
git commit -m "refactor(stores): make Stores explicitly @MainActor"
```

---

## Task 6: SignUpConfirmSheet 添加 `isSubmitting` 防抖

**Why:** P0-3 报名按钮无防抖,快速双击可让 `currentPlayers += 2`。这是 mock 阶段就能复现的问题(`UINotificationFeedbackGenerator` 触发后 `dismiss()` + `onConfirm()` 不是原子的)。

**Files:**
- Modify: `TennisMatch/Components/SignUpConfirmSheet.swift:10, 50-62`

- [ ] **Step 1: 加 `isSubmitting` state 与 disable 逻辑**

替换 `Components/SignUpConfirmSheet.swift` 整个文件内容为:

```swift
import SwiftUI

// MARK: - Sign Up Confirmation

struct SignUpConfirmSheet: View {
    let match: SignUpMatchInfo
    var showNotes: Bool = true
    var onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var isSubmitting = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("確認報名")
                .font(Typography.largeStat)
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                infoRow(icon: "calendar", text: match.dateTime)
                infoRow(icon: "mappin.circle.fill", text: match.location)
                infoRow(icon: "figure.tennis", text: "\(match.matchType)  ·  NTRP \(match.ntrpRange)")
                infoRow(icon: "dollarsign.circle.fill", text: match.fee)
                if showNotes {
                    infoRow(icon: "exclamationmark.triangle.fill", text: match.notes)
                }
            }

            Theme.divider.frame(height: 1)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("給發起人留言（選填）")
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)

                TextField("例如：我會準時到！", text: $message, axis: .vertical)
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(3...5)
                    .padding(Spacing.sm)
                    .background(Theme.inputBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
                    .disabled(isSubmitting)
            }

            Spacer()

            Button {
                guard !isSubmitting else { return }
                isSubmitting = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                let messageSnapshot = message
                // dismiss + onConfirm 必须在同一帧,但 isSubmitting 已经把按钮 disable
                dismiss()
                onConfirm(messageSnapshot)
            } label: {
                ZStack {
                    Text("確認報名")
                        .font(Typography.button)
                        .foregroundColor(.white)
                        .opacity(isSubmitting ? 0 : 1)

                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSubmitting ? Theme.primary.opacity(0.6) : Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isSubmitting)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.bodyMedium)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textPrimary)
        }
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -10`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Manual verify — 防抖**

  1. 跑 App,进入任意约球详情
  2. 点 "報名" → 弹出 SignUpConfirmSheet
  3. **快速连续点击 "確認報名" 5 次**
  4. **预期**: 按钮第一次点击后立即变灰显示 ProgressView,后续点击无反应
  5. 进入"我的约球",确认 `currentPlayers` 只 +1(不是 +5)

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Components/SignUpConfirmSheet.swift
git commit -m "fix(signup): add isSubmitting flag to prevent double-tap on confirm"
```

---

## Task 7: 统一 `CreateMatchView` 校验 toast

**Why:** P1-8: 当前 `validationMessage` 仅在 `showCostError` 为 true 时显示在 cost section 的下方(`L432-436`)。日期/时间/球场失败时,toast 出现在表单底部,用户根本看不到。改用项目已有的 `ToastModifier` 顶部 toast。

**Files:**
- Modify: `TennisMatch/Views/CreateMatchView.swift:51-52, 432-436, 464-496`

- [ ] **Step 1: 改 state 声明**

把 `Views/CreateMatchView.swift:51-52`:
```swift
    @State private var showCostError = false
    @State private var validationMessage = ""
```

替换为:
```swift
    @State private var validationToast: String?
```

- [ ] **Step 2: 删除 cost section 的内联错误显示**

把 `Views/CreateMatchView.swift:432-436`:
```swift
            if showCostError && !validationMessage.isEmpty {
                Text(validationMessage)
                    .font(Typography.small)
                    .foregroundColor(Theme.requiredText)
            }
```

整段删除(包含外层的 `if` 闭合)。

- [ ] **Step 3: 改 submitButton 的校验逻辑**

把 `Views/CreateMatchView.swift:464-496`(`submitButton`):
```swift
    private var submitButton: some View {
        Button {
            // 必填項校驗
            if !dateWasEdited {
                validationMessage = "請選擇日期"
                showCostError = true
                return
            } else if !startTimeEdited || !endTimeEdited {
                validationMessage = "請選擇開始和結束時間"
                showCostError = true
                return
            } else if selectedCourt == nil {
                validationMessage = "請選擇球場"
                showCostError = true
                return
            } else if costType == "AA制" && (costAmount.isEmpty || Int(costAmount) ?? 0 <= 0) {
                validationMessage = "請輸入有效的費用金額"
                showCostError = true
                return
            }
            validationMessage = ""
            showCostError = false
            showConfirmation = true
        } label: {
            Text("發布約球")
                .font(Typography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
```

替换为:
```swift
    private var submitButton: some View {
        Button {
            // 必填項校驗 — 失败统一通过顶部 toast 反饋
            if !dateWasEdited {
                validationToast = "請選擇日期"
                return
            } else if !startTimeEdited || !endTimeEdited {
                validationToast = "請選擇開始和結束時間"
                return
            } else if selectedCourt == nil {
                validationToast = "請選擇球場"
                return
            } else if costType == "AA制" && (costAmount.isEmpty || Int(costAmount) ?? 0 <= 0) {
                validationToast = "請輸入有效的費用金額"
                return
            }
            showConfirmation = true
        } label: {
            Text("發布約球")
                .font(Typography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
```

- [ ] **Step 4: 在 body 末端挂 `.toast()` 修饰器**

找到 `Views/CreateMatchView.swift` 的 `body` 闭合位置(第一个 `VStack` 后跟 `.background(Theme.background)` 那块,大约在 L77 附近)。

在 `.background(Theme.background)` 后追加 `.toast($validationToast, icon: "exclamationmark.circle.fill")`。

例如:
```swift
        .background(Theme.background)
        .navigationBarHidden(true)
```

改为:
```swift
        .background(Theme.background)
        .toast($validationToast, icon: "exclamationmark.circle.fill")
        .navigationBarHidden(true)
```

- [ ] **Step 5: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -10`
Expected: `** BUILD SUCCEEDED **`

  若编译报 "cannot find 'showCostError' / 'validationMessage' in scope":说明 grep 漏掉了某处引用。Run `grep -n "showCostError\|validationMessage" TennisMatch/Views/CreateMatchView.swift` 找到剩余引用,删掉或迁到 `validationToast`。

- [ ] **Step 6: Manual verify**

  1. 跑 App,从首页 → "發起約球" 进 CreateMatchView
  2. **不填任何字段**,直接点 "發布約球"
  3. **预期**: 顶部出现 toast "請選擇日期",约 2 秒后消失
  4. 选好日期再点提交 → toast "請選擇開始和結束時間"
  5. 选时间不选球场 → toast "請選擇球場"
  6. 选 AA 制但金额留空 → toast "請輸入有效的費用金額"
  7. 全部填完 → 进入确认 sheet,无 toast

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/CreateMatchView.swift
git commit -m "fix(create-match): unify form validation feedback via top toast"
```

---

## Task 8: Phase 1 收尾验证

- [ ] **Step 1: 全量 grep 残留 `DateFormatter()`**

Run: `grep -rn "DateFormatter()" TennisMatch/ | grep -v "AppDateFormatter"`
预期:仅剩带特殊 Locale/TimeZone 的 site(已加 `// TODO(Phase1.5)` 注释)。

- [ ] **Step 2: 全量 grep 残留 `preferredColorScheme(.light)`**

Run: `grep -rn "preferredColorScheme" TennisMatch/`
预期:不再有 `.light` 强制。

- [ ] **Step 3: 全量 grep `@Observable` 后的 `final class` 是否都跟 `@MainActor`**

Run: `grep -B1 "final class.*Store" TennisMatch/Models/`
预期:每个 Store 上方都是 `@Observable\n@MainActor`(或有 TODO 跳过的注释)。

- [ ] **Step 4: 跑一次完整 smoke test**

  - 启动 → 登录 → 首页
  - 点击任意约球 → 报名(快速连击 5 次)→ 确认只 +1
  - 创建约球 → 不填字段提交 → toast 显示
  - 切换系统深色模式 → App 主题切换
  - 我的约球 / 通知 / 个人页面 → 日期标签正常

- [ ] **Step 5: 更新审计文档进度**

在 `docs/2026-04-25-comprehensive-audit.md` 文末追加 Phase 1 完成记录:

```markdown
---

## Phase 1 完成记录(2026-04-25)

✅ Task 1: 删除 .preferredColorScheme(.light) → Dark Mode 已启用
✅ Task 2-4: 21 处 DateFormatter 迁到 AppDateFormatter 缓存(N 处保留 TODO 待 Phase 1.5)
✅ Task 5: 7 个 Store 加 @MainActor
✅ Task 6: SignUpConfirmSheet 加 isSubmitting 防抖
✅ Task 7: CreateMatchView 校验 toast 统一

下阶段:Phase 2 — 数据流核心(BookingStore / startDate: Date / 取消撤销 / 报名回滚)
```

- [ ] **Step 6: Commit 收尾**

```bash
git add docs/2026-04-25-comprehensive-audit.md
git commit -m "docs: mark Phase 1 quick fixes complete"
```

---

## Self-Review Checklist

- ✅ Spec coverage: Phase 1 五条修复全部映射到 Task 1/3-4/5/6/7
- ✅ Placeholder scan: 没有 "TBD" / "implement later",每步都有完整代码或精确替换块
- ✅ Type consistency: `validationToast: String?` 在 Task 7 中前后引用一致;`AppDateFormatter` 静态属性名 (monthDay/yearMonthDay/hourMinute/posixDateTime) 在 Task 3-4 引用一致
- ✅ Each task = one commit,粒度 5-15 分钟可完成
- ⚠️ 风险点: Task 5 (`@MainActor`) 可能引发级联编译错误,Step 9 已给出回退策略
