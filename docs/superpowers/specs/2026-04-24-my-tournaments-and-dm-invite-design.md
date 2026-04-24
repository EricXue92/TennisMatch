# 「我的賽事」 Tab + 私信邀請 — Design

**Date:** 2026-04-24
**Status:** Approved, pending implementation plan
**Related audit item:** Follow-up to UI/UX audit fix batches

---

## Goal

Two related feature additions to MyMatchesView:

1. **Feature A — 「我的賽事」 tab**: Tournaments the user publishes should appear in MyMatchesView under a new third tab alongside 即將到來 / 已完成, with a 管理 action that mirrors the match management pattern (查看報名者 / 編輯 / 關閉報名 / 取消 / 私信邀請).

2. **Feature B — DM invite from 管理**: For the user's own published matches, the existing 管理 confirmation dialog should gain a 「私信邀請球友」 action that opens a mutual-follow picker and jumps into a chat prepopulated with an invite card. The same picker is reused by Feature A.

## Non-goals (explicit YAGNI)

- Actually editing tournament/match details (「編輯」 stays a stub toast).
- Actually closing registration (「關閉報名」 stays a stub toast).
- Cross-launch persistence of published/cancelled tournaments.
- Inviting users outside mutual-follow scope.

---

## Architecture

### New: `TournamentStore` (`@Observable`)

File: `TennisMatch/Models/TournamentStore.swift`

Replaces `TournamentView`'s current local `@State var tournaments: [MockTournament]`. The store is the single source of truth so MyMatchesView can read the same list without prop-drilling.

```swift
@Observable
final class TournamentStore {
    var tournaments: [MockTournament]

    init(initial: [MockTournament] = mockTournaments) {
        self.tournaments = initial
    }

    func addPublished(info: PublishedTournamentInfo, organizerName: String, organizerGender: Gender) { ... }
    func cancel(id: UUID) { ... }
}
```

Injected into env from `TennisMatchApp`. Same pattern as existing `FollowStore`, `BookedSlotStore`, `NotificationStore`, `CreditScoreStore`.

### New: `InvitePickerSheet` (reusable component)

File: `TennisMatch/Components/InvitePickerSheet.swift`

Shared UI for picking a mutual-follow target to DM an invite to. Used by Feature A (tournament invite) and Feature B (match invite).

```swift
enum InviteTarget: Identifiable {
    case match(MyMatchItem)
    case tournament(MockTournament)
    var id: UUID {
        switch self {
        case .match(let m): return m.id
        case .tournament(let t): return t.id
        }
    }
}

struct InvitePickerSheet: View {
    let target: InviteTarget
    let onPick: (FollowPlayer) -> Void
    // Lists mockMutualFollowPlayers filtered by followStore.isFollowing()
    // Uses existing FollowPlayerRow.
    // Empty state: "暫無互關好友"
}
```

### Modified files

- `TennisMatch/Views/TournamentView.swift` — read from store, drop local @State. `CreateTournamentView`'s `onPublish` routes into `tournamentStore.addPublished(...)`.
- `TennisMatch/Views/MyMatchesView.swift` — add 我的賽事 tab, tournament card + manage dialog, invite picker wiring on match manage dialog.
- `TennisMatch/TennisMatchApp.swift` — `.environment(TournamentStore())` on the root view.

---

## UI & Flows

### MyMatchesView tab layout

Filter tabs: `["即將到來", "已完成", "我的賽事"]`.

When `selectedFilter == "我的賽事"`:
- Show `tournamentStore.tournaments.filter { $0.isOwnTournament }`.
- Empty state: `ContentUnavailableView("還沒有發起過賽事", systemImage: "trophy", description: Text("去賽事頁發起你的第一場賽事"))` + a "去發起賽事" button that calls a new `onGoTournaments: (() -> Void)?` closure. HomeView wires this to switch the main tab to Tournament.

### Tournament card (in 我的賽事 tab)

Reuses the compact layout from `TournamentView.tournamentCard`. Card content: 名稱 · 日期範圍 · 賽制 · 報名 x/y. Tapping the card pushes `TournamentDetailView`. A 「管理」 button sits trailing, 44pt tap target, opens `showTournamentManage` confirmation dialog.

To avoid duplication, extract a thin `ownedTournamentCard(_ tournament:)` in MyMatchesView that reuses shared styling. (Full tournamentCard extraction into a Component is out of scope here — we'll only do what's needed for this feature.)

### Tournament manage confirmationDialog

Presented via `.confirmationDialog("管理賽事", isPresented: $showTournamentManage, presenting: tournamentToManage)`.

Buttons, in order:

1. **查看報名者** — sets `tournamentRegistrantSheet = tournament` → slim sheet listing `tournament.playerList`. Mirrors existing match `registrantMatch` pattern.
2. **編輯賽事** — `toast = .init(kind: .info, text: "編輯賽事功能即將推出")` (stub).
3. **關閉報名** — `toast = .init(kind: .info, text: "關閉報名功能即將推出")` (stub).
4. **私信邀請球友** — sets `inviteTarget = .tournament(tournament)` → opens InvitePickerSheet.
5. **取消賽事** (destructive) — sets `tournamentToCancel = tournament` + `showCancelTournamentAlert = true` → alert confirms → `tournamentStore.cancel(id:)` + `NotificationStore.push(.cancelled, ...)` + `toast = .init(kind: .success, text: "已取消賽事")`.
6. **取消** (cancel role).

No status-based gating for v1 — all buttons show regardless of tournament status. The stubs are safe no-ops; cancellation on a completed tournament just removes it from the list (acceptable for mock-stage v1).

### Match manage confirmationDialog (existing, extended)

Current order (after our last fix):
`查看報名者 · 編輯約球 · 關閉報名 · 取消約球 · 取消`

New order inserts 私信邀請 between 關閉報名 and 取消約球:
`查看報名者 · 編輯約球 · 關閉報名 · 私信邀請球友 · 取消約球 · 取消`

「私信邀請球友」 sets `inviteTarget = .match(match)` → opens InvitePickerSheet.

### InvitePickerSheet presentation

Presented on MyMatchesView via `.sheet(item: $inviteTarget)`.

Body is a `NavigationStack { List { ForEach(mutualFollows) { FollowPlayerRow(...) } } }`.

On tap of a row, the sheet calls `onPick(player)` which:

1. Dismisses sheet (`inviteTarget = nil`).
2. Resolves/creates the personal chat:
   - If `sharedChats` already contains a personal chat with `player.name`, reuse it.
   - Otherwise build `MockChat(type: .personal(name: player.name, symbol: player.gender.symbol, symbolColor: ...), lastMessage: "點擊開始聊天", time: "剛剛", unreadCount: 0)` and insert at index 0.
3. Builds `selectedChatMatchContext` from the `InviteTarget`:
   - `.match(m)`: `"🎾 邀請你加入我的約球\n\(m.title)\n\(m.dateLabel) \(m.timeRange)\n📍 \(m.location)\n👥 \(m.players)"`
   - `.tournament(t)`: `"🏆 邀請你參加我的賽事\n\(t.name)\n📅 \(t.dateRange)\n📍 \(t.location)\n🎾 \(t.matchType) · \(t.format)"`
4. Sets `selectedChat = chat` → existing `.navigationDestination(item: $selectedChat)` pushes ChatDetailView with the context.

ChatDetailView's existing `matchContext` rendering (invite card with 「接受」 action) is unchanged — we're only populating it from a new caller path.

---

## Data Model & Edge Cases

### Tournament cancellation

```swift
func cancel(id: UUID) {
    tournaments.removeAll { $0.id == id }
}
```

Side-effects (handled in MyMatchesView, not the store):
- `notificationStore.push(.cancelled, title: "賽事已取消", body: "「\(tournament.name)」 已取消", ...)`
- `toast = .init(kind: .success, text: "已取消賽事")`
- No credit-score deduction (unlike matches).

### Invite deduplication

Before creating a new MockChat, check existing `sharedChats` for a `.personal(name:)` match. If found, reuse the chat id and just update `selectedChatMatchContext`. Prevents duplicate chat rows when user invites the same person twice.

### Empty InvitePickerSheet

If `mockMutualFollowPlayers.filter { followStore.isFollowing($0.name) }.isEmpty`, render:
```
ContentUnavailableView("暫無互關好友", systemImage: "person.2",
    description: Text("互相關注後才能邀請對方"))
+ "去關注球友" button → dismiss sheet (user navigates themselves)
```

### Completed-status tournaments

All buttons show regardless of status for v1. Cancel on a completed tournament just removes the card — acceptable for mock-stage UI. Proper gating is a follow-up.

---

## Testing Scope

Manual smoke tests (no automated tests in this project):

**Tournament flow:**
1. Navigate to 賽事 → 建立賽事 → fill + publish.
2. Switch to 我的約球 → 我的賽事 tab → confirm card appears.
3. Tap 管理 → try each of 5 actions:
   - 查看報名者 → sheet opens with empty/seed list.
   - 編輯 / 關閉報名 → toast "即將推出".
   - 私信邀請 → picker opens (see invite flow below).
   - 取消賽事 → confirm → card disappears + notification pushed + toast shown.
4. Verify cancellation also removes the tournament from the 賽事 page list.

**Match invite flow:**
1. Create a match via CreateMatchView (or use a seeded isOrganizer match).
2. In 我的約球 tap 管理 → 私信邀請球友.
3. Pick a mutual follow → sheet dismisses → chat opens with invite card rendered in ChatDetailView.
4. Re-invoke invite for same person → confirm no duplicate chat appears in MessagesView.

**Empty picker state:**
1. Temporarily unfollow all mutuals via FollowStore (or test fixture).
2. Tap 私信邀請 → confirm ContentUnavailableView shown.

---

## Files Summary

| Action | Path |
|--------|------|
| Create | `TennisMatch/Models/TournamentStore.swift` |
| Create | `TennisMatch/Components/InvitePickerSheet.swift` |
| Modify | `TennisMatch/TennisMatchApp.swift` |
| Modify | `TennisMatch/Views/TournamentView.swift` |
| Modify | `TennisMatch/Views/MyMatchesView.swift` |
| Modify | `TennisMatch/Views/HomeView.swift` (onGoTournaments wiring for empty state) |
