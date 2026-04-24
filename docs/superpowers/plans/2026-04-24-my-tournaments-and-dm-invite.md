# 我的賽事 Tab + 私信邀請 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 「我的賽事」 tab to MyMatchesView that shows user-published tournaments with a 管理 dialog, and add a 「私信邀請球友」 action to both match and tournament manage dialogs that opens a mutual-follow picker and jumps into a pre-populated chat.

**Architecture:** Lift tournament state out of TournamentView into a shared `@Observable TournamentStore`. Introduce a reusable `InvitePickerSheet` component keyed by an `InviteTarget` enum (match or tournament). Both features share the same invite pipeline; tournaments get their own management dialog with parallel actions to the existing match dialog.

**Tech Stack:** Swift / SwiftUI / iOS 17+ / `@Observable` pattern (existing project convention)

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `TennisMatch/Models/TournamentStore.swift` | `@Observable` store owning the tournaments list; add/cancel mutations |
| Create | `TennisMatch/Components/InvitePickerSheet.swift` | Reusable mutual-follow picker + `InviteTarget` enum |
| Modify | `TennisMatch/TennisMatchApp.swift` | Inject `TournamentStore` into the environment |
| Modify | `TennisMatch/Views/TournamentView.swift` | Read tournaments from store, stop owning local `@State` |
| Modify | `TennisMatch/Views/MyMatchesView.swift` | Add 我的賽事 tab, tournament card + manage dialog, invite wiring on match dialog |
| Modify | `TennisMatch/Views/HomeView.swift` | Pass `onGoTournaments` callback to switch to Tournament surface |

---

### Task 1: Create TournamentStore

**Files:**
- Create: `TennisMatch/Models/TournamentStore.swift`

**Why:** Tournament state currently lives as `@State var tournaments` inside `TournamentView` (lines 18). MyMatchesView needs to read the same list and trigger cancellation, so state must be lifted into a shared `@Observable` store following the same pattern as `FollowStore`, `NotificationStore`, `CreditScoreStore`.

- [ ] **Step 1: Create the store file**

Create `TennisMatch/Models/TournamentStore.swift`:

```swift
//
//  TournamentStore.swift
//  TennisMatch
//
//  共享的賽事狀態 — 取代之前 TournamentView 中的 local @State,
//  讓 MyMatchesView 與 TournamentView 能共用同一份資料。
//

import Foundation

@Observable
final class TournamentStore {
    var tournaments: [MockTournament]

    init(initial: [MockTournament] = mockTournaments) {
        self.tournaments = initial
    }

    /// 加入一場新發布的賽事 — 當前用戶為發起人。
    func addPublished(
        info: PublishedTournamentInfo,
        organizerName: String,
        organizerGender: Gender
    ) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateRange = "\(formatter.string(from: info.startDate)) - \(formatter.string(from: info.endDate))"

        let tournament = MockTournament(
            name: info.name.isEmpty ? "我的賽事" : info.name,
            format: info.format,
            matchType: info.matchType,
            ntrpRange: info.level,
            status: "報名中",
            dateRange: dateRange,
            location: info.courtName.isEmpty ? "待定" : info.courtName,
            participants: "0/\(info.participantCount.isEmpty ? "16" : info.participantCount)",
            fee: info.fee.isEmpty ? "免費" : "\(info.fee) 港幣",
            organizer: organizerName,
            organizerGender: organizerGender,
            gradientColors: [Theme.gradGreenLight, Theme.primary],
            rules: info.rules.isEmpty ? [] : [info.rules],
            playerList: [],
            isOwnTournament: true
        )
        tournaments.insert(tournament, at: 0)
    }

    /// 取消賽事 — 從列表中移除。副作用(通知 / toast)由呼叫方處理。
    func cancel(id: UUID) {
        tournaments.removeAll { $0.id == id }
    }
}
```

- [ ] **Step 2: Build to verify the file compiles standalone**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (new file compiles; `TournamentStore` type is unused but the project should still build).

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Models/TournamentStore.swift
git commit -m "feat: add TournamentStore for shared tournament state"
```

---

### Task 2: Inject TournamentStore into the app and wire TournamentView

**Files:**
- Modify: `TennisMatch/TennisMatchApp.swift`
- Modify: `TennisMatch/Views/TournamentView.swift`

**Why:** Connect the store to the environment so descendant views (`TournamentView`, `MyMatchesView`) can read/mutate it. Replace `TournamentView`'s local `@State var tournaments` with `tournamentStore.tournaments`.

- [ ] **Step 1: Inject TournamentStore in TennisMatchApp**

In `TennisMatch/TennisMatchApp.swift`, after the existing `@State private var ratingFeedbackStore = RatingFeedbackStore()` (line 18), add:

```swift
    @State private var tournamentStore = TournamentStore()
```

Then in the `.environment(...)` chain after `.environment(ratingFeedbackStore)` (line 40), add:

```swift
            .environment(tournamentStore)
```

- [ ] **Step 2: Update TournamentView to read from the store**

In `TennisMatch/Views/TournamentView.swift`:

1. At line 14 (after `@Environment(UserStore.self) private var userStore`), add:
```swift
    @Environment(TournamentStore.self) private var tournamentStore
```

2. Delete line 18:
```swift
    @State private var tournaments: [MockTournament] = mockTournaments
```

3. Replace the `filteredTournaments` computed property (lines 52-55):

Old:
```swift
    private var filteredTournaments: [MockTournament] {
        let base = selectedFilter == "全部" ? tournaments : tournaments.filter { $0.status == selectedFilter }
        return base.sorted { $0.isOwnTournament && !$1.isOwnTournament }
    }
```

New:
```swift
    private var filteredTournaments: [MockTournament] {
        let base = selectedFilter == "全部"
            ? tournamentStore.tournaments
            : tournamentStore.tournaments.filter { $0.status == selectedFilter }
        return base.sorted { $0.isOwnTournament && !$1.isOwnTournament }
    }
```

4. Replace the `addPublishedTournament` private method (lines 57-80) with a thin call to the store:

Old:
```swift
    private func addPublishedTournament(_ info: PublishedTournamentInfo) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateRange = "\(formatter.string(from: info.startDate)) - \(formatter.string(from: info.endDate))"

        let tournament = MockTournament(
            name: info.name.isEmpty ? "我的賽事" : info.name,
            format: info.format,
            matchType: info.matchType,
            ntrpRange: info.level,
            status: "報名中",
            dateRange: dateRange,
            location: info.courtName.isEmpty ? "待定" : info.courtName,
            participants: "0/\(info.participantCount.isEmpty ? "16" : info.participantCount)",
            fee: info.fee.isEmpty ? "免費" : "\(info.fee) 港幣",
            organizer: userStore.displayName,
            organizerGender: userStore.gender,
            gradientColors: [Theme.gradGreenLight, Theme.primary],
            rules: info.rules.isEmpty ? [] : [info.rules],
            playerList: [],
            isOwnTournament: true
        )
        tournaments.insert(tournament, at: 0)
    }
```

New:
```swift
    private func addPublishedTournament(_ info: PublishedTournamentInfo) {
        tournamentStore.addPublished(
            info: info,
            organizerName: userStore.displayName,
            organizerGender: userStore.gender
        )
    }
```

- [ ] **Step 3: Update TournamentView previews (if any reference needs the env)**

Scroll to the end of `TournamentView.swift` — the `#Preview` blocks (around lines 1053 / 1059) need `.environment(TournamentStore())` added. Find each preview that currently reads:

```swift
    TournamentView()
```

Change each occurrence to:

```swift
    TournamentView()
        .environment(TournamentStore())
        .environment(UserStore())
```

If `UserStore` is already present in the existing preview (check the surrounding modifiers), keep only the one that's missing.

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/TennisMatchApp.swift TennisMatch/Views/TournamentView.swift
git commit -m "refactor: wire TournamentStore into TournamentView via environment"
```

---

### Task 3: Create InvitePickerSheet component

**Files:**
- Create: `TennisMatch/Components/InvitePickerSheet.swift`

**Why:** Both the match and tournament manage dialogs need the same "pick a mutual-follow to DM-invite" flow. Encapsulating in a reusable component keyed by `InviteTarget` avoids duplication and makes the invite context-aware.

- [ ] **Step 1: Create the component file**

Create `TennisMatch/Components/InvitePickerSheet.swift`:

```swift
//
//  InvitePickerSheet.swift
//  TennisMatch
//
//  邀請球友加入約球 / 賽事 — 從互關好友中挑選對象。
//  管理約球 / 管理賽事 兩個入口共用。
//

import SwiftUI

/// 邀請目標 — 約球或賽事。Identifiable 讓 .sheet(item:) 能驅動呈現。
enum InviteTarget: Identifiable {
    case match(id: UUID, title: String, dateLabel: String, timeRange: String, location: String, players: String)
    case tournament(id: UUID, name: String, dateRange: String, location: String, matchType: String, format: String)

    var id: UUID {
        switch self {
        case .match(let id, _, _, _, _, _): return id
        case .tournament(let id, _, _, _, _, _): return id
        }
    }

    /// 用於 ChatDetailView 的 matchContext 字串 — 渲染邀請卡片。
    var chatContext: String {
        switch self {
        case .match(_, let title, let dateLabel, let timeRange, let location, let players):
            return "🎾 邀請你加入我的約球\n\(title)\n\(dateLabel) \(timeRange)\n📍 \(location)\n👥 \(players)"
        case .tournament(_, let name, let dateRange, let location, let matchType, let format):
            return "🏆 邀請你參加我的賽事\n\(name)\n📅 \(dateRange)\n📍 \(location)\n🎾 \(matchType) · \(format)"
        }
    }

    var titleText: String {
        switch self {
        case .match: return "邀請球友加入約球"
        case .tournament: return "邀請球友加入賽事"
        }
    }
}

struct InvitePickerSheet: View {
    let target: InviteTarget
    let onPick: (FollowPlayer) -> Void

    @Environment(FollowStore.self) private var followStore
    @Environment(\.dismiss) private var dismiss

    private var mutualFollows: [FollowPlayer] {
        mockMutualFollowPlayers.filter { followStore.isFollowing($0.name) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if mutualFollows.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(mutualFollows) { player in
                            Button {
                                onPick(player)
                                dismiss()
                            } label: {
                                playerRow(player)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(target.titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暫無互關好友",
            systemImage: "person.2",
            description: Text("互相關注後才能邀請對方")
        )
    }

    private func playerRow(_ player: FollowPlayer) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 40, height: 40)
                Text(String(player.name.suffix(1)))
                    .font(Typography.labelSemibold)
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xxs) {
                    Text(player.name)
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.textPrimary)
                    Text(player.gender.symbol)
                        .font(Typography.small)
                        .foregroundColor(player.gender == .female ? Theme.genderFemale : Theme.genderMale)
                }
                Text("NTRP \(player.ntrp) · \(player.latestActivity)")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "paperplane.fill")
                .foregroundColor(Theme.primary)
        }
        .padding(.vertical, Spacing.xxs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}
```

**Note on `Spacing.xxs`:** if this token does not exist in the project, replace with `Spacing.xs`. Do a quick `Grep` for `Spacing.xxs` before building — adjust to `Spacing.xs` if absent.

- [ ] **Step 2: Check Spacing token availability**

Run Grep for `Spacing.xxs`. If no results, replace both occurrences in the file from Step 1 with `Spacing.xs`.

- [ ] **Step 3: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Components/InvitePickerSheet.swift
git commit -m "feat: add reusable InvitePickerSheet for mutual-follow invites"
```

---

### Task 4: Add 私信邀請 to the match manage dialog

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift`

**Why:** First surface wiring the new InvitePickerSheet. Adds the invite action to the existing match manage dialog without disturbing tournament logic yet.

- [ ] **Step 1: Add invite state to MyMatchesView**

In `TennisMatch/Views/MyMatchesView.swift`, locate the `@State` declarations at the top of the struct (around line 22 next to `selectedChat`). After `@State private var selectedChatMatchContext: String?`, add:

```swift
    @State private var inviteTarget: InviteTarget?
```

- [ ] **Step 2: Insert 「私信邀請球友」 button in the match manage dialog**

Find the confirmationDialog block we added earlier (starts with `.confirmationDialog("管理約球", isPresented: $showManageSheet, ...)`). Current button order is:

```swift
            Button("查看報名者") { registrantMatch = match }
            Button("編輯約球") { toast = .init(kind: .info, text: "編輯約球功能即將推出") }
            Button("關閉報名") { toast = .init(kind: .info, text: "關閉報名功能即將推出") }
            Button("取消約球", role: .destructive) {
                matchToCancel = match
                showCancelAlert = true
            }
            Button("取消", role: .cancel) {}
```

Insert one new button between 關閉報名 and 取消約球:

```swift
            Button("私信邀請球友") {
                inviteTarget = .match(
                    id: match.id,
                    title: match.title,
                    dateLabel: match.dateLabel,
                    timeRange: match.timeRange,
                    location: match.location,
                    players: match.players
                )
            }
```

The final block looks like:

```swift
        .confirmationDialog("管理約球", isPresented: $showManageSheet, presenting: matchToManage) { match in
            Button("查看報名者") {
                registrantMatch = match
            }
            Button("編輯約球") {
                toast = .init(kind: .info, text: "編輯約球功能即將推出")
            }
            Button("關閉報名") {
                toast = .init(kind: .info, text: "關閉報名功能即將推出")
            }
            Button("私信邀請球友") {
                inviteTarget = .match(
                    id: match.id,
                    title: match.title,
                    dateLabel: match.dateLabel,
                    timeRange: match.timeRange,
                    location: match.location,
                    players: match.players
                )
            }
            Button("取消約球", role: .destructive) {
                matchToCancel = match
                showCancelAlert = true
            }
            Button("取消", role: .cancel) {}
        } message: { match in
            Text(match.title)
        }
```

- [ ] **Step 3: Attach the invite picker sheet and its completion handler**

Find the `.sheet(item: $registrantMatch)` modifier. Immediately after its closing brace, add a new sheet for `inviteTarget`:

```swift
        .sheet(item: $inviteTarget) { target in
            InvitePickerSheet(target: target) { player in
                handleInvitePicked(player: player, target: target)
            }
        }
```

- [ ] **Step 4: Add the handleInvitePicked private method**

Add this method near the other private helpers (e.g., near `ntrpMidpoint` at the bottom of the primary struct body, before any extension blocks). If unsure, place it right after the existing `acceptedMatchItems` computed property's helpers:

```swift
    private func handleInvitePicked(player: FollowPlayer, target: InviteTarget) {
        // 若已有與此球友的私信,重用現有 chat;否則新建。
        let existing = sharedChats.first { chat in
            if case .personal(let name, _, _) = chat.type, name == player.name { return true }
            return false
        }
        let chat: MockChat
        if let existing {
            chat = existing
        } else {
            let newChat = MockChat(
                type: .personal(
                    name: player.name,
                    symbol: player.gender.symbol,
                    symbolColor: player.gender == .female ? Theme.genderFemale : Theme.genderMale
                ),
                lastMessage: "點擊開始聊天",
                time: "剛剛",
                unreadCount: 0
            )
            sharedChats.insert(newChat, at: 0)
            chat = newChat
        }
        selectedChatMatchContext = target.chatContext
        selectedChat = chat
        toast = .init(kind: .success, text: "已發送邀請給 \(player.name)")
    }
```

- [ ] **Step 5: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "feat: add 私信邀請球友 action to match manage dialog"
```

---

### Task 5: Add 我的賽事 filter tab and tournament card rendering

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift`

**Why:** Introduce the third tab and render the user's own tournaments. No manage dialog yet — that lands in Task 6.

- [ ] **Step 1: Add TournamentStore dependency and filter option**

At the top of `MyMatchesView`, next to the other `@Environment` declarations (around line 13-19), add:

```swift
    @Environment(TournamentStore.self) private var tournamentStore
```

Find the filter tabs — look for the array of filter option strings (likely `["即將到來", "已完成"]`). Replace with:

```swift
["即將到來", "已完成", "我的賽事"]
```

Use Grep to locate the exact line:
```
grep -n '"即將到來"' TennisMatch/Views/MyMatchesView.swift
```
Replace that occurrence of the two-element array with the three-element array. If there's a single spot using `ForEach(["即將到來", "已完成"], id: \.self) { ... }`, update it there.

- [ ] **Step 2: Compute my own tournaments**

Add a computed property near `visibleInvitations` (around line 99):

```swift
    private var myOwnTournaments: [MockTournament] {
        tournamentStore.tournaments.filter { $0.isOwnTournament }
    }
```

- [ ] **Step 3: Branch the body to render the new tab**

Find the main `if/else` in the body that handles `selectedFilter == "即將到來"` empty state vs `selectedFilter == "已完成"` empty state vs the list. Add a third branch for `我的賽事` before the `ScrollView`. The current structure is roughly:

```swift
            if selectedFilter == "即將到來" && upcomingEmpty {
                // empty upcoming
            } else if selectedFilter == "已完成" && completedEmpty {
                // empty completed
            } else {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        if selectedFilter == "即將到來" {
                            // upcoming content
                        } else {
                            // completed content
                        }
                    }
                    ...
                }
            }
```

Change to:

```swift
            if selectedFilter == "即將到來" && upcomingEmpty {
                // existing empty upcoming
            } else if selectedFilter == "已完成" && completedEmpty {
                // existing empty completed
            } else if selectedFilter == "我的賽事" && myOwnTournaments.isEmpty {
                VStack(spacing: Spacing.md) {
                    ContentUnavailableView(
                        "還沒有發起過賽事",
                        systemImage: "trophy",
                        description: Text("去賽事頁發起你的第一場賽事")
                    )
                    if let onGoTournaments {
                        Button {
                            onGoTournaments()
                        } label: {
                            Text("去發起賽事")
                                .font(Typography.bodyMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.lg)
                                .frame(height: 36)
                                .background(Theme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        if selectedFilter == "即將到來" {
                            // existing upcoming content unchanged
                        } else if selectedFilter == "已完成" {
                            // existing completed content unchanged (change from `else` to explicit check)
                        } else {
                            ForEach(myOwnTournaments) { tournament in
                                ownedTournamentCard(tournament)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, 100)
                }
            }
```

Keep the existing 即將到來 and 已完成 body content intact — only add the 我的賽事 branch.

- [ ] **Step 4: Add the onGoTournaments stored property**

At the top of the struct (near `onGoHome`), add:

```swift
    var onGoTournaments: (() -> Void)? = nil
```

- [ ] **Step 5: Add ownedTournamentCard render method**

At the bottom of the struct body (before the closing `}` of the primary `MyMatchesView`), add this private method:

```swift
    @ViewBuilder
    private func ownedTournamentCard(_ tournament: MockTournament) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(Typography.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                    Text("\(tournament.format) · \(tournament.matchType) · NTRP \(tournament.ntrpRange)")
                        .font(Typography.small)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Text(tournament.status)
                    .font(Typography.micro)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xs)
                    .frame(height: 22)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            HStack(spacing: Spacing.md) {
                Label(tournament.dateRange, systemImage: "calendar")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
                Label(tournament.location, systemImage: "mappin.and.ellipse")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
            }

            HStack {
                Label("報名 \(tournament.participants)", systemImage: "person.2.fill")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Button("管理") {
                    tournamentToManage = tournament
                    showTournamentManage = true
                }
                .font(Typography.captionMedium)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.md)
                .frame(minHeight: 44)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.inputBorder, lineWidth: 0.5)
        }
    }
```

Also add the supporting `@State` declarations at the top (near `showManageSheet`):

```swift
    @State private var tournamentToManage: MockTournament?
    @State private var showTournamentManage = false
    @State private var tournamentRegistrantSheet: MockTournament?
    @State private var tournamentToCancel: MockTournament?
    @State private var showCancelTournamentAlert = false
```

- [ ] **Step 6: Update preview blocks**

Find the `#Preview` blocks at the bottom of the file (around line 1614 and 1620). Add `.environment(TournamentStore())` to each. Example:

```swift
#Preview {
    MyMatchesView(acceptedMatches: .constant([]), sharedChats: .constant([]))
        .environment(RatingFeedbackStore())
        .environment(UserStore())
        .environment(FollowStore())
        .environment(BookedSlotStore())
        .environment(NotificationStore())
        .environment(CreditScoreStore())
        .environment(TournamentStore())
}
```

If a preview already injects some stores but not others, only add what's missing. The key one to add is `TournamentStore()` — `FollowStore` may already be present because InvitePickerSheet reads it.

- [ ] **Step 7: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 8: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "feat: add 我的賽事 tab with tournament cards in MyMatchesView"
```

---

### Task 6: Add the tournament manage dialog with all 5 actions

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift`

**Why:** With the tab and card in place, add the management actions: 查看報名者, 編輯, 關閉報名, 私信邀請, 取消賽事.

- [ ] **Step 1: Add the tournament manage confirmation dialog**

Find the existing `.confirmationDialog("管理約球", ...)` block (Task 4). Immediately after its closing brace, add:

```swift
        .confirmationDialog("管理賽事", isPresented: $showTournamentManage, presenting: tournamentToManage) { tournament in
            Button("查看報名者") {
                tournamentRegistrantSheet = tournament
            }
            Button("編輯賽事") {
                toast = .init(kind: .info, text: "編輯賽事功能即將推出")
            }
            Button("關閉報名") {
                toast = .init(kind: .info, text: "關閉報名功能即將推出")
            }
            Button("私信邀請球友") {
                inviteTarget = .tournament(
                    id: tournament.id,
                    name: tournament.name,
                    dateRange: tournament.dateRange,
                    location: tournament.location,
                    matchType: tournament.matchType,
                    format: tournament.format
                )
            }
            Button("取消賽事", role: .destructive) {
                tournamentToCancel = tournament
                showCancelTournamentAlert = true
            }
            Button("取消", role: .cancel) {}
        } message: { tournament in
            Text(tournament.name)
        }
```

- [ ] **Step 2: Add the cancellation alert**

After the confirmation dialog from Step 1, add:

```swift
        .alert("取消賽事", isPresented: $showCancelTournamentAlert, presenting: tournamentToCancel) { tournament in
            Button("再想想", role: .cancel) {
                tournamentToCancel = nil
            }
            Button("確認取消", role: .destructive) {
                tournamentStore.cancel(id: tournament.id)
                notificationStore.push(MatchNotification(
                    type: .cancelled,
                    title: "賽事已取消",
                    body: "「\(tournament.name)」 已取消",
                    time: "剛剛",
                    isRead: false
                ))
                toast = .init(kind: .success, text: "已取消賽事")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                tournamentToCancel = nil
            }
        } message: { tournament in
            Text("確認取消「\(tournament.name)」?已報名的球友將收到通知。")
        }
```

- [ ] **Step 3: Add the registrant list sheet for tournaments**

After the cancellation alert, add:

```swift
        .sheet(item: $tournamentRegistrantSheet) { tournament in
            NavigationStack {
                Group {
                    if tournament.playerList.isEmpty {
                        ContentUnavailableView(
                            "還沒有球友報名",
                            systemImage: "person.2",
                            description: Text("賽事開始報名後,報名球友會顯示在這裡")
                        )
                    } else {
                        List {
                            ForEach(Array(tournament.playerList.enumerated()), id: \.offset) { _, player in
                                HStack(spacing: Spacing.sm) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.avatarPlaceholder)
                                            .frame(width: 36, height: 36)
                                        Text(String(player.name.suffix(1)))
                                            .font(Typography.labelSemibold)
                                            .foregroundColor(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(player.name)
                                            .font(Typography.bodyMedium)
                                            .foregroundColor(Theme.textPrimary)
                                        Text("NTRP \(player.ntrp)")
                                            .font(Typography.small)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("報名者 (\(tournament.participants))")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { tournamentRegistrantSheet = nil }
                    }
                }
            }
        }
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "feat: add tournament manage dialog, cancellation, and registrant sheet"
```

---

### Task 7: Wire onGoTournaments callback from HomeView

**Files:**
- Modify: `TennisMatch/Views/HomeView.swift`

**Why:** The 我的賽事 empty state has a "去發起賽事" button that requires HomeView to switch the main tab to Tournament. Pass the callback through `MyMatchesView(...)` instantiation.

- [ ] **Step 1: Identify the current Tournament tab trigger**

Use Grep to find where tournaments surface is shown. The current app uses `showTournaments` or similar on HomeView. Run:

```
grep -n "showTournaments\|TournamentView()\|selectedTab" TennisMatch/Views/HomeView.swift
```

Look for the existing way to navigate to `TournamentView` from HomeView. Two likely patterns:
1. A `@State var showTournaments: Bool` with a `.navigationDestination`.
2. A tab switch via `selectedTab`.

- [ ] **Step 2: Pass the callback to MyMatchesView**

Find where `MyMatchesView(...)` is instantiated in HomeView (grep located it at line 62):

```swift
case 1: MyMatchesView(acceptedMatches: $acceptedMatches, sharedChats: $sharedChats, onGoHome: { selectedTab = 0 }, onMatchCancelled: { sourceMatchID in
```

Add the `onGoTournaments:` parameter using whatever navigation mechanism the project currently uses. If `showTournaments` is a `@State Bool`:

```swift
case 1: MyMatchesView(
    acceptedMatches: $acceptedMatches,
    sharedChats: $sharedChats,
    onGoHome: { selectedTab = 0 },
    onGoTournaments: { showTournaments = true },
    onMatchCancelled: { sourceMatchID in
```

(Keep the rest of the closure body unchanged.)

If navigation to Tournament instead goes through an existing menu action, find that function and call it in the closure. Example if there's a `openTournaments()` helper:

```swift
onGoTournaments: { openTournaments() },
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "feat: wire onGoTournaments from HomeView into MyMatchesView empty state"
```

---

### Task 8: Manual smoke test

**Files:** none (verification only)

**Why:** Project has no automated tests; validate the two feature flows manually in the simulator.

- [ ] **Step 1: Run the app**

Run: `xcodebuild build -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -5`
Then launch via Xcode (or `xcrun simctl launch`) on the iPhone 17 simulator.

- [ ] **Step 2: Verify tournament flow**

1. Navigate to 賽事 → 建立賽事 → fill minimum required fields → publish.
2. Return to 我的約球 → tap 我的賽事 tab → confirm the new tournament appears at the top.
3. Tap 管理 → verify all 5 buttons:
   - 查看報名者 → sheet opens; empty state since playerList is empty.
   - 編輯賽事 → toast "編輯賽事功能即將推出".
   - 關閉報名 → toast "關閉報名功能即將推出".
   - 私信邀請球友 → picker sheet opens showing mutual follows.
   - 取消賽事 → confirm dialog → tap 確認取消 → card disappears, notification badge increments, toast shows "已取消賽事".
4. Navigate to 賽事 page → confirm the cancelled tournament is also gone from that list.

- [ ] **Step 3: Verify match invite flow**

1. In 我的約球 → 即將到來, find an `isOrganizer: true` match (mock data has several; e.g. card titled "我發起的...").
2. Tap 管理 → tap 私信邀請球友 → picker opens.
3. Pick any mutual follow → sheet dismisses → chat pushes with invite card rendered (🎾 邀請你加入我的約球 ...).
4. Return to 我的約球 → repeat 私信邀請 for the same player → confirm no duplicate chat created (MessagesView should still show one personal chat with that player).

- [ ] **Step 4: Verify empty invite state**

1. (Optional) Use FollowStore to unfollow all mutuals temporarily via the 關注 / 粉絲 pages.
2. Tap 私信邀請 → confirm ContentUnavailableView "暫無互關好友" shows.
3. Refollow to restore state.

- [ ] **Step 5: Commit any follow-up fixes found during testing**

If testing surfaces bugs, fix them with small follow-up commits. When clean, push a final smoke-test commit placeholder if desired:

```bash
git log --oneline -10
```

---

## Summary

| Task | Files | Commits |
|------|-------|---------|
| 1 | Models/TournamentStore.swift | 1 |
| 2 | TennisMatchApp.swift, Views/TournamentView.swift | 1 |
| 3 | Components/InvitePickerSheet.swift | 1 |
| 4 | Views/MyMatchesView.swift | 1 |
| 5 | Views/MyMatchesView.swift | 1 |
| 6 | Views/MyMatchesView.swift | 1 |
| 7 | Views/HomeView.swift | 1 |
| 8 | none | 0 (or N small fix commits) |

Total: ~7 commits, 6 files touched (2 created, 4 modified).
