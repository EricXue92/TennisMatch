# DM 邀請互動接受/拒絕閉環 — 設計

**日期**：2026-04-26
**作者**：XUE / Claude
**前情**：2026-04-25 spec 實作了「邀請發出後 1.6s 自動模擬好友回覆」的 demo scaffold（PR #21）。本次把它替換為**用戶可在每張邀請卡上互動點擊「接受 / 拒絕」**的真互動模型,並補上「滿員後從首頁消失 / 跨聊天聯動 / Undo」三項新行為。

## 背景

PR #21 的自動回覆滿足了「邀請閉環走得通」的最小驗收,但有三個用戶可見的硬傷:

1. **沒有真實互動**:用戶看著 1.6s 倒數,沒有可操作的按鈕,demo 感太重。
2. **跨聊天無聯動**:同一個約球邀請了 4 個人,任何一個接受不會影響其他人的聊天,沒有「已約到球友」的視覺反饋。
3. **滿員不消失**:約球滿員後仍佔據首頁列表,用戶以為還能報名。

本設計同時補齊「用戶反悔」這條路徑(Undo Accept / Undo Decline),為「demo 過程中誤點」提供退路。

## 範圍

### 包含
1. **互動邀請卡**:每張邀請以一個自定義 bubble 渲染,含 `[拒絕]` `[接受]` 按鈕,用戶點擊代表被邀者的決定。
2. **跨聊天派生狀態**:約球滿員時,所有未決定的邀請卡**渲染時派生**為「已約到球友」灰態。
3. **滿員從首頁消失**:`HomeView` 的 `matches` 顯示時 filter 掉 `isFull == true && isOwnMatch == true`(自己創的滿員約球也消失,被報名的滿員約球已有 filter `if match.isFull && !match.isOwnMatch`)。
4. **Undo**:點已決定的灰卡 → confirmation alert → 反悔。Undo Accept 會把 registrant / players / status / 首頁 currentPlayers / 首頁顯示全部回滾。
5. **時間衝突警告**:被邀者在 `MockFriendSchedule` 中該時段有約 → 卡片頂部黃條警告,但**按鈕仍可用**。

### 不包含
- 真實後端 / 推送通知
- 邀請撤回(發出後不能由發起人「收回」邀請,只能等被邀者決定或衝突過期)
- 邀請過期清理(約球時間過了的 pending 邀請暫時保留為灰卡)
- App 重啟持久化(in-memory,符合既有 mock 慣例)
- 賽事 `私信邀請球友`(賽事 registrants 模型不同,後續單獨處理)
- 編輯約球 / 關閉報名(仍占位)

## 驗收標準（手動測試）

1. 我發起的雙打 (1/4) → 管理 → 私信邀請球友 → 邀 4 人(王強、莎拉、林叔、嘉欣)
2. 進「聊天」tab → 看到 4 個對話最上方各有一張**互動邀請卡**(中央卡片,內含按鈕),其中莎拉那張卡頂部有黃條「⚠️ 莎拉那時段有單打」(因 `MockFriendSchedule`)
3. 進王強對話 → 點 `[接受]` → 卡片變灰 + 顯示「✅ 王強已接受」+ 下方系統消息「🎾 約球已確認」+ toast「王強已接受邀請」
4. 退回我的約球 → 該約球變 2/4,registrants 多了王強
5. 同樣流程接受林叔(3/4)、嘉欣(4/4 滿員)
6. **首頁** → 該約球**消失**(filter)
7. **進莎拉對話** → 那張未決定的卡片自動變灰,按鈕區換成「🎾 已約到球友 (4/4)」
8. **回我的約球 → 莎拉那張對話也是灰** ← 派生狀態而非持久化 expired
9. **Undo Accept**:點嘉欣對話裡的「✅ 嘉欣已接受」灰卡 → confirmation「撤回嘉欣的決定?」→ 確認 → 卡片變回可接受 + 約球變 3/4 + 首頁該約球**重新出現** + 莎拉那張卡也**自動恢復為可接受**(派生狀態)
10. **Undo Decline**:同上但對「❌ 拒絕」卡 → 純狀態翻轉,無資料變更
11. App 重啟 → 邀請丟失(`InviteStore` in-memory)

## 設計

### 數據模型

#### 新文件:`Models/InviteStore.swift`

```swift
import Foundation
import SwiftUI

@Observable
final class InviteStore {
    enum Status: String { case pending, accepted, declined }

    struct Invite: Identifiable, Equatable {
        let id: UUID
        let matchID: UUID
        let inviteeName: String                 // 對 MockChat.personal(name:)
        let inviteeGender: Gender
        let inviteeNTRP: String
        let payload: OutgoingInvitationPayload  // 顯示用(從 §6 spec 沿用)
        let startDate: Date
        let endDate: Date
        var status: Status
        var decidedAt: Date?                    // accept/decline 時間,顯示時間戳用
        let createdAt: Date
    }

    private(set) var invites: [Invite] = []

    func add(_ invite: Invite) {
        // 防重:同一 (matchID, inviteeName) 只允許一條 active(pending/accepted)
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

    /// 整個約球被取消時呼叫;把所有 active(pending/accepted)邀請改 .declined。
    /// 不在 store 內處理 match 數據回滾,呼叫方自己處理。
    func expireAll(matchID: UUID) {
        for i in invites.indices where invites[i].matchID == matchID
                                    && invites[i].status != .declined {
            invites[i].status = .declined
            invites[i].decidedAt = Date()
        }
    }
}
```

注入方式對齊現有 `BookingStore` / `FollowStore`:

```swift
// HomeView.swift PreviewProvider 與 RootView 注入鏈
.environment(InviteStore())
```

#### `OutgoingInvitationPayload` / `PendingDMInvitation`

`OutgoingInvitationPayload` 沿用 PR #21 引入的類型(`ChatDetailView.swift` 文件級 internal struct)。`PendingDMInvitation` 不再需要 — 邀請發出時直接構造 `InviteStore.Invite` 寫入 store,不再經由 ChatDetailView 的 prop。

### 渲染邏輯 — 派生狀態

`ChatDetailView` 把 `InviteStore.invitesForChat(chat.name)` 與 `mockMessages + sentMessages` 合併,按 `createdAt` 時序穿插渲染。每張卡的顯示狀態**渲染時計算**:

```swift
enum InviteCardDisplay {
    case actionable(hasConflict: Bool, conflictLabel: String?)
    case accepted(at: Date)
    case declined(at: Date)
    case expired(reason: ExpireReason)   // 滿員 / 約球已取消 / 已過開賽時間
}

enum ExpireReason { case full, cancelled, timePassed }

func display(for invite: Invite,
             match: MyMatchItem?,
             friendBusy: FriendBusySlot?) -> InviteCardDisplay {
    switch invite.status {
    case .accepted: return .accepted(at: invite.decidedAt ?? invite.createdAt)
    case .declined: return .declined(at: invite.decidedAt ?? invite.createdAt)
    case .pending:
        guard let m = match else { return .expired(reason: .cancelled) }
        if m.startDate < Date() { return .expired(reason: .timePassed) }
        let (cur, mx) = m.playerCounts
        if cur >= mx { return .expired(reason: .full) }
        return .actionable(hasConflict: friendBusy != nil,
                           conflictLabel: friendBusy?.label)
    }
}
```

「match 滿員 → 其他卡片變灰」是這個派生函數的自然結果,不需要任何主動同步。Undo Accept 讓 `cur` 變回 `mx - 1`,所有 pending 卡片下次 render 時自動回到 `.actionable`。

### `BubbleContent` 變更

PR #21 引入了 `.outgoingInvitation(OutgoingInvitationPayload)`(發起人視角,純展示無按鈕,右側綠卡)。本次**保留**它,並新增 `.dmInvitation(InviteStore.Invite.ID)` —— **僅儲存 invite id**,渲染時從 InviteStore 拉資料,確保狀態變化(accept/decline/undo)即時反映到所有顯示位置。

```swift
enum BubbleContent {
    case incoming(String)
    case outgoing(String)
    case outgoingImage(Data)
    case invitation(date: String, location: String, startDate: Date, endDate: Date)
    case outgoingInvitation(OutgoingInvitationPayload)  // PR #21,保留
    case dmInvitation(UUID)                              // 新增,id 是 InviteStore.Invite.id
    case systemMessage(String)
}
```

實際上 `.dmInvitation` bubble 不會被 append 到 `sentMessages` —— 由 ChatDetailView 在 build `allMessages` 時即時生成:

```swift
// ChatDetailView.allMessages
var messages = mockMessages + sentMessages
for invite in inviteStore.invitesForChat(chat.name) {
    let bubble = ChatBubble(.dmInvitation(invite.id),
                            timestamp: AppDateFormatter.hourMinute.string(from: invite.createdAt))
    messages.append(bubble)
}
return messages.sorted(by: { /* by timestamp 或保留 invite append-after 順序 */ })
```

### 邀請卡渲染(`dmInvitationCard`)

在 `ChatDetailView` 加新 view builder。中央置中卡片(類似系統卡的全寬風格,但是有邊框/圓角),不同 `InviteCardDisplay` 對應不同視覺:

```swift
@ViewBuilder
private func dmInvitationCard(_ invite: InviteStore.Invite,
                              display: InviteCardDisplay) -> some View {
    VStack(spacing: 0) {
        // 衝突警告條(僅 .actionable + hasConflict)
        if case .actionable(true, let label?) = display {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("\(invite.inviteeName)那時段已有\(label)")
            }
            .font(Typography.small)
            .foregroundColor(Theme.warningText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(Theme.warningBg)
        }

        // 卡片主體 — 約球資訊
        VStack(alignment: .leading, spacing: 6) {
            Text("🎾 約球邀請")
                .font(Typography.captionMedium)
                .foregroundColor(Theme.textSecondary)
            Text(invite.payload.title)
                .font(Typography.bodySemibold)
            Text("📅 \(invite.payload.dateLabel) \(invite.payload.timeRange)")
            Text("📍 \(invite.payload.location)")
            Text("👥 \(invite.payload.players)")
        }
        .padding(Spacing.md)

        // 動作區 — 依 display 切換
        Divider()
        actionRow(invite: invite, display: display)
    }
    .background(displayBackground(for: display))
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(displayBorder(for: display), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, Spacing.md)
    .opacity(display.isMuted ? 0.7 : 1.0)
    .onTapGesture {
        if display.isDecided { undoTarget = invite }   // 觸發反悔流程
    }
}

@ViewBuilder
private func actionRow(invite: InviteStore.Invite,
                       display: InviteCardDisplay) -> some View {
    switch display {
    case .actionable:
        HStack(spacing: Spacing.sm) {
            Button("拒絕") { handleDecline(invite) }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            Button("接受") { handleAccept(invite) }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding(Spacing.sm)

    case .accepted(let at):
        Label("\(invite.inviteeName)已接受 · \(timeFmt(at))",
              systemImage: "checkmark.circle.fill")
            .foregroundColor(Theme.success)
            .padding(Spacing.sm)

    case .declined(let at):
        Label("\(invite.inviteeName)已拒絕 · \(timeFmt(at))",
              systemImage: "xmark.circle.fill")
            .foregroundColor(Theme.textSecondary)
            .padding(Spacing.sm)

    case .expired(let reason):
        Label(reasonText(reason, match: matchLookup(invite.matchID)),
              systemImage: "lock.fill")
            .foregroundColor(Theme.textSecondary)
            .padding(Spacing.sm)
    }
}
```

`reasonText(_:match:)`:
- `.full` → `"🎾 已約到球友 (\(m.playerCounts.current)/\(m.playerCounts.max))"`(若 match 不存在則 fallback「約球已滿員」)
- `.cancelled` → `"約球已取消"`
- `.timePassed` → `"已過開賽時間"`

### 接受 / 拒絕 / 反悔 處理

ChatDetailView 內三個 handler:

```swift
private func handleAccept(_ invite: InviteStore.Invite) {
    inviteStore.setStatus(.accepted, for: invite.id)
    matchActions.acceptInvite(invite)        // 統一閉包,寫 MyMatchesView/HomeView
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
    // Undo Decline 純狀態,無副作用
}
```

`matchActions` 是新的 `InviteMatchActions` struct(closure 集合),由 HomeView 提供,讓 ChatDetailView 不直接耦合 MyMatchesView 內部:

```swift
struct InviteMatchActions {
    var acceptInvite: (InviteStore.Invite) -> Void
    var undoAcceptInvite: (InviteStore.Invite) -> Void
}
```

#### `acceptInvite` 在 HomeView 提供的實現

`upcomingMatches` 上提到 HomeView 後,closure 直接讀寫兩個 `@State`:

```swift
acceptInvite: { invite in
    // 1. 寫 upcomingMatches:append registrant、players +1、滿員時 status 升 .confirmed
    guard let idx = upcomingMatches.firstIndex(where: { $0.id == invite.matchID }) else { return }
    var m = upcomingMatches[idx]
    guard !m.registrants.contains(where: { $0.name == invite.inviteeName }) else { return }
    m.registrants.append(MatchRegistrant(
        name: invite.inviteeName,
        gender: invite.inviteeGender,
        ntrp: invite.inviteeNTRP,
        isOrganizer: false
    ))
    let (cur, mx) = m.playerCounts
    let ntrpRange = m.players.components(separatedBy: "NTRP ").last ?? ""
    m.players = "\(cur + 1)/\(mx) · NTRP \(ntrpRange)"
    if cur + 1 >= mx { m.status = .confirmed }
    upcomingMatches[idx] = m

    // 2. 同步首頁 matches.currentPlayers(若該約球有對應 MockMatch)
    if let src = m.sourceMatchID,
       let mIdx = matches.firstIndex(where: { $0.id == src }) {
        matches[mIdx].currentPlayers += 1
    }
}
```

`undoAcceptInvite`:相反方向 — remove registrant、字串 -1、若 cur 從 mx 下降回 mx-1 則 status 從 .confirmed 回 .pending、首頁 currentPlayers -1。

### MyMatchesView 變更

**移除 PR #21 的 1.6s scaffold 機制**:
- `pendingInvitation: PendingDMInvitation?` @State 刪除
- `handleInviteResolved` 函數刪除
- ChatDetailView 的 `pendingInvitation` / `onInviteResolved` 兩個 init 參數刪除
- ChatDetailView `.task(id:)` 模擬塊刪除

**新增 InviteStore 寫入**(`handleInvitePicked` 內):

```swift
private func handleInvitePicked(player: FollowPlayer, target: InviteTarget) {
    let chat = ensureChat(with: player)        // 既有邏輯抽出
    if case .match(let id, let title, let dateLabel, let timeRange, let location, let players) = target,
       let item = upcomingMatches.first(where: { $0.id == id }) {
        let invite = InviteStore.Invite(
            id: UUID(),
            matchID: id,
            inviteeName: player.name,
            inviteeGender: player.gender,
            inviteeNTRP: player.ntrp,
            payload: OutgoingInvitationPayload(
                title: title, dateLabel: dateLabel,
                timeRange: timeRange, location: location, players: players
            ),
            startDate: item.startDate,
            endDate: item.endDate,
            status: .pending,
            decidedAt: nil,
            createdAt: Date()
        )
        inviteStore.add(invite)
        // 順帶把 chat 提到列表頂部,但**不主動進入聊天** —— 用戶要去「聊天」tab 自己點進對話。
        // (對齊用戶需求:「自動生成新的私信對話框」)
    }
    toast = .init(kind: .success, text: "邀請已發送給 \(player.name)")
}
```

**新增 `appendRegistrant` / `removeRegistrant` 方法**(讓 HomeView 能驅動):

由於 `upcomingMatches` 是 `MyMatchesView` 的 `@State`,需要透過 binding 或 closure 上拋。最簡:把 `upcomingMatches` 提到 HomeView,作為 `@State` 並 binding 進 `MyMatchesView`(對齊 `matches` 的處理)。

或者:用 callback,讓 HomeView 觸發 MyMatchesView 內的方法 — 但 SwiftUI 不直接支持。

**選定方案**:把 `upcomingMatches` 上提到 `HomeView` 的 `@State`,binding 進 `MyMatchesView`。`acceptInvite` / `undoAcceptInvite` 兩個 closure 在 HomeView 直接操作 `@State upcomingMatches` + `@State matches`。

```swift
// HomeView.swift
@State private var upcomingMatches: [MyMatchItem] = mockUpcomingMatchesInitial

MyMatchesView(
    sharedChats: $sharedChats,
    upcomingMatches: $upcomingMatches,
    onGoHome: { selectedTab = 0 },
    ...
)

case 3: MessagesView(
    totalUnread: $chatUnreadCount,
    chats: $sharedChats,
    matchActions: InviteMatchActions(
        acceptInvite: { invite in
            // 寫 upcomingMatches + matches
        },
        undoAcceptInvite: { invite in ... }
    )
)
```

**MessagesView → ChatDetailView 透傳**:`MessagesView` 接 `matchActions`,傳給 `ChatDetailView`。

**權衡**:`upcomingMatches` 上提後,`MyMatchesView` 變得相對 dumb,但符合「state hoisting」SwiftUI 慣用模式,而且 `matches` 已經在 HomeView。一致性好。

### HomeView 改造

```swift
// matches 列表過濾(現有 buildSection 內,line 404 附近)
.filter { match in
    if match.isFull { return false }   // 自己 / 別人創的滿員都過濾
    // ... 既有篩選 ...
}
```

PR #21 留下的 `onInviteAccepted` callback 整段刪除(被 `acceptInvite` closure 取代)。

### MockFriendSchedule 變更

**保留**檔期數據與 `conflict(for:start:end:)` 函數。
**刪除**:無 — 但其唯一呼叫者(ChatDetailView 的 `.task` 自動回覆塊)被刪了,需要新呼叫者:

```swift
// ChatDetailView.dmInvitationCard 渲染前
let busy = MockFriendSchedule.conflict(
    for: invite.inviteeName,
    start: invite.startDate,
    end: invite.endDate
)
let display = displayState(for: invite, match: ..., friendBusy: busy)
```

### Undo confirmation

點已決定的卡 → `undoTarget: InviteStore.Invite?` 設值 → confirmationDialog:

```swift
.confirmationDialog("撤回\(invite.inviteeName)的決定?",
                    isPresented: undoBinding,
                    presenting: undoTarget) { invite in
    Button("撤回", role: .destructive) { handleUndo(invite) }
    Button("取消", role: .cancel) {}
} message: { invite in
    Text(invite.status == .accepted
         ? "撤回後,該球友將從報名列表移除,約球可能恢復至「招募中」"
         : "撤回後,可重新讓該球友考慮")
}
```

## 邊界情況

| # | 場景 | 行為 |
|---|---|---|
| 1 | 同一好友重複邀同一約球 | InvitePickerSheet 已禁用「已報名」(現有);`InviteStore.add` 額外去重 active 邀請 |
| 2 | 邀請數 > 剩餘名額 | 全部允許發送;先到先得,後接受的看到 `.expired(.full)` |
| 3 | 邀請發出後,被邀者未決定就把約球**取消** | `handleMatchCancelled` 統一調 `inviteStore.expireAll(matchID:)` 把所有未決定改 declined,卡片渲染為 `.expired(.cancelled)` |
| 4 | Undo Accept 時該約球已被另一邀請填滿(理論上不可能,因為填滿後其他卡都灰) | 仍允許 undo;players -1, status 從 .confirmed 回 .pending |
| 5 | App 重啟 | invites 丟失;mock 慣例 |
| 6 | 同一 chat 多張不同約球的邀請 | 全部渲染,按 createdAt 時序 |
| 7 | 拒絕後 InvitePickerSheet 是否解禁? | 解禁(`registrants` 裡沒這個人,自然可選);用戶可重新邀請 |
| 8 | 對方已在 `registrants`(透過別的途徑)時邀請 | InvitePickerSheet 標灰禁用(現有) |
| 9 | `MockFriendSchedule.busySlots` 沒對上 | `friendBusy == nil` → 卡片無警告條(正常路徑) |
| 10 | 聊天裡接受後立刻退出 → 重新進來 | 卡片仍是 accepted 狀態(因 InviteStore 持久於 session) |
| 11 | 約球時段已過(過期) | `display = .expired(.timePassed)`,按鈕灰掉,可 Undo 已決定的 |
| 12 | 邀請了非互關好友(理論上 `mutualFollows` 不含) | 不會發生 |
| 13 | 滿員的約球 → 取消 → 邀請是否復活? | 取消已 `expireAll` 改 declined,**不復活**;一致性優先於體驗 |

## 本地化新字串

- `🎾 約球邀請`
- `%@ 已接受 · %@`
- `%@ 已拒絕 · %@`
- `%@婉拒了邀請`
- `%@那時段已有%@`
- `🎾 已約到球友 (%d/%d)`
- `約球已取消`
- `已過開賽時間`
- `撤回%@的決定?`
- `撤回後,該球友將從報名列表移除,約球可能恢復至「招募中」`
- `撤回後,可重新讓該球友考慮`
- `撤回`
- `邀請已發送給 %@`
- `🎾 約球已確認！%@ 在%@`(沿用)

## 改動文件清單

| 文件 | 變更 |
|---|---|
| `Models/InviteStore.swift` | **新建** —— `@Observable` store + `Invite` struct + `add/setStatus/expireAll/invitesForChat` |
| `Views/HomeView.swift` | 注入 `InviteStore`、`upcomingMatches` 上提為 `@State`、`InviteMatchActions` closures、移除 `onInviteAccepted`、`matches` filter `isFull` 過濾 |
| `Views/MyMatchesView.swift` | 移除 `pendingInvitation` / `handleInviteResolved`、`upcomingMatches` 改 `@Binding`、`handleInvitePicked` 改寫入 `InviteStore`、整合 `inviteStore.expireAll` 到 `handleMatchCancelled` |
| `Views/ChatDetailView.swift` | 移除 `pendingInvitation` / `onInviteResolved` / `.task` 模擬;新增 `BubbleContent.dmInvitation`、`dmInvitationCard` 與 `actionRow` 渲染、`handleAccept/Decline/Undo`、`undoTarget` confirmationDialog;`allMessages` 合併 InviteStore 條目;接 `matchActions: InviteMatchActions` 參數 |
| `Views/MessagesView.swift` | 透傳 `matchActions` 到 `ChatDetailView` |
| `Models/MockFriendSchedule.swift` | 不變,新呼叫點在 ChatDetailView 渲染處 |
| `Components/InvitePickerSheet.swift` | 不變(現有 `disabledPlayerNames` 已能服務「已報名」禁用) |
| `Localizable.xcstrings` | Xcode auto-extract |
| `TennisMatchApp.swift` | `.environment(InviteStore())` 加進現有注入鏈(與 `BookingStore` / `FollowStore` 並列);PreviewProvider 同步補 |

預估改動量:新增 ~350-450 行、刪除 ~100-150 行(PR #21 scaffold)、修改 ~80-120 行。

## 風險

| 風險 | 緩解 |
|---|---|
| `upcomingMatches` 上提到 HomeView 是大手術,可能影響現有 cancel / registrant sheet 等流程 | 細分 task 逐步遷移,每步編譯 + 冒煙;若風險太大,改用 `@Observable MatchStore` 把 upcomingMatches 包進去 |
| `dmInvitation` bubble 用 invite id 查 store,渲染時 store 突變(Undo)需要 view 重 render | `InviteStore` 是 `@Observable`,SwiftUI 自動追蹤;ChatDetailView 持 `@Environment(InviteStore.self)` 引用即可 |
| `BubbleContent.dmInvitation` 加 case 觸發所有 switch 編譯失敗 | Swift 編譯器逐個提示 |
| 滿員約球從首頁消失後,用戶找不到入口 Undo | 約球仍在「我的約球 → 即將到來」中(本來就應在);灰卡 Undo 入口在「聊天」 |
| `MockFriendSchedule` 時段對不上 mock 約球,衝突警告無從觸發 | PR #21 已處理時段對齊(`23cb78b chore(mock): align 小美 busy slot with 跑馬地 14:00 match`);本次 demo 路徑同樣可走 |
| Undo Accept 同步首頁時,若 `sourceMatchID == nil`(種子 mock 約球無對應 MockMatch),首頁 no-op,但 MyMatchesView 有變化 → 顯示一致性 OK | 已驗證:沒 sourceMatchID 的約球本來就不在 HomeView matches 裡 |

## 後續

- 真實後端接入時:`InviteStore` 變 `@Observable` + actor,本地 mutate 之外加 push event 收到時 mutate(WebSocket / APNs)
- 邀請過期清理:加定時 task 把 `startDate < now - 1h` 的 pending 自動標 declined
- 通知整合:邀請發出 / 被接受 / 衝突 → push 通知或 in-app banner
- 賽事邀請:賽事 registrants 模型對齊後復用 InviteStore(加 `kind: .match | .tournament`)
