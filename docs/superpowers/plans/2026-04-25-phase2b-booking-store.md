# Phase 2b — BookingStore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate scattered booking state (`acceptedMatches`, `signedUpMatchIDs`, `bookedSlots`) into a single `@Observable BookingStore` injected via `@Environment`, eliminating the `@Binding` cascade and the `onMatchCancelled` callback chain.

**Architecture:**
- One `@MainActor @Observable` store owns all booking state and exposes intent-level methods (`signUp`, `acceptInvitation`, `cancel`, `registerExternal`).
- Store mirrors `signedUpMatchIDs` as a derived `Set<UUID>` for O(1) lookup; persists it via UserDefaults under the existing key (no migration).
- Conflict detection lives in the store (`conflict(start:end:excluding:)`); call sites just consume the result.
- Replaces `BookedSlotStore` outright — `BookedSlot` struct is kept (used inside `externalSlots` for mock seed only).

**Tech Stack:** Swift / SwiftUI, `@Observable` (iOS 17+), `@Environment` injection, UserDefaults JSON.

---

## File Structure

| File | Change | Responsibility |
| --- | --- | --- |
| `TennisMatch/Models/BookingStore.swift` | **Create** | The new single-source-of-truth store. |
| `TennisMatch/Models/BookedSlotStore.swift` | **Delete** | Replaced by `BookingStore`. `BookedSlot` struct moves into `BookingStore.swift`. |
| `TennisMatch/TennisMatchApp.swift` | Modify | Inject `BookingStore` instead of `BookedSlotStore`. |
| `TennisMatch/Views/HomeView.swift` | Modify | Drop `@State acceptedMatches` + `signedUpMatchIDs` + UserDefaults code; route signUp through store; drop `onMatchCancelled` handler. |
| `TennisMatch/Views/MyMatchesView.swift` | Modify | Drop `@Binding acceptedMatches` + `onMatchCancelled`; route accept-invitation + cancel through store; mock seed via `registerExternal`. |
| `TennisMatch/Views/ChatDetailView.swift` | Modify | Drop `@Binding acceptedMatches`; read from store; accept invitation via store. |
| `TennisMatch/Views/MessagesView.swift` | Modify | Drop `@Binding acceptedMatches` (pure pass-through). |
| `TennisMatch/Views/MatchDetailView.swift` | Modify | Drop both `@Binding`s; consume store. |
| `TennisMatch/Views/NotificationsView.swift` | Modify | Drop `notificationAccepted` / `notificationSignedUp` constants. |
| `TennisMatch/Views/PublicProfileView.swift` | Modify | Drop `.constant([])` ChatDetailView arg in preview. |
| `TennisMatch/Views/TournamentView.swift` | Modify | Same — drop `.constant([])`. |
| `TennisMatch/Views/MatchAssistantView.swift` | Modify | Drop `.constant([])` MatchDetailView args in preview. |

---

### Task 1: Create `BookingStore`

**Files:**
- Create: `TennisMatch/Models/BookingStore.swift`

- [ ] **Step 1: Write `BookingStore.swift`**

```swift
//
//  BookingStore.swift
//  TennisMatch
//
//  Phase 2b: 集中管理"用户已确认/报名/外部占用"的预定状态。
//  替代旧的 BookedSlotStore + HomeView.acceptedMatches + signedUpMatchIDs 三处分散状态。
//
//  - accepted:          用户已加入"我的约球"的条目(报名 + 接受邀请)。
//  - signedUpMatchIDs:  从 accepted.sourceMatchID 派生的 O(1) 镜像,持久化到 UserDefaults。
//  - externalSlots:     mock 阶段用来注入"已占用但不在 accepted 里"的时段(例如示例数据)。
//  接后端时:externalSlots 由订单/邀请接口拉取,不再 mock 注入。
//

import Foundation
import Observation

/// 跨视图记录"已被占用的时段"。`BookingStore` 内部消费,外部很少直接构造。
struct BookedSlot: Identifiable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    /// 冲突 toast 用的人类可读描述,如 `"莎拉 04/19 10:00"`。
    let label: String
}

enum SignUpResult: Equatable {
    case ok
    case alreadySignedUp
    case conflict(label: String)
}

enum AcceptResult: Equatable {
    case ok
    case conflict(label: String)
}

struct ConflictHit: Equatable {
    let id: UUID
    let label: String
}

@Observable
@MainActor
final class BookingStore {
    private static let signedUpKey = "signedUpMatchIDs"

    /// 用户已确认参加的所有约球(报名 + 接受邀请)。
    private(set) var accepted: [AcceptedMatchInfo] = []

    /// `accepted` 中由"报名 MockMatch"产生的条目 → 其 sourceMatchID 集合。
    /// 用于首页显示"已报名"徽标的 O(1) 查询。
    private(set) var signedUpMatchIDs: Set<UUID> = []

    /// mock 阶段的"外部占用时段"(示例邀请、示例 booking)。
    /// 真实业务中由后端拉取,不会从 UI 主动 add。
    private(set) var externalSlots: [BookedSlot] = []

    init() {
        loadSignedUp()
    }

    // MARK: - Sign up flow (报名 MockMatch)

    /// 报名一个 MockMatch。返回结果由调用方展示 toast / 跳转。
    @discardableResult
    func signUp(matchID: UUID, info: AcceptedMatchInfo) -> SignUpResult {
        if signedUpMatchIDs.contains(matchID) { return .alreadySignedUp }
        if let hit = conflict(start: info.startDate, end: info.endDate, excluding: matchID) {
            return .conflict(label: hit.label)
        }
        accepted.append(info)
        signedUpMatchIDs.insert(matchID)
        persistSignedUp()
        return .ok
    }

    // MARK: - Invitation flow (接受邀请)

    /// 接受邀请。`info.sourceMatchID` 通常为 nil(邀请没有 MockMatch 对应)。
    @discardableResult
    func acceptInvitation(_ info: AcceptedMatchInfo) -> AcceptResult {
        if let hit = conflict(start: info.startDate, end: info.endDate) {
            return .conflict(label: hit.label)
        }
        accepted.append(info)
        if let src = info.sourceMatchID {
            signedUpMatchIDs.insert(src)
            persistSignedUp()
        }
        return .ok
    }

    // MARK: - Cancel

    /// 取消一个 accepted 条目。返回被移除的条目(供撤销 / 业务后续处理)。
    @discardableResult
    func cancel(acceptedID: UUID) -> AcceptedMatchInfo? {
        guard let idx = accepted.firstIndex(where: { $0.id == acceptedID }) else { return nil }
        let removed = accepted.remove(at: idx)
        if let src = removed.sourceMatchID {
            signedUpMatchIDs.remove(src)
            persistSignedUp()
        }
        return removed
    }

    // MARK: - External slots (mock seed only)

    func registerExternal(_ slot: BookedSlot) {
        externalSlots.removeAll { $0.id == slot.id }
        externalSlots.append(slot)
    }

    func removeExternal(id: UUID) {
        externalSlots.removeAll { $0.id == id }
    }

    // MARK: - Queries

    func isSignedUp(matchID: UUID) -> Bool {
        signedUpMatchIDs.contains(matchID)
    }

    /// 与 `[start, end)` 重叠的第一条占用(优先 accepted,再看 externalSlots)。
    /// `excluding`:重新登记同一 booking 时排除自身。
    func conflict(start: Date, end: Date, excluding: UUID? = nil) -> ConflictHit? {
        // accepted 中的条目
        if let m = accepted.first(where: { info in
            info.id != excluding && info.sourceMatchID != excluding
                && info.startDate < end && start < info.endDate
        }) {
            return ConflictHit(id: m.id, label: m.conflictLabel)
        }
        // externalSlots
        if let s = externalSlots.first(where: { slot in
            slot.id != excluding && slot.start < end && start < slot.end
        }) {
            return ConflictHit(id: s.id, label: s.label)
        }
        return nil
    }

    // MARK: - Persistence

    private func loadSignedUp() {
        guard let data = UserDefaults.standard.data(forKey: Self.signedUpKey),
              let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            return
        }
        signedUpMatchIDs = ids
    }

    private func persistSignedUp() {
        guard let data = try? JSONEncoder().encode(signedUpMatchIDs) else { return }
        UserDefaults.standard.set(data, forKey: Self.signedUpKey)
    }
}

private extension AcceptedMatchInfo {
    /// 冲突 toast 用的简短标签 — 与旧 BookedSlot.label 同样格式:`"organizer MM/dd HH:mm"`。
    var conflictLabel: String {
        let f = AppDateFormatter.shortMonthDayHourMinute
        return "\(organizerName) \(f.string(from: startDate))"
    }
}
```

- [ ] **Step 2: Confirm `AppDateFormatter.shortMonthDayHourMinute` exists**

Run: `grep -n "shortMonthDayHourMinute" TennisMatch/Models/AppDateFormatter.swift`
Expected: a static property formatted like `MM/dd HH:mm`. If absent, add it (locale `en_US_POSIX`, format `"MM/dd HH:mm"`).

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED. (Store not yet referenced, but file must compile cleanly.)

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Models/BookingStore.swift
git commit -m "feat(phase2b): add BookingStore — single source of truth for accepted/signedUp/external slots"
```

---

### Task 2: Inject `BookingStore` in `TennisMatchApp`

**Files:**
- Modify: `TennisMatch/TennisMatchApp.swift:16`, `:44`

- [ ] **Step 1: Replace `bookedSlotStore` with `bookingStore`**

```swift
@State private var bookingStore = BookingStore()
// ...
.environment(bookingStore)
```

Drop the old `BookedSlotStore` line and its `.environment(bookedSlotStore)`.

- [ ] **Step 2: Build — expect failures in views still referencing `BookedSlotStore`**

Run: `xcodebuild ...`
Expected: errors in HomeView, MyMatchesView, ChatDetailView, MatchDetailView. **Do NOT commit yet** — Tasks 3–7 fix them.

---

### Task 3: HomeView — drop `@State` and route through store

**Files:**
- Modify: `TennisMatch/Views/HomeView.swift`
  - L15 — change Environment store
  - L40 — remove `@State acceptedMatches`
  - L46 — remove `@State signedUpMatchIDs`
  - L62–73 — drop `onMatchCancelled` handler (no longer needed; cancel updates store directly)
  - L75 — drop `acceptedMatches:` arg to MessagesView
  - L116–122 — replace inline signUp body with `bookingStore.signUp(...)` switch
  - L158–159, L187 — drop `acceptedMatches:` / `signedUpMatchIDs:` bindings to MatchDetailView
  - L196–209 — DELETE `.onAppear` UserDefaults load + `.onChange` save (store handles it)
  - L290 — `bookingStore.signedUpMatchIDs.count`
  - L408 — `bookingStore.isSignedUp(matchID: match.id)`
  - L552 — `bookingStore.isSignedUp(matchID: match.id)`
  - L607–660 — refactor `signUpForMatch` to use store
  - L697–720 — DELETE `addToAcceptedMatches` (now `signUp` does it)

- [ ] **Step 1: Update env + delete state + UserDefaults code**

Replace `@Environment(BookedSlotStore.self) private var bookedSlotStore` with
`@Environment(BookingStore.self) private var bookingStore`. Remove `acceptedMatches`, `signedUpMatchIDs` `@State`, the `.onAppear` UserDefaults load, the `.onChange(of: signedUpMatchIDs)` save, and `addToAcceptedMatches`.

- [ ] **Step 2: Refactor `signUpForMatch`**

```swift
private func signUpForMatch(_ match: MockMatch) {
    let accepted = AcceptedMatchInfo(
        // build from match (existing logic — unchanged)
        sourceMatchID: match.id,
        // ...
    )
    switch bookingStore.signUp(matchID: match.id, info: accepted) {
    case .ok:
        showSignUpSuccess(for: match)   // existing flow
    case .alreadySignedUp:
        return                           // already handled by isSignedUp gate
    case .conflict(let label):
        conflictToast = "已与「\(label)」冲突"
    }
}
```

(Replace existing inline `bookedSlotStore.conflict` + `bookedSlotStore.add` + `acceptedMatches.append` block with this single call.)

- [ ] **Step 3: Update child view args**

`MyMatchesView(acceptedMatches: $acceptedMatches, ...)` → `MyMatchesView(...)` (drop binding + drop `onMatchCancelled`).
`MessagesView(... acceptedMatches: $acceptedMatches, ...)` → drop the binding.
`MatchDetailView(... acceptedMatches: $acceptedMatches, signedUpMatchIDs: $signedUpMatchIDs, ...)` → drop both.

- [ ] **Step 4: Build (will still fail — child views need updating)**

Continue without committing until Task 7.

---

### Task 4: MatchDetailView — consume store directly

**Files:**
- Modify: `TennisMatch/Views/MatchDetailView.swift:12`, `:15`, `:23`, `:398`, `:448`, `:474`, `:658-659`, `:671-672`

- [ ] **Step 1: Drop bindings, swap env**

Remove `@Binding var acceptedMatches`, `@Binding var signedUpMatchIDs`. Change `@Environment(BookedSlotStore.self) private var bookedSlotStore` → `@Environment(BookingStore.self) private var bookingStore`.

- [ ] **Step 2: Replace L398 / L448 signUp block**

The existing block does `conflict` check + `signedUpMatchIDs.insert` + (likely) `acceptedMatches.append` + `bookedSlotStore.add`. Replace with one call:

```swift
switch bookingStore.signUp(matchID: mid, info: accepted) {
case .ok:                 onSignUpSuccess()
case .alreadySignedUp:    return
case .conflict(let l):    conflictToast = "已与「\(l)」冲突"
}
```

- [ ] **Step 3: Replace `signedUpMatchIDs.contains(mid)` reads (L45)**

`bookingStore.isSignedUp(matchID: mid)`.

- [ ] **Step 4: Drop `acceptedMatches:` from sub-view call (L474) and `.constant([])` from previews (L658-659, L671-672)**

---

### Task 5: ChatDetailView — consume store directly

**Files:**
- Modify: `TennisMatch/Views/ChatDetailView.swift:13`, `:22`, `:81`, `:432–450`, `:662`, `:676`

- [ ] **Step 1: Drop binding, swap env**

Remove `@Binding var acceptedMatches`. Change env to `BookingStore`.

- [ ] **Step 2: Replace L81 read**

`acceptedMatches.contains { ... }` → `bookingStore.accepted.contains { ... }` (logic unchanged).

- [ ] **Step 3: Replace L432–450 invitation accept**

```swift
switch bookingStore.acceptInvitation(match) {
case .ok:               // existing success UI
case .conflict(let l):  conflictToast = "已与「\(l)」冲突"
}
```

(Drops the conflict check + `acceptedMatches.append` + `bookedSlotStore.add` triplet.)

- [ ] **Step 4: Drop `.constant([])` from previews (L662, L676)**

---

### Task 6: MyMatchesView — accept + cancel + mock seed

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift:11`, `:17`, `:18`, `:114`, `:268`, `:280–285`, `:516`, `:577`, `:939`, `:957–960`, `:1857`, `:1864`

- [ ] **Step 1: Drop binding + callback, swap env**

Remove `@Binding var acceptedMatches`, `var onMatchCancelled`. Change env to `BookingStore`.

- [ ] **Step 2: Replace data reads**

L114 `acceptedMatches.map` → `bookingStore.accepted.map`.

- [ ] **Step 3: Cancel block (L280–285)**

```swift
if let removed = bookingStore.cancel(acceptedID: aid) {
    // any local UI cleanup (existing ChatDetailView dismiss etc.)
    _ = removed   // sourceMatchID handling now inside store
}
```

Drop `onMatchCancelled?(match.sourceMatchID)` — Cancel already updated `signedUpMatchIDs` inside the store.

- [ ] **Step 4: Mock seed (L516)**

`bookedSlotStore.add(BookedSlot(...))` → `bookingStore.registerExternal(BookedSlot(...))`. Same struct — only the receiver changes.

- [ ] **Step 5: Accept invitation (L939–960)**

Replace conflict-check + append + slot-add triplet with:

```swift
switch bookingStore.acceptInvitation(accepted) {
case .ok:               showAcceptSuccess()
case .conflict(let l):  conflictToast = "已与「\(l)」冲突"
}
```

- [ ] **Step 6: ChatDetailView call sites (L268, L577)**

Drop `acceptedMatches: $acceptedMatches` arg.

- [ ] **Step 7: Previews (L1857, L1864)**

`MyMatchesView(acceptedMatches: .constant([]), sharedChats: .constant([]))` → `MyMatchesView(sharedChats: .constant([]))`.

---

### Task 7: Leaf-view binding cleanup

**Files:**
- Modify: `TennisMatch/Views/MessagesView.swift:12`, `:60`, `:298`, `:304`
- Modify: `TennisMatch/Views/NotificationsView.swift:67–68` (and any leftover `notificationAccepted` / `notificationSignedUp` `@State` — search and remove)
- Modify: `TennisMatch/Views/TournamentView.swift:383`
- Modify: `TennisMatch/Views/PublicProfileView.swift:57`
- Modify: `TennisMatch/Views/MatchAssistantView.swift:57–58`

- [ ] **Step 1: Drop `acceptedMatches` `@Binding` from MessagesView**

Remove the binding declaration and its single usage at L60 (the ChatDetailView call now needs no such arg).

- [ ] **Step 2: NotificationsView — remove notification bindings to MatchDetailView**

Lines 67–68 pass `acceptedMatches: $notificationAccepted, signedUpMatchIDs: $notificationSignedUp`. Both are no-op stand-ins that exist *only* because of the old binding API. Delete the `@State` declarations of `notificationAccepted` / `notificationSignedUp` at top of the file, and drop both args.

- [ ] **Step 3: Preview-only `.constant([])` cleanups**

TournamentView L383, PublicProfileView L57: drop `acceptedMatches: .constant([])` arg from `ChatDetailView(...)`.
MatchAssistantView L57–58: drop both `acceptedMatches: .constant([])` and `signedUpMatchIDs: .constant([])` args from `MatchDetailView(...)`.

- [ ] **Step 4: Build**

Run: `xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit Tasks 2–7 as one atomic migration**

```bash
git add TennisMatch/
git commit -m "refactor(phase2b): migrate views to BookingStore; remove acceptedMatches/signedUpMatchIDs cascade"
```

---

### Task 8: Delete `BookedSlotStore.swift`

**Files:**
- Delete: `TennisMatch/Models/BookedSlotStore.swift`

- [ ] **Step 1: Confirm no remaining references**

Run: `grep -rn "BookedSlotStore\|bookedSlotStore" TennisMatch/`
Expected: zero matches.

- [ ] **Step 2: Delete file**

```bash
git rm TennisMatch/Models/BookedSlotStore.swift
```

(Note: `BookedSlot` struct itself was moved into `BookingStore.swift` in Task 1 — already covered.)

- [ ] **Step 3: Build**

Run: `xcodebuild ... build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(phase2b): delete BookedSlotStore — replaced by BookingStore"
```

---

### Task 9: PR

- [ ] **Step 1: Push branch**

```bash
git push -u origin feat/phase2b-booking-store
```

- [ ] **Step 2: Open PR**

Title: `refactor: Phase 2b — BookingStore consolidates booking state`
Body summarizes: scattered state → one store; eliminates `@Binding` cascade across 7 views; removes `onMatchCancelled` callback chain; preserves UserDefaults persistence under existing key (no migration).

---

## Self-Review

- **Spec coverage:** every audit-named pain point (scattered state ✓, callback fragility ✓, duplicated conflict logic ✓) has a task that addresses it.
- **No placeholders:** Task 1 carries the full BookingStore code; migration tasks point to exact files + line ranges + before/after sketches.
- **Type consistency:** `SignUpResult`, `AcceptResult`, `ConflictHit`, `BookedSlot`, `AcceptedMatchInfo` names match across tasks.
- **Persistence:** UserDefaults key `"signedUpMatchIDs"` reused — existing user data carries forward.
- **Risk:** `AcceptedMatchInfo.sourceMatchID` is the linchpin for derived `signedUpMatchIDs`. Verified during Phase 2a; if absent, conflict scope shrinks but flow still works.
