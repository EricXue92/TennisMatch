# Batch 2a — P1 数据 & 逻辑层修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 8 P1 data/logic bugs from fix-plan-v2.md Batch 2a — cross-midnight time parsing, hour/minute validation, login flow corrections, date-edit flags, AA cost validation, court persistence, and signedUpMatchIDs persistence.

**Architecture:** Each task is an isolated single-file fix (except G-2 which touches UserStore + EditProfileView). No dependencies between tasks — they can be done in any order. All changes are in existing files.

**Tech Stack:** Swift / SwiftUI / `@Observable` / `@AppStorage`

---

### Task 1: MatchSchedule 支持跨午夜时间段 (A-2)

**Files:**
- Modify: `TennisMatch/Models/MatchSchedule.swift:118-124`

Currently line 124 falls back to `start + defaultDurationHours` when `end <= start`. For cross-midnight (e.g. "23:00 - 01:00"), the end resolves to same-day 01:00 which is < start 23:00 → incorrect fallback. Fix: when `end <= start`, add 1 day to end before falling back.

- [ ] **Step 1: Modify `dateRange` to handle cross-midnight**

In `TennisMatch/Models/MatchSchedule.swift`, replace lines 122-124:

```swift
// BEFORE:
let end = calendar.date(from: endComps) ?? fallback
// 若 end <= start(罕见的解析异常),用 fallback 兜底,避免空区间被误判为不冲突。
return (start, end > start ? end : fallback)
```

```swift
// AFTER:
var end = calendar.date(from: endComps) ?? fallback
// 跨午夜(如 23:00 - 01:00):end 落在同日 01:00 < start 23:00,向后推一天。
if end <= start, let nextDay = calendar.date(byAdding: .day, value: 1, to: end) {
    end = nextDay
}
return (start, end > start ? end : fallback)
```

- [ ] **Step 2: Verify build**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Models/MatchSchedule.swift
git commit -m "fix: MatchSchedule dateRange supports cross-midnight time spans (A-2)"
```

---

### Task 2: CalendarService 加 hour/minute 边界校验 (A-3)

**Files:**
- Modify: `TennisMatch/Models/CalendarService.swift:154-163`

`apply(time:to:)` parses `"25:75"` → `bySettingHour:25 minute:75` which silently wraps to next day. Add a guard for valid ranges.

- [ ] **Step 1: Add hour/minute bounds guard**

In `TennisMatch/Models/CalendarService.swift`, replace lines 157-159:

```swift
// BEFORE:
guard parts.count == 2,
      let hour = Int(parts[0]),
      let minute = Int(parts[1]) else { return nil }
```

```swift
// AFTER:
guard parts.count == 2,
      let hour = Int(parts[0]),
      let minute = Int(parts[1]),
      (0...23).contains(hour),
      (0...59).contains(minute) else { return nil }
```

- [ ] **Step 2: Verify build**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Models/CalendarService.swift
git commit -m "fix: CalendarService rejects out-of-range hour/minute (A-3)"
```

---

### Task 3: LoginView WeChat/Apple 改为 toast "即將支持" (B-2)

**Files:**
- Modify: `TennisMatch/Views/LoginView.swift:14,17,140-169`

Both WeChat and Apple buttons currently set `isLoggedIn = true`, bypassing registration. Replace with a toast. LoginView currently has no toast state, so add one.

- [ ] **Step 1: Add toast state**

In `TennisMatch/Views/LoginView.swift`, after line 18 (`@State private var showHelpView = false`), add:

```swift
@State private var toastMessage: String?
```

- [ ] **Step 2: Change WeChat action**

Replace line 146:

```swift
// BEFORE:
action: { isLoggedIn = true }
```

```swift
// AFTER:
action: { toastMessage = "微信登录即將支持" }
```

- [ ] **Step 3: Change Apple action**

Replace line 150:

```swift
// BEFORE:
Button(action: { isLoggedIn = true }) {
```

```swift
// AFTER:
Button(action: { toastMessage = "Apple 登录即將支持" }) {
```

- [ ] **Step 4: Add toast overlay**

In the body, after `.navigationDestination(isPresented: $showHelpView)` (line 61), add:

```swift
.overlay(alignment: .top) {
    if let msg = toastMessage {
        Text(msg)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.textDeep.opacity(0.92))
            .clipShape(Capsule())
            .padding(.top, 60)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { toastMessage = nil }
                }
            }
    }
}
.animation(.easeInOut(duration: 0.3), value: toastMessage)
```

- [ ] **Step 5: Verify build**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/LoginView.swift
git commit -m "fix: WeChat/Apple login buttons show toast instead of bypassing registration (B-2)"
```

---

### Task 4: LoginView "立即註冊" 修正跳转目标 (B-3)

**Files:**
- Modify: `TennisMatch/Views/LoginView.swift:17,57-58,208`

"立即註冊" currently sets `showVerification = true` → navigates to `PhoneVerificationView`. It should go to `RegisterView`. Add a new `@State` for the register destination.

- [ ] **Step 1: Add register navigation state**

After `@State private var showHelpView = false` (line 18) — or after the toast state from Task 3 — add:

```swift
@State private var showRegister = false
```

- [ ] **Step 2: Change "立即註冊" button action**

Replace line 208:

```swift
// BEFORE:
Button(action: { showVerification = true }) {
```

```swift
// AFTER:
Button(action: { showRegister = true }) {
```

- [ ] **Step 3: Add navigationDestination for RegisterView**

After the `.navigationDestination(isPresented: $showHelpView)` block (line 61), add:

```swift
.navigationDestination(isPresented: $showRegister) {
    RegisterView()
}
```

- [ ] **Step 4: Verify build**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Views/LoginView.swift
git commit -m "fix: '立即註冊' navigates to RegisterView instead of PhoneVerificationView (B-3)"
```

---

### Task 5: CreateMatchView 日期编辑 flag 改 @State (H-2)

**Files:**
- Modify: `TennisMatch/Views/CreateMatchView.swift:312-320`

The current code has `@State private var _dateWasEdited` backing stores with computed property wrappers (`private var dateWasEdited: Bool { _dateWasEdited }`). The computed properties are read-only aliases that work correctly — the `_` prefixed `@State` vars are what get mutated. The real issue from the plan is that if the computed properties were being *set* somewhere, those writes would be silently dropped.

Looking at the code, `_dateWasEdited`, `_startTimeEdited`, `_endTimeEdited` are directly mutated via onChange handlers (e.g. line 299: `_endTimeEdited = true`), so the backing stores work. The computed properties are only read in `confirmDateText` (lines 654-656). The indirection is unnecessary but not buggy. Simplify by removing the computed wrappers and using the `@State` vars directly.

- [ ] **Step 1: Remove redundant computed properties**

In `TennisMatch/Views/CreateMatchView.swift`, delete lines 318-320:

```swift
// DELETE these three lines:
private var dateWasEdited: Bool { _dateWasEdited }
private var startTimeEdited: Bool { _startTimeEdited }
private var endTimeEdited: Bool { _endTimeEdited }
```

- [ ] **Step 2: Rename backing stores to remove underscore prefix**

Throughout the file, rename:
- `_dateWasEdited` → `dateWasEdited`
- `_startTimeEdited` → `startTimeEdited`
- `_endTimeEdited` → `endTimeEdited`
- `_startTimeDismissId` → `startTimeDismissId`
- `_endTimeDismissId` → `endTimeDismissId`

The `@State` declarations (lines 312-316) become:

```swift
@State private var dateWasEdited = false
@State private var startTimeEdited = false
@State private var endTimeEdited = false
@State private var startTimeDismissId = UUID()
@State private var endTimeDismissId = UUID()
```

And all references in the file (onChange handlers, confirmDateText, etc.) use the new names without underscore.

- [ ] **Step 3: Verify build**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/CreateMatchView.swift
git commit -m "fix: remove redundant computed wrappers for date-edit flags (H-2)"
```

---

### Task 6: CreateMatchView AA制费用非空校验 (H-1)

**Files:**
- Modify: `TennisMatch/Views/CreateMatchView.swift:544-546,503-516`

When `costType == "AA制"`, the user can publish with empty `costAmount`. Add validation: disable the submit button or show inline error when AA is selected but amount is empty/zero.

- [ ] **Step 1: Add validation state**

After `@State private var notes: String = ""` (line 50), add:

```swift
@State private var showCostError = false
```

- [ ] **Step 2: Add validation to submit button**

Replace the submit button action (line 545-546):

```swift
// BEFORE:
Button {
    showConfirmation = true
```

```swift
// AFTER:
Button {
    if costType == "AA制" && (costAmount.isEmpty || Int(costAmount) ?? 0 <= 0) {
        showCostError = true
        return
    }
    showCostError = false
    showConfirmation = true
```

- [ ] **Step 3: Add error hint below the cost TextField**

In the cost section, after the closing `}` of the `if costType == "AA制"` TextField block (after line 516), add:

```swift
if showCostError && costType == "AA制" {
    Text("請填寫費用金額")
        .font(.system(size: 12))
        .foregroundColor(Theme.badge)
}
```

- [ ] **Step 4: Clear error when user switches to 免費**

In the 免費 radio button action (line 499), add error clearing:

```swift
// BEFORE:
costType = "免費"
```

```swift
// AFTER:
costType = "免費"
showCostError = false
```

- [ ] **Step 5: Verify build**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/CreateMatchView.swift
git commit -m "fix: validate AA cost amount is non-empty before publishing (H-1)"
```

---

### Task 7: EditProfileView 保存球场选择 (G-2)

**Files:**
- Modify: `TennisMatch/Models/UserStore.swift:16-44`
- Modify: `TennisMatch/Views/EditProfileView.swift:57-66,284-290`

`EditProfileView` has a `selectedCourt` local state but never saves it to `UserStore`. UserStore doesn't even have a `selectedCourt` property. Add one and wire it up.

- [ ] **Step 1: Add selectedCourt to UserStore**

In `TennisMatch/Models/UserStore.swift`, after `var region: String` (line 30), add:

```swift
/// 偏好球场。
var selectedCourt: TennisCourt?
```

And in the `init`, after `region: String = "香港"` parameter (line 37), add a parameter:

```swift
selectedCourt: TennisCourt? = nil,
```

And in the init body, after `self.region = region` (line 43), add:

```swift
self.selectedCourt = selectedCourt
```

Note: `TennisCourt` is defined in `RegisterView.swift` — UserStore already imports Foundation; `TennisCourt` is a top-level struct visible project-wide.

- [ ] **Step 2: Seed court from store in EditProfileView onAppear**

In `TennisMatch/Views/EditProfileView.swift`, inside the `onAppear` block (after line 65 `region = userStore.region`), add:

```swift
if let court = userStore.selectedCourt {
    selectedCourt = court
}
```

- [ ] **Step 3: Save court in saveButton**

In `TennisMatch/Views/EditProfileView.swift`, inside the save button action (after line 289 `userStore.region = region`), add:

```swift
userStore.selectedCourt = selectedCourt
```

- [ ] **Step 4: Verify build**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/UserStore.swift TennisMatch/Views/EditProfileView.swift
git commit -m "fix: EditProfileView persists court selection to UserStore (G-2)"
```

---

### Task 8: signedUpMatchIDs 持久化 (C-3)

**Files:**
- Modify: `TennisMatch/Views/HomeView.swift:51`

`signedUpMatchIDs` is `@State` — lost when the view is recreated (e.g. app backgrounded then purged). Change to `@AppStorage` with JSON encoding since `@AppStorage` doesn't natively support `Set<UUID>`.

- [ ] **Step 1: Replace @State with @AppStorage + computed accessor**

In `TennisMatch/Views/HomeView.swift`, replace line 51:

```swift
// BEFORE:
@State private var signedUpMatchIDs: Set<UUID> = []
```

```swift
// AFTER:
@AppStorage("signedUpMatchIDs") private var signedUpMatchIDsData: Data = Data()

private var signedUpMatchIDs: Set<UUID> {
    get {
        (try? JSONDecoder().decode(Set<UUID>.self, from: signedUpMatchIDsData)) ?? []
    }
}

private func updateSignedUpMatchIDs(_ ids: Set<UUID>) {
    signedUpMatchIDsData = (try? JSONEncoder().encode(ids)) ?? Data()
}
```

- [ ] **Step 2: Update all mutation sites**

Search for all places in HomeView.swift where `signedUpMatchIDs` is mutated (`.insert`, `.remove`, `= []`, etc.) and replace with calls to `updateSignedUpMatchIDs`. For example:

- `signedUpMatchIDs.insert(id)` → `var ids = signedUpMatchIDs; ids.insert(id); updateSignedUpMatchIDs(ids)`
- `signedUpMatchIDs.remove(id)` → `var ids = signedUpMatchIDs; ids.remove(id); updateSignedUpMatchIDs(ids)`

Use `grep -n "signedUpMatchIDs" TennisMatch/Views/HomeView.swift` to find all sites and update each one.

- [ ] **Step 3: Verify build**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "fix: persist signedUpMatchIDs via @AppStorage to survive background purge (C-3)"
```

---

## Verification

After all 8 tasks are complete, verify:

- [ ] Full project builds: `xcodebuild build`
- [ ] "23:00-01:00" cross-midnight time span parses correctly (end is next day 01:00, not same day)
- [ ] CalendarService rejects `"25:75"` — returns nil
- [ ] WeChat/Apple login buttons show toast, do NOT enter main app
- [ ] "立即註冊" navigates to RegisterView
- [ ] Date/time edit flags use clean `@State` names (no underscore prefix)
- [ ] AA制 with empty cost → cannot publish, error shown
- [ ] EditProfileView saves and restores court selection
- [ ] signedUpMatchIDs survives app background cycle
