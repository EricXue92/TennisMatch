# P1 Fixes Batch 1 — Quick Logic & Validation Fixes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 13 P1 issues that are quick, focused, single-file (or 2-file) changes — validation fixes, state management, disabled states, and missing guards.

**Architecture:** Each task is independent. No ordering dependencies.

**Tech Stack:** Swift / SwiftUI / iOS 17+ / `@Observable`

**Already fixed from P0 pass:** "验证错误不会自动消失" (Task 4), "拉球类型缺失于筛选器" (Task 6)

---

### Task 1: Improve email validation in EmailRegisterView

**Files:** Modify: `TennisMatch/Views/EmailRegisterView.swift`

**Audit:** P1 Module 1 — Email 格式校验过于宽松 + 发送验证码无前置校验

Two issues in one file:
1. `validate()` (line 272) only checks `@` and `.` exist — `a@.` passes
2. `sendCode()` (line 253) starts countdown without validating email format first; button only checks `!email.isEmpty`

- [ ] **Step 1: Improve email regex in validate()**

In `EmailRegisterView.swift`, find line 272:
```swift
} else if !email.contains("@") || !email.contains(".") {
```
Replace with a proper email pattern check:
```swift
} else if !isValidEmail(email) {
```

Add this helper function to the struct:
```swift
private func isValidEmail(_ email: String) -> Bool {
    let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    return email.range(of: pattern, options: .regularExpression) != nil
}
```

- [ ] **Step 2: Add email validation before sendCode()**

Find `sendCode()` (line 253). Add a guard at the top:
```swift
private func sendCode() {
    guard isValidEmail(email) else {
        validationMessage = "請輸入有效的郵箱地址"
        withAnimation { showValidationError = true }
        return
    }
    codeSent = true
    // ... rest unchanged
```

- [ ] **Step 3: Update sendButtonEnabled to check email format**

Find `sendButtonEnabled` (line 242):
```swift
private var sendButtonEnabled: Bool {
    !email.isEmpty && (!codeSent || canResend)
}
```
Replace with:
```swift
private var sendButtonEnabled: Bool {
    isValidEmail(email) && (!codeSent || canResend)
}
```

- [ ] **Step 4: Build and commit**

---

### Task 2: Disable send button when chat input is empty

**Files:** Modify: `TennisMatch/Views/ChatDetailView.swift`

**Audit:** P1 Module 4 — 发送按钮始终高亮

The send button at line ~595 is always green/tappable even when input is empty.

- [ ] **Step 1: Read ChatDetailView to find the input field state variable name**

Find the @State for the text input (likely `messageText` or similar) and the `sendMessage()` function.

- [ ] **Step 2: Update send button appearance and disabled state**

Find the send button (line ~595):
```swift
Button { sendMessage() } label: {
    Text("發送")
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.white)
        .frame(width: 50, height: 36)
        .background(
            Capsule().fill(Theme.accentGreen)
        )
}
```

Replace with (using the correct text state variable name):
```swift
Button { sendMessage() } label: {
    Text("發送")
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.white)
        .frame(width: 50, height: 36)
        .background(
            Capsule().fill(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.chipUnselectedBg : Theme.accentGreen)
        )
}
.disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
```

Adjust the variable name to whatever the actual @State property is called.

- [ ] **Step 3: Build and commit**

---

### Task 3: Make FollowStore counts dynamic

**Files:** Modify: `TennisMatch/Models/FollowStore.swift`

**Audit:** P1 Module 5 — FollowStore.mutualCount 和 followerCount 是静态值

`followerCount` and `mutualCount` are static init values (18 and 12) that never change when the user follows/unfollows.

- [ ] **Step 1: Make counts computed from mock data**

In `FollowStore.swift`, replace the static stored properties with computed properties.

Remove the stored `followerCount` and `mutualCount` properties and the init parameters for them. Replace with:

```swift
@Observable
final class FollowStore {
    var following: Set<String>

    var followingCount: Int { following.count }

    /// 粉絲數 = mockAllFollowers 中仍在列表裡的人數（mock 階段簡化邏輯）
    var followerCount: Int { mockAllFollowers.count }

    /// 互關數 = 同時在 following 和 mockAllFollowers 中的人數
    var mutualCount: Int {
        mockAllFollowers.filter { following.contains($0.name) }.count
    }

    init(following: Set<String> = FollowStore.seedFollowing) {
        self.following = following
    }
    
    // ... rest of functions unchanged
```

Note: `mockAllFollowers` is defined in `PlayerModels.swift` (created in P0 Task 2) and is accessible project-wide.

- [ ] **Step 2: Build and commit**

---

### Task 4: Add unfollow confirmation to FollowerListView

**Files:** Modify: `TennisMatch/Views/FollowerListView.swift`

**Audit:** P1 Module 5 — 粉丝列表取消互关无确认弹窗（FollowingView 和 MutualFollowListView 都有确认，FollowerListView 没有）

- [ ] **Step 1: Add confirmation state and alert**

In `FollowerListView.swift`, add state properties:
```swift
@State private var playerToUnfollow: FollowPlayer?
@State private var showUnfollowAlert = false
```

- [ ] **Step 2: Change the follow/unfollow button action for mutual followers**

In the `followerRow` function, when `isMutual` is true, instead of directly toggling:
```swift
Button {
    withAnimation { followStore.toggle(follower.name) }
}
```

Change to show alert only when unfollowing (i.e., when isMutual is true):
```swift
Button {
    if isMutual {
        playerToUnfollow = follower
        showUnfollowAlert = true
    } else {
        withAnimation { followStore.toggle(follower.name) }
    }
}
```

- [ ] **Step 3: Add the alert to the view body**

Add after the existing `.navigationDestination`:
```swift
.alert("取消關注", isPresented: $showUnfollowAlert) {
    Button("取消", role: .cancel) { playerToUnfollow = nil }
    Button("確認", role: .destructive) {
        if let p = playerToUnfollow {
            withAnimation { followStore.unfollow(p.name) }
        }
        playerToUnfollow = nil
    }
} message: {
    if let p = playerToUnfollow {
        Text("確定要取消關注「\(p.name)」嗎？")
    }
}
```

- [ ] **Step 4: Build and commit**

---

### Task 5: Persist Settings toggles with @AppStorage

**Files:** Modify: `TennisMatch/Views/SettingsView.swift`

**Audit:** P1 Module 7 — Settings 通知开关和隐私选项不持久化

All toggles and pickers use `@State` — they reset on page dismiss.

- [ ] **Step 1: Replace @State with @AppStorage for persistent settings**

In `SettingsView.swift`, find lines 13-17:
```swift
@State private var matchReminders = true
@State private var chatNotifications = true
@State private var tournamentUpdates = true
@State private var profileVisibility = "所有人"
@State private var dmPermission = "所有人"
```

Replace with:
```swift
@AppStorage("matchReminders") private var matchReminders = true
@AppStorage("chatNotifications") private var chatNotifications = true
@AppStorage("tournamentUpdates") private var tournamentUpdates = true
@AppStorage("profileVisibility") private var profileVisibility = "所有人"
@AppStorage("dmPermission") private var dmPermission = "所有人"
```

- [ ] **Step 2: Build and commit**

---

### Task 6: Remove time picker 1-second auto-close

**Files:** Modify: `TennisMatch/Views/CreateMatchView.swift`

**Audit:** P1 Module 3 — 时间选择器 1 秒后自动关闭

The `.onChange` handler dismisses the wheel picker after 1 second — bad UX.

- [ ] **Step 1: Remove auto-dismiss for start time picker**

Find the `.onChange(of: selectedStartTime)` block (~line 277). Remove the auto-dismiss logic:
```swift
let dismissId = UUID()
startTimeDismissId = dismissId
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    if startTimeDismissId == dismissId {
        showStartTimePicker = false
    }
}
```

Keep only the end-time auto-clamp logic that's above it.

- [ ] **Step 2: Remove auto-dismiss for end time picker**

Find the similar `.onChange(of: selectedEndTime)` block. Remove the same pattern (DispatchQueue + dismissId + auto-close). Keep any validation logic.

- [ ] **Step 3: Remove the dismissId state variables**

Find and remove `@State private var startTimeDismissId` and `@State private var endTimeDismissId` (or similar names) since they're no longer needed.

- [ ] **Step 4: Build and commit**

---

### Task 7: Add success toast after publishing match

**Files:** Modify: `TennisMatch/Views/CreateMatchView.swift`

**Audit:** P1 Module 3 — 发布成功无任何反馈

`publishMatch()` directly dismisses without any success indication.

- [ ] **Step 1: Read publishMatch() to understand the current flow**

The current flow (line ~678):
```swift
private func publishMatch() {
    let info = PublishedMatchInfo(...)
    showConfirmation = false
    onPublish?(info)
    dismiss()
}
```

The `onPublish` callback is called before dismiss — the parent view (HomeView) receives the data. The toast should appear on the parent (HomeView) since this view is dismissing. So the fix is to ensure HomeView shows a success toast when it receives the callback.

- [ ] **Step 2: Check HomeView's onPublish handler**

Read HomeView to find where `CreateMatchView` is presented and what happens in the `onPublish` callback. The success feedback should be added there (a toast in HomeView after the sheet dismisses).

Find the `.sheet` presentation for CreateMatchView in HomeView and add a toast after receiving the published match. If HomeView already has a toast system, use it. Add something like:
```swift
CreateMatchView { info in
    // ... existing handling ...
    conflictToast = "約球已成功發布 🎾"
}
```

Use whatever toast state variable HomeView already has (likely `conflictToast` or similar).

- [ ] **Step 3: Build and commit**

---

### Task 8: Fix gender hardcoded to male in MyMatchesView invitations

**Files:** Modify: `TennisMatch/Views/MyMatchesView.swift`

**Audit:** P1 Module 3 — 接受邀请时性别硬编码为男性

Line ~353: All invitation acceptances create a chat with hardcoded `"♂"` and `Theme.genderMale`.

- [ ] **Step 1: Find all hardcoded gender in invitation chat creation**

Search MyMatchesView.swift for `"♂"` and `Theme.genderMale` in MockChat creation contexts. There may be multiple instances.

- [ ] **Step 2: Replace with data from the invitation**

The invitation data should contain the inviter's gender info. If the invitation struct has a gender field, use it. If not, read the struct definition and check what's available.

If the invitation has a `gender` field or symbol:
```swift
MockChat(
    type: .personal(name: inv.inviterName, symbol: inv.gender.symbol, symbolColor: inv.gender == .female ? Theme.genderFemale : Theme.genderMale),
    ...
)
```

If no gender is available on the invitation, use UserStore to look up, or default to a neutral representation. Read the actual data structures to determine the right approach.

- [ ] **Step 3: Build and commit**

---

### Task 9: Prevent duplicate tournament signup

**Files:** Modify: `TennisMatch/Views/TournamentView.swift`

**Audit:** P1 Module 6 — 赛事可重复报名

The signup button at line ~588 has no guard to prevent clicking multiple times.

- [ ] **Step 1: Find the signup state and button**

Read TournamentView to find:
1. Whether there's an `isSignedUp` state or similar
2. The signup confirmation flow (line ~588 shows `showSignUpConfirm = true`)
3. Where the actual signup action happens (after confirmation)

- [ ] **Step 2: Add signup guard**

If there's already an `isSignedUp` @State, use it to disable the button. If not, add one:
```swift
@State private var isSignedUp = false
```

Update the bottom bar button to show different text and be disabled after signup:
```swift
Button {
    if !isSignedUp {
        showSignUpConfirm = true
    }
} label: {
    Text(isSignedUp ? "已報名" : "立即報名 · \(tournament.fee)")
        // ...
        .background(isSignedUp ? Theme.chipUnselectedBg : Theme.primaryEmerald)
}
.disabled(isSignedUp)
```

And in the actual signup completion handler, set `isSignedUp = true`.

- [ ] **Step 3: Build and commit**

---

### Task 10: Fix password change without current password verification

**Files:** Modify: `TennisMatch/Views/SettingsView.swift`

**Audit:** P1 Module 7 — 修改密码不验证当前密码

The password change sheet directly shows "密碼修改成功" without checking `currentPassword`.

- [ ] **Step 1: Find the ChangePasswordSheet**

Read SettingsView.swift to find the change password sheet/view. It should have fields for currentPassword, newPassword, confirmPassword.

- [ ] **Step 2: Add current password validation**

Before showing success, add a guard:
```swift
guard !currentPassword.isEmpty else {
    errorMessage = "請輸入目前的密碼"
    return
}
guard currentPassword == "password123" else { // mock 階段用固定值
    errorMessage = "目前的密碼不正確"
    return
}
guard newPassword.count >= 6 else {
    errorMessage = "新密碼至少需要 6 位"
    return
}
guard newPassword == confirmNewPassword else {
    errorMessage = "兩次新密碼不一致"
    return
}
```

- [ ] **Step 3: Build and commit**

---

### Task 11: Add no-results guidance to HomeView empty filter state

**Files:** Modify: `TennisMatch/Views/HomeView.swift`

**Audit:** P1 Module 2 — 空状态缺乏引导

When filters yield no results, only shows "🎾 沒有符合條件的約球" with no action buttons.

- [ ] **Step 1: Find the empty state view in HomeView**

Search for "沒有符合條件的約球" in HomeView.swift.

- [ ] **Step 2: Add action buttons to the empty state**

Replace the plain text with a more helpful empty state:
```swift
ContentUnavailableView {
    Label("沒有符合條件的約球", systemImage: "magnifyingglass")
} description: {
    Text("試試調整篩選條件，或發起一場新的約球")
} actions: {
    Button("清除篩選") {
        selectedFilter = "全部"
        ntrpLow = 1.0; ntrpHigh = 7.0
        selectedAgeRange.removeAll()
        selectedGender = ""
        selectedCourts.removeAll()
        selectedDays.removeAll()
        timeFrom = 7.0; timeTo = 23.0
        showFilterPanel = false
    }
    .buttonStyle(.bordered)

    Button("發起約球") {
        showCreateMatch = true
    }
    .buttonStyle(.borderedProminent)
    .tint(Theme.primary)
}
```

- [ ] **Step 3: Build and commit**

---

### Task 12: Add pull-to-refresh to HomeView

**Files:** Modify: `TennisMatch/Views/HomeView.swift`

**Audit:** P1 Module 2 — 没有下拉刷新

The home tab's ScrollView has no `.refreshable`.

- [ ] **Step 1: Find the ScrollView in homeTab**

Locate the main ScrollView in the home tab content.

- [ ] **Step 2: Add .refreshable modifier**

Add `.refreshable` to the ScrollView:
```swift
ScrollView {
    // ... existing content
}
.refreshable {
    // Mock 階段模擬刷新 — 重新載入列表
    try? await Task.sleep(for: .seconds(0.8))
    matches = initialMockMatches
}
```

Note: `initialMockMatches` is the constant mock array. In mock stage, refresh just reloads the initial data.

- [ ] **Step 3: Build and commit**

---

### Task 13: Persist LinkedAccountsSheet state

**Files:** Modify: `TennisMatch/Views/SettingsView.swift`

**Audit:** P1 Module 7 — LinkedAccountsSheet 关联状态不持久化

The linked accounts (Google, Apple, Line) use local @State — reset when sheet closes.

- [ ] **Step 1: Find LinkedAccountsSheet in SettingsView**

Find the linked accounts sheet struct. Identify the @State properties for linked status.

- [ ] **Step 2: Replace @State with @AppStorage**

Change the linked account states from `@State` to `@AppStorage`:
```swift
@AppStorage("linkedGoogle") private var linkedGoogle = false
@AppStorage("linkedApple") private var linkedApple = true
@AppStorage("linkedLine") private var linkedLine = false
```

Keep the "至少保留一種" protection logic unchanged.

- [ ] **Step 3: Build and commit**

---

## Summary

| Task | Audit Item | Module | File |
|------|-----------|--------|------|
| 1 | Email 校验宽松 + 发码无前置检查 | 1 | EmailRegisterView |
| 2 | 发送按钮始终高亮 | 4 | ChatDetailView |
| 3 | FollowStore 计数静态 | 5 | FollowStore |
| 4 | 粉丝列表取消互关无确认 | 5 | FollowerListView |
| 5 | Settings 不持久化 | 7 | SettingsView |
| 6 | 时间选择器自动关闭 | 3 | CreateMatchView |
| 7 | 发布成功无反馈 | 3 | CreateMatchView + HomeView |
| 8 | 性别硬编码♂ | 3 | MyMatchesView |
| 9 | 赛事可重复报名 | 6 | TournamentView |
| 10 | 密码不验证 | 7 | SettingsView |
| 11 | 空状态无引导 | 2 | HomeView |
| 12 | 无下拉刷新 | 2 | HomeView |
| 13 | 关联状态不持久化 | 7 | SettingsView |
