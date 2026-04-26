# DM 邀請互動接受/拒絕閉環 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 PR #21 的「1.6s 自動回覆」demo scaffold 替換為**用戶可在每張邀請卡上互動點擊接受/拒絕**的真互動模型,並補上「滿員從首頁消失 / 跨聊天派生灰態 / Undo」三項新行為。

**Architecture:** 新增 `@Observable InviteStore`(in-memory)持有所有邀請;`upcomingMatches` 從 `MyMatchesView.@State` 上提到 `HomeView.@State` + `@Binding` 傳回,讓 `acceptInvite`/`undoAcceptInvite` closures(由 HomeView 提供)能直接寫 upcomingMatches + matches。ChatDetailView 渲染時從 InviteStore 拉條目,用「派生顯示狀態」函數計算每張卡是 actionable / accepted / declined / expired,Undo 點擊已決定卡 → confirmationDialog → 反向回滾。

**Tech Stack:** Swift / SwiftUI / `@Observable` / `@Environment` / `@Binding`

**Spec:** `docs/superpowers/specs/2026-04-26-dm-invite-interactive-design.md`

**Project context:**
- 無單元測試框架 — 每個任務的驗證 = `xcodebuild` 編譯通過 + Xcode 模擬器手動冒煙
- 當前分支:`feat/dm-invite-interactive`(已建,spec 已 commit)
- PR #21 引入的類型 `OutgoingInvitationPayload` 保留;`PendingDMInvitation` 將被刪除
- `MyMatchItem` / `MatchRegistrant` / `MyMatchStatus` / `mockUpcomingMatchesInitial` 目前是 `private` 在 `MyMatchesView.swift` 內,需提升為 internal 才能在 HomeView 引用
- `BubbleContent` 已有 `.outgoingInvitation` case(PR #21,**保留**)
- `MockFriendSchedule` 保留;只是換個呼叫點(從 `.task` 模擬器 → `dmInvitationCard` 渲染時查衝突)

**Build command (CLI):**
```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

---

## File Structure

| 文件 | 動作 | 職責 |
|---|---|---|
| `TennisMatch/Models/InviteStore.swift` | **Create** | `@Observable` store + `Invite` struct + `InviteMatchActions` + `InviteCardDisplay` 派生函數 |
| `TennisMatch/TennisMatchApp.swift` | Modify | 注入 `InviteStore` 到 environment chain |
| `TennisMatch/Views/HomeView.swift` | Modify | 注入 `InviteStore`、上提 `upcomingMatches`、提供 `acceptInvite`/`undoAcceptInvite` closures、`MessagesView` 透傳、`matches.filter` 拿掉 `!match.isOwnMatch` 例外、刪除 `onInviteAccepted` callback |
| `TennisMatch/Views/MyMatchesView.swift` | Modify | `MyMatchItem`/`MatchRegistrant`/`MyMatchStatus`/`mockUpcomingMatchesInitial` 提升為 internal、`upcomingMatches` 改 `@Binding`、`handleInvitePicked` 寫入 `InviteStore`、刪除 `pendingInvitation`/`handleInviteResolved`、cancel 流程加 `inviteStore.expireAll(matchID:)` |
| `TennisMatch/Views/MessagesView.swift` | Modify | 接 `matchActions: InviteMatchActions` 參數,透傳到 `ChatDetailView` |
| `TennisMatch/Views/ChatDetailView.swift` | Modify | 刪除 `pendingInvitation`/`onInviteResolved`/`.task` 模擬;新增 `BubbleContent.dmInvitation(UUID)`、`dmInvitationCard`、`actionRow`、`handleAccept`/`handleDecline`/`handleUndo`、`undoTarget` confirmationDialog;`allMessages` 合併 InviteStore 條目;接 `matchActions: InviteMatchActions` 參數 |
| `TennisMatch/Models/MockFriendSchedule.swift` | 不變 | 仍提供 `conflict(for:start:end:)` |
| `TennisMatch/Components/InvitePickerSheet.swift` | 不變 | 既有 `disabledPlayerNames` 已能服務 |
| `TennisMatch/Localizable.xcstrings` | Xcode 自動 extract | 不手改 |

---

## Tasks

### Task 1: Baseline build

**Files:** none

- [ ] **Step 1: 確認當前分支與工作樹**

```bash
git status
git branch --show-current
```

Expected: `feat/dm-invite-interactive`,工作樹乾淨(spec 已 commit)。

- [ ] **Step 2: Baseline build**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

---

### Task 2: 提升 `MyMatchItem` / `MatchRegistrant` / `MyMatchStatus` / `mockUpcomingMatchesInitial` 為 internal

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift`

**Why:** 為 Task 6 的「`upcomingMatches` 上提到 HomeView」做準備 — HomeView 在另一個文件,引用這些類型需要 internal。

- [ ] **Step 1: 找 `MyMatchItem` 定義移除 `private`**

`MyMatchesView.swift` line 1191(目前 `private struct MyMatchItem: Identifiable {`):

```swift
struct MyMatchItem: Identifiable {
```

- [ ] **Step 2: 找 `MatchRegistrant` 定義(在 MyMatchItem 同檔)移除 `private`**

搜 `private struct MatchRegistrant`:

```bash
grep -n "private struct MatchRegistrant\|private enum MyMatchStatus\|private let mockUpcomingMatchesInitial" TennisMatch/Views/MyMatchesView.swift
```

把找到的三處 `private` 都拿掉,變成:

```swift
struct MatchRegistrant {
enum MyMatchStatus {
let mockUpcomingMatchesInitial: [MyMatchItem]
```

(`mockUpcomingMatchesInitial` 是頂層 `let` 而非 `private let`,如果原本就無 `private` 修飾,跳過。)

- [ ] **Step 3: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "$(cat <<'EOF'
refactor(my-matches): 提升 MyMatchItem 等類型為 internal

為「upcomingMatches 上提到 HomeView」做準備:HomeView 與 MyMatchesView
在不同文件,要互傳這些類型必須是 internal。Visibility 變化沒有功能影響。
EOF
)"
```

---

### Task 3: 創建 `Models/InviteStore.swift`

**Files:**
- Create: `TennisMatch/Models/InviteStore.swift`

**Why:** Spec §「數據模型」— 全局邀請持有者 + 派生顯示狀態函數 + closures 結構體。

- [ ] **Step 1: 創建文件 + 寫入完整內容**

```swift
//
//  InviteStore.swift
//  TennisMatch
//
//  全局 DM 邀請存儲(in-memory,跨 chat 共享)。每張邀請卡渲染時從這裡拉狀態,
//  接受/拒絕/反悔通過呼叫 setStatus(...) + 對應的 InviteMatchActions closure。
//

import Foundation
import SwiftUI

@Observable
final class InviteStore {
    enum Status: String { case pending, accepted, declined }

    struct Invite: Identifiable, Equatable {
        let id: UUID
        let matchID: UUID
        let inviteeName: String
        let inviteeGender: Gender
        let inviteeNTRP: String
        let payload: OutgoingInvitationPayload
        let startDate: Date
        let endDate: Date
        var status: Status
        var decidedAt: Date?
        let createdAt: Date
    }

    private(set) var invites: [Invite] = []

    /// 加入新邀請。若同一 (matchID, inviteeName) 已有 active(pending/accepted)邀請,
    /// 先把舊的去掉再 append — InvitePickerSheet 已禁用「已報名」,這是兜底防重。
    func add(_ invite: Invite) {
        invites.removeAll { $0.matchID == invite.matchID
                            && $0.inviteeName == invite.inviteeName
                            && $0.status != .declined }
        invites.append(invite)
    }

    func setStatus(_ status: Status, for id: UUID) {
        guard let idx = invites.firstIndex(where: { $0.id == id }) else { return }
        invites[idx].status = status
        invites[idx].decidedAt = (status == .pending) ? nil : Date()
    }

    func invitesForChat(_ name: String) -> [Invite] {
        invites
            .filter { $0.inviteeName == name }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// 整個約球被取消時:把所有 active(pending/accepted)邀請改 declined。
    /// 不在 store 內處理 match 數據回滾,呼叫方自己管 acceptedInvite 的副作用。
    func expireAll(matchID: UUID) {
        for i in invites.indices where invites[i].matchID == matchID
                                    && invites[i].status != .declined {
            invites[i].status = .declined
            invites[i].decidedAt = Date()
        }
    }
}

// MARK: - Display State

enum InviteCardDisplay: Equatable {
    case actionable(hasConflict: Bool, conflictLabel: String?)
    case accepted(at: Date)
    case declined(at: Date)
    case expired(reason: ExpireReason)

    enum ExpireReason: Equatable {
        case full(current: Int, max: Int)
        case cancelled
        case timePassed
    }

    var isDecided: Bool {
        switch self {
        case .accepted, .declined: return true
        default: return false
        }
    }

    var isMuted: Bool {
        switch self {
        case .actionable: return false
        default: return true
        }
    }
}

// MARK: - Match Actions Bridge

/// HomeView 提供給 ChatDetailView 的回調集 — 解耦 chat 與 match state。
struct InviteMatchActions {
    var acceptInvite: (InviteStore.Invite) -> Void
    var undoAcceptInvite: (InviteStore.Invite) -> Void

    static var noop: InviteMatchActions {
        InviteMatchActions(
            acceptInvite: { _ in },
            undoAcceptInvite: { _ in }
        )
    }
}
```

注意:`OutgoingInvitationPayload` / `Gender` 都已是 internal 全局可見類型,直接引用即可。

- [ ] **Step 2: 把新文件加進 Xcode project**

確認:

```bash
grep InviteStore TennisMatch.xcodeproj/project.pbxproj | head -3
```

如無匹配,在 Xcode 裡:右鍵 `Models` group → Add Files to TennisMatch → 選 `InviteStore.swift`。

- [ ] **Step 3: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Models/InviteStore.swift TennisMatch.xcodeproj/project.pbxproj
git commit -m "$(cat <<'EOF'
feat(models): add InviteStore for interactive DM invites

@Observable store + Invite struct + InviteCardDisplay 派生函數類型 +
InviteMatchActions closures struct。本任務不改既有文件,只是把全部新類型落地;
後續 task 接駁渲染與互動。
EOF
)"
```

---

### Task 4: 注入 `InviteStore` 到 `TennisMatchApp` + Previews

**Files:**
- Modify: `TennisMatch/TennisMatchApp.swift`
- Modify: `TennisMatch/Views/HomeView.swift`(2 處 PreviewProvider)
- Modify: `TennisMatch/Views/MyMatchesView.swift`(若有 Preview)
- Modify: `TennisMatch/Views/ChatDetailView.swift`(若有 Preview)
- Modify: `TennisMatch/Views/MessagesView.swift`(若有 Preview)

**Why:** Spec §「改動文件清單」— 對齊 BookingStore / FollowStore 的注入模式。

- [ ] **Step 1: 在 `TennisMatchApp.swift` 加 store 屬性 + .environment**

`TennisMatchApp.swift` line 14-20 現有 7 個 store,加 inviteStore:

```swift
@State private var followStore = FollowStore()
@State private var userStore = UserStore()
@State private var bookingStore = BookingStore()
@State private var notificationStore = NotificationStore()
@State private var creditScoreStore = CreditScoreStore()
@State private var ratingFeedbackStore = RatingFeedbackStore()
@State private var tournamentStore = TournamentStore()
@State private var inviteStore = InviteStore()
```

line 42-48 現有 7 個 .environment,加一行:

```swift
.environment(followStore)
.environment(userStore)
.environment(bookingStore)
.environment(notificationStore)
.environment(creditScoreStore)
.environment(ratingFeedbackStore)
.environment(tournamentStore)
.environment(inviteStore)
```

- [ ] **Step 2: 找出所有 PreviewProvider 補 `.environment(InviteStore())`**

```bash
grep -rn "\.environment(BookingStore())\|\.environment(FollowStore())" TennisMatch/Views | head -20
```

對每個出現 `.environment(BookingStore())` 的 PreviewProvider(HomeView 約 line 859-868、MyMatchesView 約 line 2024/2032、若 MessagesView/ChatDetailView 有 preview 同),在那塊 `.environment(...)` 鏈尾追加:

```swift
.environment(InviteStore())
```

- [ ] **Step 3: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`(尚無人讀 inviteStore,僅注入,不影響運行)。

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/TennisMatchApp.swift TennisMatch/Views/HomeView.swift TennisMatch/Views/MyMatchesView.swift TennisMatch/Views/MessagesView.swift TennisMatch/Views/ChatDetailView.swift
git commit -m "feat(app): 注入 InviteStore 到 environment chain

對齊 BookingStore/FollowStore 既有模式。所有 PreviewProvider 同步補上,
讓 SwiftUI 預覽不會因缺 environment 崩。"
```

---

### Task 5: 上提 `upcomingMatches` 從 `MyMatchesView` 到 `HomeView`

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift`
- Modify: `TennisMatch/Views/HomeView.swift`

**Why:** Spec §「MyMatchesView 變更」最後一段 — 讓 HomeView 的 acceptInvite/undoAcceptInvite closures 能直接寫,而不必用 SwiftUI 不擅長的「父推子」回調。

- [ ] **Step 1: HomeView 加 `@State` 持 upcomingMatches**

`HomeView.swift` line 36 附近(在 `matches` 旁):

```swift
@State private var matches: [MockMatch] = initialMockMatches
@State private var upcomingMatches: [MyMatchItem] = mockUpcomingMatchesInitial
```

- [ ] **Step 2: MyMatchesView 把 `@State upcomingMatches` 改 `@Binding`**

`MyMatchesView.swift` line 52,刪除:

```swift
@State private var upcomingMatches: [MyMatchItem] = mockUpcomingMatchesInitial
```

換成:

```swift
@Binding var upcomingMatches: [MyMatchItem]
```

放在 line 11 的 `@Binding var sharedChats: [MockChat]` 旁邊(讓 binding 集中)。

- [ ] **Step 3: HomeView 調用 `MyMatchesView` 時傳 binding**

`HomeView.swift` line 60-74 現有調用:

```swift
case 1: MyMatchesView(
    sharedChats: $sharedChats,
    upcomingMatches: $upcomingMatches,
    onGoHome: { selectedTab = 0 },
    onGoTournaments: { showTournaments = true },
    onMatchCancelled: { payload in
        handleMyMatchCancellation(payload)
    },
    onInviteAccepted: { _, _, sourceMatchID in
        guard let id = sourceMatchID,
              let idx = matches.firstIndex(where: { $0.id == id })
        else { return }
        matches[idx].currentPlayers += 1
    }
)
```

(本 task 暫時保留 `onInviteAccepted`;Task 9 會刪。)

- [ ] **Step 4: 同步 Preview 調用點**

`MyMatchesView.swift` line 2024 / 2032 兩處:

```swift
MyMatchesView(sharedChats: .constant([]), upcomingMatches: .constant([]))
```

- [ ] **Step 5: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 6: 模擬器冒煙 — 確認沒回退**

Xcode `⌘R`(iPhone 16 sim):
1. 我的約球 → 即將到來 → 看到所有原 mock 約球
2. 點任一管理 → 取消約球 → 該卡消失,首頁同步更新
3. 切到首頁、再切回我的約球 → 取消的不再出現(現有 cancelledMockKeysJSON 持久仍生效)

Expected: 行為與 PR #21 一致。

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/HomeView.swift TennisMatch/Views/MyMatchesView.swift
git commit -m "$(cat <<'EOF'
refactor: 上提 upcomingMatches 到 HomeView

從 MyMatchesView.@State 移到 HomeView.@State + @Binding 傳回。
為下一個 task「acceptInvite/undoAcceptInvite closures 直接寫
upcomingMatches」鋪路,避免 SwiftUI 不擅長的父推子回調鏈。
PreviewProvider 同步補上 .constant([])。本任務保留 onInviteAccepted,
下一輪 task 會刪。
EOF
)"
```

---

### Task 6: 加 `BubbleContent.dmInvitation` case + 在 ChatDetailView 注入 InviteStore + 渲染骨架

**Files:**
- Modify: `TennisMatch/Views/ChatDetailView.swift`

**Why:** Spec §「BubbleContent 變更」+ §「邀請卡渲染」骨架。本 task 只接 InviteStore 並讓邀請出現在聊天裡(無互動,純 placeholder 卡),Task 7 補 actionRow + 互動。

- [ ] **Step 1: BubbleContent 加 case**

`ChatDetailView.swift` line 720 附近(`enum BubbleContent`):

```swift
enum BubbleContent {
    case incoming(String)
    case outgoing(String)
    case outgoingImage(Data)
    case invitation(date: String, location: String, startDate: Date, endDate: Date)
    case outgoingInvitation(OutgoingInvitationPayload)
    case dmInvitation(UUID)         // ← 新增,UUID = InviteStore.Invite.id
    case systemMessage(String)
}
```

- [ ] **Step 2: ChatDetailView 注入 InviteStore + matchLookup closure 參數**

`ChatDetailView.swift` line 32-47 區塊。在 `@Environment(BookingStore.self)` 旁加:

```swift
@Environment(InviteStore.self) private var inviteStore
```

並在 var 屬性區尾(現有 `var pendingInvitation` / `var onInviteResolved` 即將被刪,但本 task 先放著)加:

```swift
/// 由 HomeView 提供,讓 actionRow 能查詢「該約球當前的 (current, max) / 是否取消」。
/// nil → 視為已取消(渲染 .expired(.cancelled))。
var matchLookup: (UUID) -> MyMatchItem? = { _ in nil }
/// 接受/反悔的副作用 — 由 HomeView 寫 upcomingMatches/matches。
var matchActions: InviteMatchActions = .noop
```

- [ ] **Step 3: `allMessages` 合併 InviteStore 條目**

`ChatDetailView.swift` line 118-142 現有:

```swift
private var allMessages: [ChatBubble] {
    var messages: [ChatBubble] = []
    if let context = matchContext {
        if !matchContextDismissed {
            messages.append(ChatBubble(.systemMessage(context)))
        }
    } else {
        for msg in mockMessages {
            messages.append(msg)
            if case .invitation(let date, let location, _, _) = msg.content,
               isInvitationAccepted(date: date, location: location) {
                messages.append(ChatBubble(
                    .systemMessage("🎾 約球已確認！\(date) 在\(location)，記得準時到達！")
                ))
            }
        }
    }
    messages.append(contentsOf: sentMessages)
    return messages
}
```

改成在 `messages.append(contentsOf: sentMessages)` **之後**加:

```swift
    messages.append(contentsOf: sentMessages)

    // DM 邀請卡 — 從 InviteStore 動態合併,讓接受/拒絕/反悔即時反映
    if case .personal(let name, _, _) = chat.type {
        for invite in inviteStore.invitesForChat(name) {
            let ts = AppDateFormatter.hourMinute.string(from: invite.createdAt)
            messages.append(ChatBubble(.dmInvitation(invite.id), timestamp: ts))
        }
    }

    return messages
}
```

- [ ] **Step 4: `messageView` switch 加 `.dmInvitation` 路由(暫 placeholder)**

`ChatDetailView.swift` line 302-331 的 `messageView`,在 `.outgoingInvitation` 後加:

```swift
case .dmInvitation(let inviteID):
    dmInvitationCard(inviteID: inviteID)
```

- [ ] **Step 5: 加 `dmInvitationCard` 骨架**

緊接 `outgoingInvitationCard(...)` 之後(用 `grep -n "outgoingInvitationCard" ChatDetailView.swift` 找),加:

```swift
// MARK: - DM Invitation Card (interactive)

@ViewBuilder
private func dmInvitationCard(inviteID: UUID) -> some View {
    if let invite = inviteStore.invites.first(where: { $0.id == inviteID }) {
        let match = matchLookup(invite.matchID)
        let busy = MockFriendSchedule.conflict(
            for: invite.inviteeName,
            start: invite.startDate,
            end: invite.endDate
        )
        let display = displayState(for: invite, match: match, friendBusy: busy)

        VStack(spacing: 0) {
            // 衝突警告條(僅 actionable + hasConflict)
            if case .actionable(true, let label?) = display {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("\(invite.inviteeName)那時段已有\(label)")
                }
                .font(Typography.small)
                .foregroundColor(Theme.warning)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.sm)
                .background(Theme.warningBg)
            }

            // 主體
            VStack(alignment: .leading, spacing: 6) {
                Text("🎾 約球邀請")
                    .font(Typography.captionMedium)
                    .foregroundColor(Theme.textSecondary)
                Text(invite.payload.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("📅 \(invite.payload.dateLabel) \(invite.payload.timeRange)")
                    .font(Typography.fieldLabel)
                    .foregroundColor(Theme.textBody)
                Text("📍 \(invite.payload.location)")
                    .font(Typography.fieldLabel)
                    .foregroundColor(Theme.textBody)
                Text("👥 \(invite.payload.players)")
                    .font(Typography.fieldLabel)
                    .foregroundColor(Theme.textBody)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)

            Divider()

            // 動作區 — Task 7 補完整;本 task 僅 placeholder
            Text("(actions)")
                .font(Typography.small)
                .foregroundColor(Theme.textHint)
                .padding(Spacing.sm)
        }
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.inputBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, Spacing.md)
        .opacity(display.isMuted ? 0.7 : 1.0)
    }
}

// MARK: - Display State Derivation

private func displayState(for invite: InviteStore.Invite,
                          match: MyMatchItem?,
                          friendBusy: FriendBusySlot?) -> InviteCardDisplay {
    switch invite.status {
    case .accepted:
        return .accepted(at: invite.decidedAt ?? invite.createdAt)
    case .declined:
        return .declined(at: invite.decidedAt ?? invite.createdAt)
    case .pending:
        guard let m = match else {
            return .expired(reason: .cancelled)
        }
        if m.startDate < Date() {
            return .expired(reason: .timePassed)
        }
        let (cur, mx) = m.playerCounts
        if cur >= mx {
            return .expired(reason: .full(current: cur, max: mx))
        }
        return .actionable(
            hasConflict: friendBusy != nil,
            conflictLabel: friendBusy?.label
        )
    }
}
```

注意 `Theme.warning` / `Theme.warningBg`:在現有 Theme 中可能用 `Theme.creditDeducted` / 黃色相關 token。如不存在,先用 `Color.orange` / `Color.orange.opacity(0.1)` 占位,Task 7 末尾的 design polish step 統一替換成 Theme token。

- [ ] **Step 6: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build 2>&1 | grep -E "error:" | head -20
```

Expected: 沒有 `error:` 或只有 `Theme.warning` / `Theme.warningBg` 找不到的 — 那兩處改用 `Color.orange` / `Color.orange.opacity(0.15)` 占位。改完再編譯一次,Expected `BUILD SUCCEEDED`。

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/ChatDetailView.swift
git commit -m "$(cat <<'EOF'
feat(chat): dmInvitation bubble + 渲染骨架

- BubbleContent 新增 .dmInvitation(UUID) case,UUID 對 InviteStore.Invite.id
- ChatDetailView 注入 InviteStore + matchLookup/matchActions 兩個新參數
- allMessages 合併 InviteStore.invitesForChat(...) 條目
- dmInvitationCard 骨架:衝突警告條 + 主體資訊;動作區仍是 placeholder
- displayState 派生函數:accepted/declined/expired/actionable 四種狀態
EOF
)"
```

---

### Task 7: 完成 `dmInvitationCard` 的 actionRow + 互動 handler + Undo confirmationDialog

**Files:**
- Modify: `TennisMatch/Views/ChatDetailView.swift`

**Why:** Spec §「邀請卡渲染」的 actionRow + Spec §「接受 / 拒絕 / 反悔 處理」+ §「Undo confirmation」。

- [ ] **Step 1: 加 `@State undoTarget` + `actionRow` view builder**

`ChatDetailView.swift` 在現有 `@State private var lastHandledInvitationID` 旁(line 67 附近)加:

```swift
/// 點已決定的灰卡 → confirmationDialog 詢問是否撤回。
@State private var undoTarget: InviteStore.Invite?
```

把 Task 6 的 `Text("(actions)")` placeholder 替換為呼叫 actionRow:

```swift
Divider()
actionRow(invite: invite, display: display)
```

並在 `dmInvitationCard` 函數**之後**加 `actionRow`:

```swift
@ViewBuilder
private func actionRow(invite: InviteStore.Invite,
                       display: InviteCardDisplay) -> some View {
    switch display {
    case .actionable:
        HStack(spacing: Spacing.sm) {
            Button {
                handleDecline(invite)
            } label: {
                Text("拒絕")
                    .font(Typography.bodyMedium)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.bordered)

            Button {
                handleAccept(invite)
            } label: {
                Text("接受")
                    .font(Typography.bodyMedium)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.primary)
        }
        .padding(Spacing.sm)

    case .accepted(let at):
        decidedRow(
            text: "✅ \(invite.inviteeName)已接受 · \(AppDateFormatter.hourMinute.string(from: at))",
            color: Theme.accentGreen,
            invite: invite
        )

    case .declined(let at):
        decidedRow(
            text: "❌ \(invite.inviteeName)已拒絕 · \(AppDateFormatter.hourMinute.string(from: at))",
            color: Theme.textSecondary,
            invite: invite
        )

    case .expired(let reason):
        Text(expiredText(reason))
            .font(Typography.smallMedium)
            .foregroundColor(Theme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .center)
            .padding(Spacing.sm)
    }
}

private func decidedRow(text: String,
                        color: Color,
                        invite: InviteStore.Invite) -> some View {
    Button {
        undoTarget = invite
    } label: {
        HStack {
            Text(text)
                .font(Typography.smallMedium)
                .foregroundColor(color)
            Spacer()
            Text("撤回")
                .font(Typography.small)
                .foregroundColor(Theme.textHint)
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 11))
                .foregroundColor(Theme.textHint)
        }
        .padding(Spacing.sm)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
}

private func expiredText(_ reason: InviteCardDisplay.ExpireReason) -> String {
    switch reason {
    case .full(let cur, let mx):
        return "🎾 已約到球友 (\(cur)/\(mx))"
    case .cancelled:
        return "約球已取消"
    case .timePassed:
        return "已過開賽時間"
    }
}
```

- [ ] **Step 2: 加三個 handler — accept / decline / undo**

`ChatDetailView.swift` 在 `actionRow` 之後加:

```swift
// MARK: - DM Invite Handlers

private func handleAccept(_ invite: InviteStore.Invite) {
    inviteStore.setStatus(.accepted, for: invite.id)
    matchActions.acceptInvite(invite)
    sentMessages.append(ChatBubble(.systemMessage(
        "🎾 約球已確認！\(invite.payload.dateLabel) 在\(invite.payload.location)"
    )))
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}

private func handleDecline(_ invite: InviteStore.Invite) {
    inviteStore.setStatus(.declined, for: invite.id)
    sentMessages.append(ChatBubble(.systemMessage(
        "\(invite.inviteeName)婉拒了邀請"
    )))
}

private func handleUndo(_ invite: InviteStore.Invite) {
    let was = invite.status
    inviteStore.setStatus(.pending, for: invite.id)
    if was == .accepted {
        matchActions.undoAcceptInvite(invite)
    }
    // Undo Decline 純狀態翻轉,無副作用。
}
```

- [ ] **Step 3: 加 Undo confirmationDialog binding 與 modifier**

`ChatDetailView.swift` body 末尾(現有 `.task(id: pendingInvitation?.matchID)` 上方,大約 line 265 附近)加:

```swift
.confirmationDialog(
    Text(undoTarget.map { "撤回\($0.inviteeName)的決定?" } ?? ""),
    isPresented: Binding(
        get: { undoTarget != nil },
        set: { if !$0 { undoTarget = nil } }
    ),
    presenting: undoTarget
) { invite in
    Button("撤回", role: .destructive) {
        handleUndo(invite)
    }
    Button("取消", role: .cancel) {}
} message: { invite in
    Text(invite.status == .accepted
         ? "撤回後,該球友將從報名列表移除,約球可能恢復至「招募中」"
         : "撤回後,可重新讓該球友考慮")
}
```

- [ ] **Step 4: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Views/ChatDetailView.swift
git commit -m "$(cat <<'EOF'
feat(chat): DM 邀請卡互動 + Undo

- actionRow:四種 display 各自渲染(可接受按鈕 / 已接受灰行 / 已拒絕灰行 /
  已過期 lock 行);已決定的灰行整行可點 → 觸發 Undo confirmationDialog
- handleAccept:寫 InviteStore + matchActions.acceptInvite + 系統消息 + 觸覺
- handleDecline:寫 InviteStore + 系統消息
- handleUndo:setStatus(.pending),Accept 路徑額外回滾 match 副作用
- confirmationDialog 顯示「撤回 XX 的決定?」,文案依 status 區分
EOF
)"
```

---

### Task 8: MyMatchesView 改寫 `handleInvitePicked` 寫 InviteStore;刪除 PR #21 scaffold;加 cancel-time expireAll

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift`

**Why:** Spec §「MyMatchesView 變更」:換成新模型寫入 InviteStore;移除 1.6s 模擬支援代碼。

- [ ] **Step 1: 注入 InviteStore**

`MyMatchesView.swift` line 23 附近(`@Environment(BookingStore.self)` 旁):

```swift
@Environment(InviteStore.self) private var inviteStore
```

- [ ] **Step 2: 刪除 `pendingInvitation` @State 與 `handleInviteResolved` 函數**

刪除 line 60-62:

```swift
@State private var pendingInvitation: PendingDMInvitation?
```

刪除整個 line 250-300 的 `handleInviteResolved` 函數。

- [ ] **Step 3: 改寫 `handleInvitePicked` 寫入 InviteStore**

`MyMatchesView.swift` line 188-248 整段替換成:

```swift
private func handleInvitePicked(player: FollowPlayer, target: InviteTarget) {
    // 找/建 chat with player(沿用既有邏輯)
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

    // 約球邀請寫入 InviteStore;賽事邀請仍走舊 matchContext 字串路徑(本次不改)
    if case .match(let id, let title, let dateLabel, let timeRange, let location, let players) = target,
       let item = upcomingMatches.first(where: { $0.id == id }) {
        let invite = InviteStore.Invite(
            id: UUID(),
            matchID: id,
            inviteeName: player.name,
            inviteeGender: player.gender,
            inviteeNTRP: player.ntrp,
            payload: OutgoingInvitationPayload(
                title: title,
                dateLabel: dateLabel,
                timeRange: timeRange,
                location: location,
                players: players
            ),
            startDate: item.startDate,
            endDate: item.endDate,
            status: .pending,
            decidedAt: nil,
            createdAt: Date()
        )
        inviteStore.add(invite)
        toast = .init(kind: .success, text: L10n.string("邀請已發送給 \(player.name)"))
        // 不再自動進入聊天 — 用戶從「聊天」tab 進入查看,符合「自動生成新對話框」需求
    } else {
        // 賽事/兜底 — 保留舊提示與 selectedChatMatchContext
        selectedChatMatchContext = target.chatContext
        selectedChat = chat
        toast = .init(kind: .success, text: L10n.string("已為你開啟與 \(player.name) 的私信"))
    }
}
```

- [ ] **Step 4: ChatDetailView 調用點移除舊參數,加新參數**

`MyMatchesView.swift` line 390-403 現有:

```swift
.navigationDestination(item: $selectedChat) { chat in
    ChatDetailView(
        chat: chat,
        matchContext: selectedChatMatchContext,
        pendingInvitation: pendingInvitation,
        onInviteResolved: handleInviteResolved
    )
    .onDisappear {
        selectedChatMatchContext = nil
        pendingInvitation = nil
    }
}
```

改成:

```swift
.navigationDestination(item: $selectedChat) { chat in
    ChatDetailView(
        chat: chat,
        matchContext: selectedChatMatchContext,
        matchLookup: { id in upcomingMatches.first(where: { $0.id == id }) },
        matchActions: makeInviteActions()
    )
    .onDisappear { selectedChatMatchContext = nil }
}
```

- [ ] **Step 5: 加 `makeInviteActions()` helper(MyMatchesView 內,acceptInvite/undo 都直接寫 binding `upcomingMatches`)**

`MyMatchesView.swift` 在 `handleInvitePicked` 之後:

```swift
private func makeInviteActions() -> InviteMatchActions {
    InviteMatchActions(
        acceptInvite: { invite in
            applyInviteAccept(invite)
        },
        undoAcceptInvite: { invite in
            applyInviteUndoAccept(invite)
        }
    )
}

/// 接受 invite 的副作用:registrants +1,players 字串 +1,滿員時 status 升 .confirmed,
/// 滿員時注冊到 BookingStore.externalSlots(避免用戶在離開重進前報名到衝突時段)。
private func applyInviteAccept(_ invite: InviteStore.Invite) {
    guard let idx = upcomingMatches.firstIndex(where: { $0.id == invite.matchID }) else { return }
    var match = upcomingMatches[idx]
    guard !match.registrants.contains(where: { $0.name == invite.inviteeName }) else { return }

    match.registrants.append(MatchRegistrant(
        name: invite.inviteeName,
        gender: invite.inviteeGender,
        ntrp: invite.inviteeNTRP,
        isOrganizer: false
    ))
    let (cur, mx) = match.playerCounts
    let newCurrent = cur + 1
    let ntrpRange = match.players.components(separatedBy: "NTRP ").last ?? ""
    match.players = "\(newCurrent)/\(mx) · NTRP \(ntrpRange)"

    if newCurrent >= mx {
        match.status = .confirmed
        let label = "\(match.title) \(match.dateLabel) \(match.timeRange)"
        bookingStore.registerExternal(BookedSlot(
            id: match.id,
            start: match.startDate,
            end: match.endDate,
            label: label
        ))
    }
    upcomingMatches[idx] = match

    // 通知 HomeView 同步 currentPlayers(下一個 task 在 HomeView 接)
    onInviteAccepted?(invite.matchID, FollowPlayer.from(invite: invite), match.sourceMatchID)
}

/// Undo Accept 的副作用:remove registrant,players -1,若原本滿員則 status 回 .pending,
/// 若有 sourceMatchID 通知 HomeView 同步 currentPlayers -1。
private func applyInviteUndoAccept(_ invite: InviteStore.Invite) {
    guard let idx = upcomingMatches.firstIndex(where: { $0.id == invite.matchID }) else { return }
    var match = upcomingMatches[idx]
    guard let rIdx = match.registrants.firstIndex(where: { $0.name == invite.inviteeName }) else { return }

    match.registrants.remove(at: rIdx)
    let (cur, mx) = match.playerCounts
    let newCurrent = max(0, cur - 1)
    let ntrpRange = match.players.components(separatedBy: "NTRP ").last ?? ""
    match.players = "\(newCurrent)/\(mx) · NTRP \(ntrpRange)"

    // 撤回後若曾經滿員 → 退回 pending,並從 BookingStore.externalSlots 移除
    if cur >= mx {
        match.status = .pending
        bookingStore.unregisterExternal(id: match.id)
    }
    upcomingMatches[idx] = match

    onInviteAccepted?(invite.matchID, FollowPlayer.from(invite: invite), match.sourceMatchID)
    // 注意:onInviteAccepted 在 Task 9 會被 -1 版本替代;本 task 暫保。
}
```

注意:`bookingStore.unregisterExternal(id:)` 是新 API;檢查 `BookingStore` 是否已有(`grep "unregisterExternal\|removeExternal" TennisMatch/Models/BookingStore.swift`)。如無:

```bash
grep -n "registerExternal\|externalSlots" TennisMatch/Models/BookingStore.swift
```

如果只有 register 沒有 unregister,**先加**:

```swift
func unregisterExternal(id: UUID) {
    externalSlots.removeAll { $0.id == id }
}
```

放在 `registerExternal` 之後。

- [ ] **Step 6: 加 `FollowPlayer.from(invite:)` extension**

`Components/InvitePickerSheet.swift` 末尾(或新檔 `Models/FollowPlayer+Invite.swift`):

```swift
extension FollowPlayer {
    static func from(invite: InviteStore.Invite) -> FollowPlayer {
        FollowPlayer(
            name: invite.inviteeName,
            gender: invite.inviteeGender,
            ntrp: invite.inviteeNTRP,
            latestActivity: ""    // onInviteAccepted 不用這欄,留空即可
        )
    }
}
```

(檢查 `FollowPlayer` 構造簽名:`grep -n "struct FollowPlayer\|init.*name.*gender.*ntrp" TennisMatch/Components/InvitePickerSheet.swift`,根據實際參數調整。如有 `id` 字段,加 `id: UUID()`。)

- [ ] **Step 7: cancel 流程加 expireAll**

`MyMatchesView.swift` line 408-436 的 `Button("確認取消", role: .destructive)` 內 closure,在 `upcomingMatches.removeAll { $0.id == match.id }` **後面**加:

```swift
upcomingMatches.removeAll { $0.id == match.id }
inviteStore.expireAll(matchID: match.id)    // ← 新增
```

- [ ] **Step 8: 刪除 PendingDMInvitation 引用 + import**

確認 MyMatchesView 已無 `PendingDMInvitation` 引用:

```bash
grep -n "PendingDMInvitation" TennisMatch/Views/MyMatchesView.swift
```

Expected: 0 matches。

- [ ] **Step 9: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。可能會有 `Theme.warning` 警告(Task 6 step 6 的 fallback)— 暫忽略。

- [ ] **Step 10: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift TennisMatch/Models/BookingStore.swift TennisMatch/Components/InvitePickerSheet.swift
git commit -m "$(cat <<'EOF'
feat(my-matches): 邀請寫入 InviteStore + 移除 1.6s scaffold

- handleInvitePicked 改為構造 InviteStore.Invite + add(...);不再自動進入
  聊天,用戶從「聊天」tab 自己點進對話框查看互動卡
- 刪除 pendingInvitation/handleInviteResolved/ChatDetailView 舊參數
- makeInviteActions:provide acceptInvite/undoAcceptInvite closures
  給 ChatDetailView,直接寫 upcomingMatches binding
- applyInviteAccept:registrants +1, players +1, 滿員 status .confirmed +
  bookingStore.registerExternal
- applyInviteUndoAccept:相反方向,滿員回退時 unregisterExternal
- BookingStore.unregisterExternal 新 API
- cancel 約球時呼叫 inviteStore.expireAll(matchID:)
EOF
)"
```

---

### Task 9: HomeView 接 InviteStore + 同步 MockMatch.currentPlayers + 透傳 matchActions 到 MessagesView

**Files:**
- Modify: `TennisMatch/Views/HomeView.swift`
- Modify: `TennisMatch/Views/MessagesView.swift`

**Why:** Spec §「HomeView 改造」+ MessagesView 透傳 — 讓「聊天」tab 進去的 ChatDetailView 也能拿到 matchActions,並讓 HomeView 接收 invite 接受時同步首頁 currentPlayers。

- [ ] **Step 1: HomeView 注入 InviteStore + matchLookup helper**

`HomeView.swift` line 14-17 旁加:

```swift
@Environment(InviteStore.self) private var inviteStore
```

- [ ] **Step 2: HomeView 提供 makeMessagesActions() helper**

在 HomeView body 之外、private extension 內或同檔末尾加:

```swift
private func makeMessagesActions() -> InviteMatchActions {
    InviteMatchActions(
        acceptInvite: { invite in
            applyInviteAcceptInHome(invite)
        },
        undoAcceptInvite: { invite in
            applyInviteUndoAcceptInHome(invite)
        }
    )
}

/// 用戶從「聊天」tab 接受邀請時的 home 端副作用 —— 同步寫 upcomingMatches
/// 與首頁 matches.currentPlayers,行為與 MyMatchesView.applyInviteAccept 對齊。
private func applyInviteAcceptInHome(_ invite: InviteStore.Invite) {
    guard let idx = upcomingMatches.firstIndex(where: { $0.id == invite.matchID }) else { return }
    var match = upcomingMatches[idx]
    guard !match.registrants.contains(where: { $0.name == invite.inviteeName }) else { return }
    match.registrants.append(MatchRegistrant(
        name: invite.inviteeName,
        gender: invite.inviteeGender,
        ntrp: invite.inviteeNTRP,
        isOrganizer: false
    ))
    let (cur, mx) = match.playerCounts
    let newCurrent = cur + 1
    let ntrpRange = match.players.components(separatedBy: "NTRP ").last ?? ""
    match.players = "\(newCurrent)/\(mx) · NTRP \(ntrpRange)"
    if newCurrent >= mx {
        match.status = .confirmed
        let label = "\(match.title) \(match.dateLabel) \(match.timeRange)"
        bookingStore.registerExternal(BookedSlot(
            id: match.id,
            start: match.startDate,
            end: match.endDate,
            label: label
        ))
    }
    upcomingMatches[idx] = match

    // 同步首頁 MockMatch.currentPlayers
    if let src = match.sourceMatchID,
       let mIdx = matches.firstIndex(where: { $0.id == src }) {
        matches[mIdx].currentPlayers += 1
    }
}

private func applyInviteUndoAcceptInHome(_ invite: InviteStore.Invite) {
    guard let idx = upcomingMatches.firstIndex(where: { $0.id == invite.matchID }) else { return }
    var match = upcomingMatches[idx]
    guard let rIdx = match.registrants.firstIndex(where: { $0.name == invite.inviteeName }) else { return }
    match.registrants.remove(at: rIdx)
    let (cur, mx) = match.playerCounts
    let newCurrent = max(0, cur - 1)
    let ntrpRange = match.players.components(separatedBy: "NTRP ").last ?? ""
    match.players = "\(newCurrent)/\(mx) · NTRP \(ntrpRange)"
    if cur >= mx {
        match.status = .pending
        bookingStore.unregisterExternal(id: match.id)
    }
    upcomingMatches[idx] = match

    if let src = match.sourceMatchID,
       let mIdx = matches.firstIndex(where: { $0.id == src }),
       matches[mIdx].currentPlayers > 0 {
        matches[mIdx].currentPlayers -= 1
    }
}
```

- [ ] **Step 3: 注意:`applyInviteAcceptInHome` 與 `MyMatchesView.applyInviteAccept` 邏輯重複了**

這是有意的:用戶可能從「我的約球 → 管理 → 私信邀請」進去聊天接受(走 MyMatchesView 路徑),也可能從「聊天」tab 直接點對話進去接受(走 HomeView 路徑)。

**避免重複的辦法**:把 `applyInviteAccept` 抽成 `InviteStore` 的 method(讓 InviteStore 持 `upcomingMatches: () -> [MyMatchItem]` / `mutateUpcoming: ([MyMatchItem]) -> Void` 回調)。**本 plan 不抽**,留作後續 refactor — 兩處重複容易 spot,且 SwiftUI source-of-truth 偏好「state 在哪裡 mutation 就在哪裡」。

不需要寫代碼;這是設計說明。

- [ ] **Step 4: 修改 `MessagesView` 加 `matchActions` 參數**

先看現狀:

```bash
grep -n "struct MessagesView\|var totalUnread\|var chats" TennisMatch/Views/MessagesView.swift | head -5
```

在 `MessagesView` 的 `var chats: Binding<[MockChat]>` 旁加:

```swift
var matchActions: InviteMatchActions = .noop
var matchLookup: (UUID) -> MyMatchItem? = { _ in nil }
```

並在 `MessagesView` body 內 `ChatDetailView(...)` 呼叫處(grep `"ChatDetailView" TennisMatch/Views/MessagesView.swift`)補兩個參數:

```swift
ChatDetailView(
    chat: chat,
    // ... 既有參數 ...
    matchLookup: matchLookup,
    matchActions: matchActions
)
```

- [ ] **Step 5: HomeView 調用 MessagesView 時傳 matchActions + matchLookup**

`HomeView.swift` line 76:

```swift
case 3: MessagesView(
    totalUnread: $chatUnreadCount,
    chats: $sharedChats,
    matchActions: makeMessagesActions(),
    matchLookup: { id in upcomingMatches.first(where: { $0.id == id }) }
)
```

- [ ] **Step 6: 刪除 HomeView 舊的 `onInviteAccepted` callback**

`HomeView.swift` line 60-74:

```swift
case 1: MyMatchesView(
    sharedChats: $sharedChats,
    upcomingMatches: $upcomingMatches,
    onGoHome: { selectedTab = 0 },
    onGoTournaments: { showTournaments = true },
    onMatchCancelled: { payload in
        handleMyMatchCancellation(payload)
    },
    onInviteAccepted: { matchID, friend, sourceMatchID in
        // 種子假資料無 sourceMatchID → 首頁無對應 MockMatch,no-op
        guard let id = sourceMatchID,
              let idx = matches.firstIndex(where: { $0.id == id })
        else { return }
        if friend.name.isEmpty {
            // Undo:friend.name 為空時當 -1 處理(MyMatchesView Task 8 約定)
            if matches[idx].currentPlayers > 0 { matches[idx].currentPlayers -= 1 }
        } else {
            matches[idx].currentPlayers += 1
        }
    }
)
```

`onInviteAccepted` 仍保留,因為 `MyMatchesView.applyInviteAccept`/`applyInviteUndoAccept` 在 Task 8 仍呼叫它。**但**:Task 8 用同一 callback 實現「+1/−1」可能含糊;改為兩個 closure 更乾淨。

**簡化方案**:乾脆讓 MyMatchesView 不再呼叫 `onInviteAccepted`,而是 HomeView 在 acceptInvite 路徑統一同步首頁 — **但 MyMatchesView 自己的 acceptInvite 走的是它自己 makeInviteActions(),不會經過 HomeView**。

**所以:**MyMatchesView.applyInviteAccept 仍需 callback 同步首頁。改成兩個:

`MyMatchesView` 加新 callback:

```swift
var onInviteAccepted: ((UUID, FollowPlayer, UUID?) -> Void)? = nil
var onInviteUndoAccepted: ((UUID, UUID?) -> Void)? = nil
```

`applyInviteUndoAccept` 改呼叫 `onInviteUndoAccepted?(invite.matchID, match.sourceMatchID)`(Task 8 step 5 末尾的 "Undo 走 onInviteAccepted" 改成這個)。

`HomeView` 兩個 callback 分開實現:

```swift
onInviteAccepted: { _, _, sourceMatchID in
    guard let id = sourceMatchID,
          let idx = matches.firstIndex(where: { $0.id == id }) else { return }
    matches[idx].currentPlayers += 1
},
onInviteUndoAccepted: { _, sourceMatchID in
    guard let id = sourceMatchID,
          let idx = matches.firstIndex(where: { $0.id == id }),
          matches[idx].currentPlayers > 0 else { return }
    matches[idx].currentPlayers -= 1
}
```

- [ ] **Step 7: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。如果 Step 6 改 callback 時 Task 8 已寫死成 `onInviteAccepted` 一處呼叫,需要回去改 `applyInviteUndoAccept` 改為 `onInviteUndoAccepted`。

- [ ] **Step 8: Commit**

```bash
git add TennisMatch/Views/HomeView.swift TennisMatch/Views/MessagesView.swift TennisMatch/Views/MyMatchesView.swift
git commit -m "$(cat <<'EOF'
feat(home): InviteStore 接駁 — Messages/MyMatches 兩條路徑

- HomeView 注入 InviteStore + makeMessagesActions() 提供「聊天」tab
  進去的 accept/undo closures
- applyInviteAcceptInHome / applyInviteUndoAcceptInHome:同步寫
  upcomingMatches + matches.currentPlayers + bookingStore externalSlots
- MessagesView 接 matchActions/matchLookup 兩個參數,透傳給 ChatDetailView
- MyMatchesView.onInviteAccepted/onInviteUndoAccepted 拆成兩個 callback,
  加減項清晰,首頁 currentPlayers 同步邏輯更乾淨

注意:applyInviteAccept 邏輯在 HomeView 與 MyMatchesView 重複,有意如此 ——
兩條進入路徑各自管 source-of-truth。後續可抽到 InviteStore method 統一。
EOF
)"
```

---

### Task 10: 滿員從首頁消失 — 拿掉 `!match.isOwnMatch` 例外

**Files:**
- Modify: `TennisMatch/Views/HomeView.swift`

**Why:** Spec §「滿員從首頁消失」+ 用戶確認:滿員(包括自己創的)應從首頁消失。當前 line 404 有 `if match.isFull && !match.isOwnMatch { return false }` —— 自己創的滿員不過濾。

- [ ] **Step 1: 修改 filter**

`HomeView.swift` line 404:

```swift
if match.isFull { return false }
```

(去掉 `&& !match.isOwnMatch`。)

注意:這也會讓「我發起的滿員約球」消失,符合 spec。**用戶仍能在「我的約球 → 即將到來」找到這條約球**(因為 upcomingMatches 是獨立 state,不被 home filter 影響)。

- [ ] **Step 2: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "feat(home): 滿員約球從首頁消失(包括自己發起的)

當約球 currentPlayers >= maxPlayers 時,首頁 filter 直接過濾。
原本「自己發起的滿員仍顯示」是為了讓自己看到推送進度,但配合 DM 邀請
互動後,該約球已轉到「我的約球 → 即將到來」管理,首頁無需再展示。"
```

---

### Task 11: 端到端手動測試 + L10n 自動 extract

**Files:** none(若無 bug);否則修對應文件 + `Localizable.xcstrings`(Xcode 自動)

**Why:** Spec §「驗收標準」11 項全跑。

- [ ] **Step 1: Clean build + 開模擬器**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet clean build
```

Xcode `⌘R`。

- [ ] **Step 2: 場景 1 — 邀請 + 互動接受 + 首頁同步**

1. 我的約球 → 即將到來 → 找一條「我發起的雙打 (1/4)」
2. 管理 → 私信邀請球友 → 邀王強(空閒) → 看到 toast「邀請已發送給 王強」,**不**自動進聊天
3. 聊天 tab → 王強對話 → 點進去 → 看到中央邀請卡 + `[拒絕]` `[接受]`
4. 點 `[接受]` → 卡片變灰「✅ 王強已接受 · HH:MM」+ 下方系統消息「🎾 約球已確認」+ 觸覺
5. 退回我的約球 → 該約球變 2/4

- [ ] **Step 3: 場景 2 — 衝突警告(可接受不阻擋)**

1. 重新開,我的約球找「跑馬地 (1/4) 14:00」之類的時段(對應 `MockFriendSchedule.busySlots["小美"]` 或 spec 中已對齊的)
2. 邀請小美 → 進聊天看小美對話 → 卡片頂部黃條「⚠️ 小美那時段已有 X」
3. 點 `[接受]` → 仍可接受(不阻擋)

如果衝突警告沒觸發:檢查 `MockFriendSchedule.busySlots` 與當前 mock 約球時段對齊;不對齊時加一條 slot,作為 bug 修補一同 commit。

- [ ] **Step 4: 場景 3 — 多人邀請 + 累積 + 滿員聯動**

1. 同一條雙打 (1/4) → 邀 4 個人(王強、莎拉、林叔、嘉欣)
2. 聊天 tab → 各對話顯示邀請卡(都是 `[拒絕]` `[接受]`)
3. 王強對話 → 接受 (2/4)
4. 林叔對話 → 接受 (3/4)
5. 嘉欣對話 → 接受 (4/4 滿員)
6. **首頁 → 該約球消失** ✓
7. 莎拉對話 → 卡片自動變灰「🎾 已約到球友 (4/4)」`[拒絕]` `[接受]` 已替換

- [ ] **Step 5: 場景 4 — Undo Accept 跨聊天恢復**

1. 接著場景 3 的滿員 (4/4)
2. 嘉欣對話 → 點灰卡「✅ 嘉欣已接受」→ confirmationDialog「撤回嘉欣的決定?」→ 撤回
3. 卡片變回 `[拒絕]` `[接受]` ✓
4. 我的約球 → 該約球 3/4 ✓
5. 首頁 → 該約球**重新出現** ✓
6. 莎拉對話 → 灰卡「已約到球友」**自動恢復**為 `[拒絕]` `[接受]` ✓(派生狀態的關鍵測試)

- [ ] **Step 6: 場景 5 — Undo Decline**

1. 任一對話 → 接受/拒絕後,點灰行 → confirmationDialog 文案應為「撤回後,可重新讓該球友考慮」
2. 撤回 → 卡片回到可接受狀態,**無**約球資料變更

- [ ] **Step 7: 場景 6 — Cancel 約球 → 邀請 expire**

1. 邀 1 個人,先別接受
2. 我的約球 → 該約球 → 管理 → 取消約球 → 確認取消
3. 進該球友對話 → 卡片顯示「約球已取消」灰態 ✓

- [ ] **Step 8: 場景 7 — App 重啟 → 邀請丟失**

1. 邀請若干人,部分接受
2. 模擬器 stop + 重 run
3. 聊天 tab → 邀請卡都不在 ✓(in-memory 行為)

- [ ] **Step 9: 場景 8 — 重複邀請防護**

1. 邀王強並接受
2. 同一約球再點「私信邀請球友」→ InvitePickerSheet 看到王強標灰「已報名」,不可選 ✓

- [ ] **Step 10: 場景 9 — 拒絕後可重新邀請**

1. 邀王強並 `[拒絕]`
2. 同一約球再點「私信邀請球友」→ InvitePickerSheet 王強仍可選(因 registrants 不含王強)
3. 重邀 → 王強對話多一張新卡(舊的灰卡仍在)

- [ ] **Step 11: L10n 字串 extract**

在 Xcode 中 `Product → Build` 後,Xcode 會自動更新 `Localizable.xcstrings`。打開 `TennisMatch/Localizable.xcstrings` 檢查新增的 key:

```
邀請已發送給 %@
🎾 約球邀請
%@那時段已有%@
拒絕
接受
撤回
撤回後,該球友將從報名列表移除,約球可能恢復至「招募中」
撤回後,可重新讓該球友考慮
🎾 已約到球友 (%d/%d)
約球已取消
已過開賽時間
%@婉拒了邀請
🎾 約球已確認！%@ 在%@
```

如果 Xcode auto-extract 沒抓到某條,手動補。譯文後續另開 chore commit(沿用 `742fc34` 流程)。

- [ ] **Step 12: 全部場景通過後 push**

```bash
git push -u origin feat/dm-invite-interactive
```

開 PR(可用 `commit-commands:commit-push-pr` 或手動 `gh pr create`)。

- [ ] **Step 13: 若 Step 3 / Step 6 等發現邊界 bug,修補 commit**

針對 manual smoke 發現的問題,定位 → 修 → commit,不要堆積。

---

## Self-Review

### Spec 覆蓋核對

| Spec 章節 | 對應 Task |
|---|---|
| §「數據模型」InviteStore + Invite struct + InviteMatchActions | Task 3 |
| §「BubbleContent 變更」.dmInvitation case | Task 6 step 1 |
| §「allMessages 合併 InviteStore」 | Task 6 step 3 |
| §「邀請卡渲染」骨架 + 衝突警告 | Task 6 step 5 |
| §「邀請卡渲染」actionRow 4 種狀態 | Task 7 step 1 |
| §「接受 / 拒絕 / 反悔 處理」三 handler | Task 7 step 2 |
| §「Undo confirmation」 | Task 7 step 3 |
| §「派生顯示狀態」displayState 函數 | Task 6 step 5 末尾 |
| §「MyMatchesView 變更」移除 1.6s scaffold | Task 8 step 2 |
| §「MyMatchesView 變更」InviteStore 寫入 | Task 8 step 3 |
| §「MyMatchesView 變更」makeInviteActions / applyInvite* | Task 8 step 5 |
| §「MyMatchesView 變更」cancel 加 expireAll | Task 8 step 7 |
| §「MyMatchesView 變更」upcomingMatches 上提 | Task 5 |
| §「HomeView 改造」InviteStore 注入 + makeMessagesActions | Task 9 step 1-2 |
| §「HomeView 改造」MessagesView 透傳 | Task 9 step 4-5 |
| §「HomeView 改造」matches.filter isFull | Task 10 |
| §「邊界 #1」InvitePickerSheet 禁用 + InviteStore.add 去重 | Task 3(add 去重) |
| §「邊界 #3」cancel 約球 expire | Task 8 step 7 |
| §「邊界 #5」App 重啟丟失 | Task 11 step 8 驗證 |
| §「邊界 #7」拒絕後可重新邀請 | Task 11 step 10 驗證 |
| §「本地化新字串」 | Task 11 step 11 |

無遺漏。

### Type / 命名一致性核對

- `InviteStore.Invite` — Task 3 定義,Task 6/7/8/9 引用 ✓
- `InviteCardDisplay.actionable/.accepted/.declined/.expired` — Task 3 定義,Task 6 step 5 / Task 7 step 1 引用 ✓
- `InviteCardDisplay.ExpireReason.full(current:max:)/.cancelled/.timePassed` — Task 3 / Task 7 expiredText() ✓
- `InviteMatchActions.acceptInvite / undoAcceptInvite / .noop` — Task 3 定義,Task 7/8/9 引用 ✓
- `BubbleContent.dmInvitation(UUID)` — Task 6 step 1,Task 6 step 3/4 引用 ✓
- `inviteStore.add / setStatus / invitesForChat / expireAll` — Task 3 定義,Task 7/8 全部引用 ✓
- `applyInviteAccept` / `applyInviteUndoAccept`(MyMatchesView)+ `applyInviteAcceptInHome` / `applyInviteUndoAcceptInHome`(HomeView)— 命名區分清晰 ✓
- `matchLookup: (UUID) -> MyMatchItem?` — Task 6 step 2 / Task 8 step 4 / Task 9 step 5 一致 ✓
- `onInviteAccepted` / `onInviteUndoAccepted` — Task 9 step 6 拆分,Task 8 step 5 末尾的 callback 用法已更新 ✓

### Placeholder / TODO 掃描

- Task 6 step 5 中 `Theme.warning` / `Theme.warningBg`:**已說明 fallback**(`Color.orange` / `Color.orange.opacity(0.15)`),不算占位。
- Task 8 step 5 末尾「Undo 走 onInviteAccepted」**過時陳述,Task 9 step 6 已更新為 onInviteUndoAccepted**;executor 應依 Task 9 為準。
- Task 11 步驟全是手測動作 + L10n,無代碼占位。

### 風險

| 風險 | 緩解 |
|---|---|
| `MyMatchItem` / `MatchRegistrant` 提升 internal 後,namespace 衝突 | 兩個類型都很特定(My Matches 域),不太可能撞名;編譯器會提示 |
| `upcomingMatches` 上提到 HomeView 後,初始 mock 數據(`mockUpcomingMatchesInitial`)被 hold 在 HomeView,跨 tab 切換不會重置;Task 5 step 6 manual smoke 確認 cancel 持久化仍生效 | Task 5 step 6 涵蓋 |
| `applyInviteAccept` 在 MyMatchesView 與 HomeView 兩處重複 | 故意:source-of-truth 在 upcomingMatches/matches,兩個入口路徑各自寫;後續 refactor 抽到 InviteStore.method 統一 |
| `BookingStore.unregisterExternal` 是新 API | Task 8 step 5 已加;若有測試覆蓋 BookingStore,後續補 unit test |
| Task 6 step 5 的 `Theme.warning` 不存在 | fallback `Color.orange`,Task 7 末尾若有時間再做 design polish 統一替換 |
| Xcode auto-extract 不抓帶內插的字串 (e.g. `"邀請已發送給 \(player.name)"`) | Task 11 step 11 提示手動補;PR #21 已驗 `742fc34` 流程可行 |

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-26-dm-invite-interactive.md`。兩個執行選項:

1. **Subagent-Driven(推薦)** — 派 fresh subagent 跑每個 task,任務間做兩階段 review,迭代快、上下文乾淨。
2. **Inline Execution** — 在當前 session 用 executing-plans 跑,批量執行 + checkpoint review。

哪個?
