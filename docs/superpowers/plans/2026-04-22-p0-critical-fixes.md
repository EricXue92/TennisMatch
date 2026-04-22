# P0 Critical Fixes — UI/UX Audit Phase 1

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all 8 P0 (critical) issues identified in `docs/ui-ux-audit.md` — these are the highest-severity bugs and architecture problems that must be resolved before moving to P1/P2 fixes.

**Architecture:** Fixes are ordered to avoid conflicts — shared models/components first (Tasks 1-2), then module-specific fixes (Tasks 3-7). Task 8 (HomeView refactor) is last because it's the largest change and other fixes may touch HomeView.

**Tech Stack:** Swift / SwiftUI / iOS 17+ / `@Observable` pattern

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `TennisMatch/Components/FlowLayout.swift` | Shared FlowLayout component (extracted from RegisterView + PublicProfileView) |
| Create | `TennisMatch/Models/PlayerModels.swift` | Unified `FollowPlayer` model (replaces FollowedPlayer / FollowerPlayer / MutualPlayer) |
| Modify | `TennisMatch/Views/RegisterView.swift` | Remove FlowLayout, remove force unwraps, use shared model |
| Modify | `TennisMatch/Views/PublicProfileView.swift` | Remove FlowLayoutPublic, use shared FlowLayout |
| Modify | `TennisMatch/Views/FollowingView.swift` | Replace FollowedPlayer with shared FollowPlayer |
| Modify | `TennisMatch/Views/FollowerListView.swift` | Replace FollowerPlayer with shared FollowPlayer |
| Modify | `TennisMatch/Views/MutualFollowListView.swift` | Replace MutualPlayer with shared FollowPlayer |
| Modify | `TennisMatch/Views/PhoneVerificationView.swift` | Add OTP length validation |
| Modify | `TennisMatch/Views/CreateMatchView.swift` | Add required field validation + "拉球" match type |
| Modify | `TennisMatch/Views/HomeView.swift` | Fix hardcoded stats, add "拉球" to filter |

---

### Task 1: Extract shared FlowLayout component

**Files:**
- Create: `TennisMatch/Components/FlowLayout.swift`
- Modify: `TennisMatch/Views/RegisterView.swift:554-592`
- Modify: `TennisMatch/Views/PublicProfileView.swift:331-360`

**Why:** `FlowLayout` (RegisterView) and `FlowLayoutPublic` (PublicProfileView) are identical Layout implementations. This is audit item **Module 5 P0 — FlowLayout 重复实现**.

- [ ] **Step 1: Create shared FlowLayout component**

Create `TennisMatch/Components/FlowLayout.swift`:

```swift
//
//  FlowLayout.swift
//  TennisMatch
//
//  可複用的流式佈局 — 自動換行排列子視圖
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
```

- [ ] **Step 2: Remove FlowLayout from RegisterView**

In `RegisterView.swift`, delete the entire `private struct FlowLayout: Layout` block (lines 556-592). Since the new `FlowLayout` in Components/ has the same name and is now internal (not `private`), all existing `FlowLayout(spacing:)` call sites in RegisterView will resolve automatically.

- [ ] **Step 3: Remove FlowLayoutPublic from PublicProfileView**

In `PublicProfileView.swift`, delete the entire `private struct FlowLayoutPublic: Layout` block (lines 331-360). Then find and replace all uses of `FlowLayoutPublic` with `FlowLayout` in that file.

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Components/FlowLayout.swift TennisMatch/Views/RegisterView.swift TennisMatch/Views/PublicProfileView.swift
git commit -m "refactor: extract shared FlowLayout component from RegisterView and PublicProfileView"
```

---

### Task 2: Unify duplicate Player data models

**Files:**
- Create: `TennisMatch/Models/PlayerModels.swift`
- Modify: `TennisMatch/Views/FollowingView.swift:150-171`
- Modify: `TennisMatch/Views/FollowerListView.swift:134-162`
- Modify: `TennisMatch/Views/MutualFollowListView.swift:151-173`

**Why:** `FollowedPlayer`, `FollowerPlayer`, `MutualPlayer` are identical structs (name, gender, ntrp, latestActivity) defined privately in 3 files with 3 copies of mock data. This is audit item **Module 5 P0 — 三套重复的 Player 数据模型**.

- [ ] **Step 1: Create shared FollowPlayer model**

Create `TennisMatch/Models/PlayerModels.swift`:

```swift
//
//  PlayerModels.swift
//  TennisMatch
//
//  統一的球友資料模型 — 取代之前分散在 FollowingView / FollowerListView / MutualFollowListView 的三份重複定義
//

import Foundation

struct FollowPlayer: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let ntrp: String
    let latestActivity: String
}

// MARK: - Mock Data

/// 12 位互相關注的球友 — FollowingView / MutualFollowListView 共用。
/// 與 FollowStore.seedFollowing 對齊。
let mockMutualFollowPlayers: [FollowPlayer] = [
    FollowPlayer(name: "莎莎", gender: .female, ntrp: "3.5", latestActivity: "剛發布了一場單打約球"),
    FollowPlayer(name: "王強", gender: .male, ntrp: "4.0", latestActivity: "報名了春季公開賽"),
    FollowPlayer(name: "小美", gender: .female, ntrp: "3.0", latestActivity: "3 天前活躍"),
    FollowPlayer(name: "志明", gender: .male, ntrp: "4.5", latestActivity: "1 週前活躍"),
    FollowPlayer(name: "大衛", gender: .male, ntrp: "4.0", latestActivity: "剛完成了一場雙打"),
    FollowPlayer(name: "嘉欣", gender: .female, ntrp: "3.5", latestActivity: "發布了九龍區雙打約球"),
    FollowPlayer(name: "陳教練", gender: .male, ntrp: "5.5", latestActivity: "分享了一篇訓練心得"),
    FollowPlayer(name: "艾美", gender: .female, ntrp: "3.0", latestActivity: "報名了階梯挑戰賽"),
    FollowPlayer(name: "Michael", gender: .male, ntrp: "5.0", latestActivity: "2 天前活躍"),
    FollowPlayer(name: "思慧", gender: .female, ntrp: "4.0", latestActivity: "獲得了「守時達人」成就"),
    FollowPlayer(name: "俊傑", gender: .male, ntrp: "4.0", latestActivity: "5 天前活躍"),
    FollowPlayer(name: "曉彤", gender: .female, ntrp: "2.5", latestActivity: "剛加入了平台"),
]

/// 額外 6 位單向粉絲 — 僅 FollowerListView 使用。
let mockFollowerOnlyPlayers: [FollowPlayer] = [
    FollowPlayer(name: "阿豪", gender: .male, ntrp: "3.5", latestActivity: "報名了雙打約球"),
    FollowPlayer(name: "麗莎", gender: .female, ntrp: "3.0", latestActivity: "1 天前活躍"),
    FollowPlayer(name: "張偉", gender: .male, ntrp: "4.5", latestActivity: "3 天前活躍"),
    FollowPlayer(name: "小琳", gender: .female, ntrp: "3.0", latestActivity: "剛發布了一場約球"),
    FollowPlayer(name: "阿杰", gender: .male, ntrp: "3.5", latestActivity: "報名了九龍區友誼賽"),
    FollowPlayer(name: "雅婷", gender: .female, ntrp: "4.0", latestActivity: "2 天前活躍"),
]

/// 完整粉絲列表 = 互關 + 單向粉絲
let mockAllFollowers: [FollowPlayer] = mockMutualFollowPlayers + mockFollowerOnlyPlayers
```

- [ ] **Step 2: Update FollowingView to use shared model**

In `FollowingView.swift`:

1. Delete the entire `private struct FollowedPlayer` block (lines 150-156)
2. Delete the entire `private let mockFollowedPlayers` array (lines 158-171)
3. Replace all occurrences of `FollowedPlayer` with `FollowPlayer`
4. Replace `mockFollowedPlayers` with `mockMutualFollowPlayers`

The `followedPlayers` computed property becomes:
```swift
private var followedPlayers: [FollowPlayer] {
    mockMutualFollowPlayers.filter { followStore.isFollowing($0.name) }
}
```

And `playerToUnfollow` type changes:
```swift
@State private var playerToUnfollow: FollowPlayer?
```

- [ ] **Step 3: Update FollowerListView to use shared model**

In `FollowerListView.swift`:

1. Delete the entire `private struct FollowerPlayer` block (lines 134-140)
2. Delete the entire `private let mockFollowers` array (lines 143-162)
3. Replace all occurrences of `FollowerPlayer` with `FollowPlayer`
4. Replace `mockFollowers` with `mockAllFollowers`

- [ ] **Step 4: Update MutualFollowListView to use shared model**

In `MutualFollowListView.swift`:

1. Delete the entire `private struct MutualPlayer` block (lines 151-157)
2. Delete the entire `private let mockMutualPlayers` array (lines 160-173)
3. Replace all occurrences of `MutualPlayer` with `FollowPlayer`
4. Replace `mockMutualPlayers` with `mockMutualFollowPlayers`

The `activeMutuals` computed property becomes:
```swift
private var activeMutuals: [FollowPlayer] {
    mockMutualFollowPlayers.filter { followStore.isFollowing($0.name) }
}
```

And `playerToUnfollow` type changes:
```swift
@State private var playerToUnfollow: FollowPlayer?
```

- [ ] **Step 5: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Models/PlayerModels.swift TennisMatch/Views/FollowingView.swift TennisMatch/Views/FollowerListView.swift TennisMatch/Views/MutualFollowListView.swift
git commit -m "refactor: unify FollowedPlayer/FollowerPlayer/MutualPlayer into shared FollowPlayer model"
```

---

### Task 3: Fix OTP verification bypass

**Files:**
- Modify: `TennisMatch/Views/PhoneVerificationView.swift:189-201`

**Why:** The "驗證並登入" button navigates to RegisterView regardless of OTP input — even empty input is accepted. This is audit item **Module 1 P0 — OTP 验证形同虚设**.

- [ ] **Step 1: Add OTP length validation and disable button when incomplete**

In `PhoneVerificationView.swift`, replace the `actionSection` computed property (lines 189-219):

Old code (lines 191-192):
```swift
            Button {
                showRegister = true
```

New code:
```swift
            Button {
                guard code.count == codeLength else { return }
                showRegister = true
```

Also update the button background to reflect disabled state. Old (line 199):
```swift
                    .background(Theme.primary)
```

New:
```swift
                    .background(code.count == codeLength ? Theme.primary : Theme.chipUnselectedBg)
```

And disable the button. After the `.clipShape(...)` on line 200, add:
```swift
            .disabled(code.count != codeLength)
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/PhoneVerificationView.swift
git commit -m "fix: validate OTP code length before allowing navigation to registration"
```

---

### Task 4: Fix force unwraps in RegisterView

**Files:**
- Modify: `TennisMatch/Views/RegisterView.swift:530-534`

**Why:** `selectedGender!` and `ntrpValue!` violate the project's CLAUDE.md rule "禁止 `!` 强解包". This is audit item **Module 1 P0 — 违反 CLAUDE.md 禁止强解包规则**.

- [ ] **Step 1: Replace force unwraps with safe binding**

In `RegisterView.swift`, replace lines 530-533:

Old:
```swift
                    // 保存到 UserStore
                    userStore.displayName = name.trimmingCharacters(in: .whitespaces)
                    userStore.gender = selectedGender!
                    userStore.ntrpLevel = ntrpValue!
```

New:
```swift
                    // 保存到 UserStore
                    guard let gender = selectedGender, let ntrp = ntrpValue else { return }
                    userStore.displayName = name.trimmingCharacters(in: .whitespaces)
                    userStore.gender = gender
                    userStore.ntrpLevel = ntrp
```

- [ ] **Step 2: Also auto-dismiss validation error when user corrects input**

The audit also notes (`RegisterView.swift:540`) that `showValidationError` never resets. Add a reset at the top of the button action, before the guard chain. Find the button action block and add at line 514 (or wherever the button action starts, just before the first `if name.trimmingCharacters...`):

```swift
                showValidationError = false
                validationMessage = ""
```

This ensures the error state clears each time the user taps "完成設定", so after correcting the issue the red banner disappears.

- [ ] **Step 3: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/RegisterView.swift
git commit -m "fix: replace force unwraps with safe guard-let in RegisterView, auto-clear validation errors"
```

---

### Task 5: Add required field validation to CreateMatchView

**Files:**
- Modify: `TennisMatch/Views/CreateMatchView.swift:547-554`

**Why:** The publish button only validates cost amount — date, time, and court can all be empty. This is audit item **Module 3 P0 — 发布约球无必填项校验**.

- [ ] **Step 1: Add comprehensive field validation**

In `CreateMatchView.swift`, add a new `@State` for validation message near line 50:
```swift
    @State private var showCostError = false
```

Find `showCostError` — it's already declared. Add a validation message state if not present:
```swift
    @State private var validationMessage = ""
```

Replace the submit button action (lines 548-554):

Old:
```swift
        Button {
            if costType == "AA制" && (costAmount.isEmpty || Int(costAmount) ?? 0 <= 0) {
                showCostError = true
                return
            }
            showCostError = false
            showConfirmation = true
```

New:
```swift
        Button {
            // 必填項校驗
            if selectedCourt == nil {
                validationMessage = "請選擇球場"
            } else if costType == "AA制" && (costAmount.isEmpty || Int(costAmount) ?? 0 <= 0) {
                validationMessage = "請輸入有效的費用金額"
            } else {
                validationMessage = ""
                showConfirmation = true
                return
            }
            showCostError = true
```

Note: `selectedDate` has a default of `Date()` so it's always set. `selectedStartTime`/`selectedEndTime` have defaults "09:00"/"10:00". The only truly "nullable" required field is `selectedCourt` (which is `TennisCourt?`).

- [ ] **Step 2: Display validation message in the UI**

Find the `showCostError` usage in the view body. The current cost error display needs to be generalized. Look for any existing error display using `showCostError` and replace the hardcoded cost error message with `validationMessage`:

If there's an existing error display like:
```swift
if showCostError {
    Text("請輸入有效的費用金額")
```

Replace with:
```swift
if showCostError && !validationMessage.isEmpty {
    Text(validationMessage)
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/CreateMatchView.swift
git commit -m "fix: add required field validation (court) to CreateMatchView publish action"
```

---

### Task 6: Add "拉球" match type to CreateMatchView and HomeView filter

**Files:**
- Modify: `TennisMatch/Views/CreateMatchView.swift:156-163`
- Modify: `TennisMatch/Views/HomeView.swift:1404`

**Why:** `MatchType` enum defines `.rally` ("拉球") but it's missing from both the create-match type selector and the home filter chips. This is audit item **Module 3 P0 — 缺少"拉球"比赛类型** and **Module 2 P1 — "拉球"类型缺失于筛选器** (promoting the filter fix here since the type fix is incomplete without it).

- [ ] **Step 1: Add "拉球" radio button to CreateMatchView**

In `CreateMatchView.swift`, find the `matchTypeSection` (lines 156-163):

Old:
```swift
            HStack(spacing: Spacing.lg) {
                radioButton(label: "單打", isSelected: matchType == "單打") {
                    matchType = "單打"
                }
                radioButton(label: "雙打", isSelected: matchType == "雙打") {
                    matchType = "雙打"
                }
            }
```

New:
```swift
            HStack(spacing: Spacing.lg) {
                radioButton(label: "單打", isSelected: matchType == "單打") {
                    matchType = "單打"
                }
                radioButton(label: "雙打", isSelected: matchType == "雙打") {
                    matchType = "雙打"
                }
                radioButton(label: "拉球", isSelected: matchType == "拉球") {
                    matchType = "拉球"
                }
            }
```

- [ ] **Step 2: Add "拉球" to HomeView filter options**

In `HomeView.swift`, find line 1404:

Old:
```swift
private let matchFilterOptions = ["全部", "單打", "雙打"]
```

New:
```swift
private let matchFilterOptions = ["全部", "單打", "雙打", "拉球"]
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/CreateMatchView.swift TennisMatch/Views/HomeView.swift
git commit -m "feat: add '拉球' match type to create-match and home filter options"
```

---

### Task 7: Fix hardcoded stats in HomeView header

**Files:**
- Modify: `TennisMatch/Views/HomeView.swift:476-479`

**Why:** "場次" is hardcoded as "28" and "NTRP" as "3.5" — they should read from UserStore. This is audit item **Module 2 P0 — 统计数据硬编码，与 UserStore 脱节**.

- [ ] **Step 1: Replace hardcoded stats with UserStore values**

In `HomeView.swift`, find lines 476-479:

Old:
```swift
                HStack(spacing: Spacing.xs) {
                    statCard(label: "信譽積分", value: "\(creditScoreStore.score)")
                    statCard(label: "場次", value: "28")
                    statCard(label: "NTRP", value: "3.5")
                }
```

New:
```swift
                HStack(spacing: Spacing.xs) {
                    statCard(label: "信譽積分", value: "\(creditScoreStore.score)")
                    statCard(label: "場次", value: "\(signedUpMatchIDs.count)")
                    statCard(label: "NTRP", value: userStore.ntrpText)
                }
```

Note: `signedUpMatchIDs.count` is a reasonable proxy for "場次" in the mock stage — it tracks matches the user has signed up for. `userStore.ntrpText` already returns the formatted NTRP string (e.g. "3.5"). HomeView already has `@Environment(UserStore.self) private var userStore` at line 13, so no new dependency needed.

- [ ] **Step 2: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "fix: replace hardcoded stats (場次/NTRP) with dynamic UserStore values"
```

---

### Task 8: Begin HomeView God Object decomposition (Phase 1 — extract filter panel)

**Files:**
- Create: `TennisMatch/Views/Home/MatchFilterPanelView.swift`
- Modify: `TennisMatch/Views/HomeView.swift`

**Why:** HomeView is 1968 lines with 40+ @State. Full decomposition is a large effort better suited to its own plan. For this P0 pass, we extract the filter panel as a first step to prove the pattern and reduce HomeView by ~200 lines. This addresses audit item **Module 2 P0 — HomeView God Object** partially — a follow-up plan will continue the decomposition.

- [ ] **Step 1: Create Home subdirectory**

Run: `mkdir -p TennisMatch/Views/Home`

- [ ] **Step 2: Read HomeView filter panel code**

Read the filter panel overlay section in HomeView. Identify the `filterPanelOverlay` computed property and all supporting filter-related code (filterChips, filter constants, NTRP slider, etc.). These are approximately lines 663-920 and 1404-1410.

- [ ] **Step 3: Create MatchFilterPanelView**

Extract the filter panel into `TennisMatch/Views/Home/MatchFilterPanelView.swift`. This view takes bindings for all filter state and a dismiss action:

```swift
//
//  MatchFilterPanelView.swift
//  TennisMatch
//
//  篩選面板 — 從 HomeView 提取的獨立組件
//

import SwiftUI

struct MatchFilterPanelView: View {
    @Binding var ntrpLow: Double
    @Binding var ntrpHigh: Double
    @Binding var selectedAgeRange: Set<String>
    @Binding var selectedGender: String
    @Binding var selectedCourts: Set<TennisCourt>
    @Binding var selectedDays: Set<String>
    @Binding var timeFrom: Double
    @Binding var timeTo: Double
    @Binding var showCourtPicker: Bool
    var onDismiss: () -> Void
    var onReset: () -> Void

    var body: some View {
        // Move the filter panel content here from HomeView
        // (exact implementation depends on reading the full filter panel code)
    }
}
```

The engineer implementing this step should:
1. Read HomeView's `filterPanelOverlay` and all `filterXxx` computed properties
2. Move them into `MatchFilterPanelView`
3. Replace the filter panel code in HomeView with a single `MatchFilterPanelView(...)` call

- [ ] **Step 4: Update HomeView to use extracted component**

Replace the inline filter panel in HomeView with:
```swift
MatchFilterPanelView(
    ntrpLow: $ntrpLow,
    ntrpHigh: $ntrpHigh,
    selectedAgeRange: $selectedAgeRange,
    selectedGender: $selectedGender,
    selectedCourts: $selectedCourts,
    selectedDays: $selectedDays,
    timeFrom: $timeFrom,
    timeTo: $timeTo,
    showCourtPicker: $showCourtPicker,
    onDismiss: { showFilterPanel = false },
    onReset: { resetFilters() }
)
```

- [ ] **Step 5: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/Home/MatchFilterPanelView.swift TennisMatch/Views/HomeView.swift
git commit -m "refactor: extract MatchFilterPanelView from HomeView (God Object decomposition phase 1)"
```

---

## Summary

| Task | Audit Item | Severity | Files Changed |
|------|-----------|----------|---------------|
| 1 | FlowLayout 重复实现 | P0 (Module 5) | 3 files |
| 2 | 三套重复 Player 数据模型 | P0 (Module 5) | 4 files |
| 3 | OTP 验证形同虚设 | P0 (Module 1) | 1 file |
| 4 | 违反强解包规则 | P0 (Module 1) | 1 file |
| 5 | 发布约球无必填项校验 | P0 (Module 3) | 1 file |
| 6 | 缺少拉球类型 (全链路) | P0 (Module 3) + P1 (Module 2) | 2 files |
| 7 | 统计数据硬编码 | P0 (Module 2) | 1 file |
| 8 | HomeView God Object (Phase 1) | P0 (Module 2) | 2 files |

**Next plans after this one:**
- `2026-04-22-p1-fixes-batch1.md` — Module 1-3 P1 issues (21 items)
- `2026-04-22-p1-fixes-batch2.md` — Module 4-7 P1 issues (20 items)
- `2026-04-22-p2-fixes.md` — All P2 issues (31 items)
- `2026-04-22-homeview-decomposition.md` — Full HomeView God Object decomposition (continuation of Task 8)
