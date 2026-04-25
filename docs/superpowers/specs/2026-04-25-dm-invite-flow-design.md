# DM 邀請報名閉環 + 報名者主頁跳轉 — 設計

**日期**：2026-04-25
**分支**：fix/cancelled-match-reappears（後續另開）
**作者**：XUE / Claude

## 背景

「我的約球 → 即將到來 → 我發起的約球 → 管理」菜單裡的 5 個動作中：

- ✅ 查看報名者 — 已實現（缺少：點球員不能進個人主頁）
- ❌ 編輯約球 — 仍是 toast 占位（**本次不做**）
- ❌ 關閉報名 — 仍是 toast 占位（**本次不做**）
- ⚠️ 私信邀請球友 — 看似實現，實際只往聊天注入一張靜態 system message info card；**被邀好友沒有任何"接受報名"入口**，整個約球邀請閉環走不通
- ✅ 取消約球 — 已實現

本設計補齊 **私信邀請球友** 的閉環，並順手修 **查看報名者** 的人物導覽。

## 範圍

### 包含
1. **DM 邀請報名閉環**（核心）— 邀請發出 → 模擬好友自動回覆（接受 / 因檔期衝突婉拒）→ 接受時 registrants/`currentPlayers` +1，狀態從「等待中」升級「已確認」。
2. **報名者列表點頭像 → `PublicProfileView`**。
3. **邀請前置校驗** — 已報名好友在 `InvitePickerSheet` 標灰禁用；約球已滿員時管理菜單隱藏「私信邀請球友」項。

### 不包含
- 編輯約球（仍占位）
- 關閉報名（仍占位）
- 賽事 `私信邀請球友`（賽事 registrant / 滿員模型不同，下一輪單獨處理）
- 真實後端 / 通知推送（仍是 mock）
- 邀請撤回（外發卡發出後不可撤）

## 驗收標準（手動測試）

1. `我發起的雙打 (2/4)` → 管理 → 私信邀請球友 → 選一個**空閒好友** → 聊天裡依次出現：外發邀請氣泡 → 1.6s 後 "好的我接受！"（incoming）→ 系統確認卡。退回「我的約球」看到 3/4、registrants 多出該好友、若達滿員則 status 升級。首頁 `MockMatch.currentPlayers` 同步 +1。
2. 同樣流程但選**檔期衝突的好友**（依 `MockFriendSchedule`）— 只出現外發卡 + 婉拒文案 "不好意思,那時段我已有 X,下次再約 🙏"，registrants 不變。
3. 接受後再點 私信邀請球友 → `InvitePickerSheet` 中該好友標灰「已報名」、不可點。
4. 將同一約球邀人到滿員 (4/4) → 管理菜單裡**不再顯示**「私信邀請球友」項。
5. 邀請發出 1.6s 內按返回退出聊天 → 不出錯、不留半截數據；再進同一聊天，不重跑模擬，視同邀請丟失。
6. 並發保護 — 第一個邀請尚在 1.6s 模擬中時點第二個 → toast「上一個邀請還在處理中」。
7. 查看報名者 sheet → 點任一球員（含發起人）→ 進 `PublicProfileView` 看到頭像/NTRP/戰績。

## 設計

### 數據模型

#### 新文件：`Models/MockFriendSchedule.swift`

```swift
struct FriendBusySlot {
    let start: Date
    let end: Date
    let label: String           // 婉拒文案用,如 "雙打" / "教練課"
}

enum MockFriendSchedule {
    /// 互關好友名 → 已佔用時段。未列出視為完全空閒(永遠接受)。
    static let busySlots: [String: [FriendBusySlot]] = [...]

    /// 返回衝突的 slot,nil 表示無衝突(可接受)。
    static func conflict(for name: String,
                         start: Date,
                         end: Date) -> FriendBusySlot?
}
```

實現時，給 `mockUpcomingMatchesInitial` 中**部分時段**配對：例如「莎拉 周日 10-12」與某條約球同時段，邀請她到那條 → 觸發婉拒分支，方便 demo。

#### `MyMatchesView.MatchRegistrant` 加 gender

```swift
private struct MatchRegistrant {
    let name: String
    let gender: Gender              // 新增
    let ntrp: String
    let isOrganizer: Bool
}
```

所有現有種子（`mockUpcomingMatchesInitial` / `mockCompletedMatches` ~20+ 處）補 gender 字段。`acceptedMatchItems`（從 `BookingStore.accepted` 合成）的發起人/小李 gender 預設 `.male`，DM 接受加進來的好友帶 `FollowPlayer.gender` 進來（精準）。

#### `MyMatchItem.players` / `status` 改可變

當前是 `let`，需改 `var` 才能在接受後遞增 `currentPlayers` 並升級 status。`registrants` 已是 `var`。

#### `ChatBubble.Content` 加新 case

`ChatBubble` 目前是 `private struct` 定義在 `ChatDetailView.swift` 末尾（line 612），新 case 直接加在那裡：

```swift
struct OutgoingInvitationPayload: Equatable {
    let title: String          // "我發起的雙打"
    let dateLabel: String      // "明天 · 04/26（六）"
    let timeRange: String      // "14:00 - 16:00"
    let location: String
    let players: String        // "2/4 · NTRP 3.5-4.5"
}

private struct ChatBubble: Identifiable {
    enum Content {
        // ... 已有: incoming/outgoing/systemMessage/invitation
        case outgoingInvitation(OutgoingInvitationPayload)
    }
}
```

`PendingDMInvitation`（外部需引用）定義為 file-private 仍會被 `MyMatchesView` 用到 → 需提升為 internal struct，放在 `ChatDetailView.swift` 頂部（與 `ChatDetailView` 同 access level）。`OutgoingInvitationPayload` 同理。

放進 `Content` 而非 `ChatDetailView` 私有 `@State`，未來要序列化、追加 status（pending/accepted/declined）擴展乾淨。

### 組件變更

#### `ChatDetailView` 新增參數

```swift
struct PendingDMInvitation: Equatable {
    let matchID: UUID                       // MyMatchItem.id
    let invitee: FollowPlayer
    let payload: OutgoingInvitationPayload
    let startDate: Date
    let endDate: Date
}

struct ChatDetailView: View {
    // ...
    var pendingInvitation: PendingDMInvitation? = nil
    var onInviteResolved: ((UUID, FollowPlayer, Bool) -> Void)? = nil
                                            // (matchID, invitee, accepted)

    @State private var simulatedInvitationHandled = false
}
```

#### ChatDetailView 模擬流程

```swift
.task(id: pendingInvitation?.matchID) {
    guard let p = pendingInvitation, !simulatedInvitationHandled else { return }
    simulatedInvitationHandled = true

    let ts = AppDateFormatter.hourMinute.string(from: Date())
    sentMessages.append(ChatBubble(.outgoingInvitation(p.payload), timestamp: ts))

    try? await Task.sleep(nanoseconds: 1_600_000_000)
    guard !Task.isCancelled else { return }

    if let conflict = MockFriendSchedule.conflict(
        for: p.invitee.name, start: p.startDate, end: p.endDate
    ) {
        let body = "不好意思,那時段我已有\(conflict.label),下次再約 🙏"
        sentMessages.append(ChatBubble(.incoming(body), timestamp: tsNow()))
        onInviteResolved?(p.matchID, p.invitee, false)
    } else {
        sentMessages.append(ChatBubble(.incoming("好的,我接受！"), timestamp: tsNow()))
        sentMessages.append(ChatBubble(.systemMessage(
            "🎾 約球已確認！\(p.payload.dateLabel) 在\(p.payload.location)"
        )))
        onInviteResolved?(p.matchID, p.invitee, true)
    }
}
```

`Task.isCancelled` 在用戶 1.6s 內退出聊天時為 true → 不注入回覆、不調回調、邀請丟失（mock 可接受）。

#### `outgoingInvitationCard` 新 view builder

右對齊綠色氣泡，背景 `Theme.confirmedBg`，內容仿現有 `invitationCard` 但無按鈕（純發送態）。標題 "🎾 你發起了約球邀請" + payload 的 title/dateLabel/timeRange/location/players 列出。

`messageView` switch 補 `.outgoingInvitation` 路由。

#### `InvitePickerSheet` 加禁用支持

```swift
struct InvitePickerSheet: View {
    let target: InviteTarget
    var disabledPlayerNames: Set<String> = []
    var disabledReason: String = "已報名"
    let onPick: (FollowPlayer) -> Void
}
```

禁用行：`Button { onPick }.disabled(true)`，右側用 `Text(disabledReason)` 替換 `paperplane.fill` 圖標，文字色 `Theme.textSecondary`。

### 狀態流（happy path）

```
MyMatchesView                 ChatDetailView                MockFriendSchedule
    │                               │                              │
    │ 用戶點 私信邀請球友             │                              │
    │ → InvitePickerSheet           │                              │
    │ ← onPick(player=莎拉)          │                              │
    │                               │                              │
    │ pendingInvitation = .init(...) │                             │
    │ selectedChat = chat            │                             │
    │ ─────────────────────────────►│                              │
    │                               │ .task: append 外發 bubble    │
    │                               │ Task.sleep(1.6s)             │
    │                               │ ────conflict(for:)──────────►│
    │                               │ ◄────FriendBusySlot? ────────│
    │                               │ append incoming bubble        │
    │ ◄──onInviteResolved(true)─────│                              │
    │                               │                              │
    │ handleInviteResolved:         │                              │
    │   guard accepted              │                              │
    │   防重複 +1                    │                              │
    │   match.registrants.append    │                              │
    │   match.players "+1/X"        │                              │
    │   status: pending → confirmed │                              │
    │   onInviteAccepted? (上行)     │                              │
    │                               │                              │
HomeView                            │                              │
    │ matches[idx].currentPlayers+=1│                              │
```

### MyMatchesView 改造

```swift
@State private var pendingInvitation: PendingDMInvitation? = nil
@State private var selectedRegistrantPlayer: PublicPlayerData? = nil

// confirmationDialog 條件化「私信邀請球友」
.confirmationDialog("管理約球", isPresented: $showManageSheet, presenting: matchToManage) { match in
    Button("查看報名者") { registrantMatch = match }
    Button("編輯約球") { /* 占位 */ }
    Button("關閉報名") { /* 占位 */ }
    if match.playerCounts.current < match.playerCounts.max {
        Button("私信邀請球友") {
            inviteTarget = .match(...)
        }
    }
    Button("取消約球", role: .destructive) { ... }
    Button("取消", role: .cancel) {}
}

private func handleInvitePicked(player: FollowPlayer, target: InviteTarget) {
    // 並發保護
    guard pendingInvitation == nil else {
        toast = .init(kind: .info, text: L10n.string("上一個邀請還在處理中"))
        return
    }

    // 找/建 chat（已有邏輯）
    let chat = ...

    if case .match(let id, let title, let dateLabel, let timeRange, let location, let players) = target,
       let item = upcomingMatches.first(where: { $0.id == id }) {
        pendingInvitation = PendingDMInvitation(
            matchID: id,
            invitee: player,
            payload: OutgoingInvitationPayload(
                title: title, dateLabel: dateLabel,
                timeRange: timeRange, location: location, players: players
            ),
            startDate: item.startDate,
            endDate: item.endDate
        )
    }
    // 賽事走原 matchContext 路徑(本次不改)
    selectedChat = chat
}

private func handleInviteResolved(matchID: UUID, friend: FollowPlayer, accepted: Bool) {
    defer { pendingInvitation = nil }      // 釋放並發鎖
    guard accepted else { return }
    guard let idx = upcomingMatches.firstIndex(where: { $0.id == matchID }) else { return }
    var match = upcomingMatches[idx]
    guard !match.registrants.contains(where: { $0.name == friend.name }) else { return }

    match.registrants.append(MatchRegistrant(
        name: friend.name, gender: friend.gender, ntrp: friend.ntrp, isOrganizer: false
    ))
    let (cur, mx) = match.playerCounts
    let ntrpRange = match.players.components(separatedBy: "NTRP ").last ?? ""
    match.players = "\(cur + 1)/\(mx) · NTRP \(ntrpRange)"
    if cur + 1 >= mx { match.status = .confirmed }
    upcomingMatches[idx] = match

    onInviteAccepted?(matchID, friend, match.sourceMatchID)
}

// 查看報名者 sheet 行：包 Button → selectedRegistrantPlayer
ForEach(...) { registrant in
    Button {
        selectedRegistrantPlayer = mockPublicPlayerData(
            name: registrant.name,
            gender: registrant.gender,
            ntrp: registrant.ntrp
        )
    } label: { ...原行 UI... }
    .buttonStyle(.plain)
}

// sheet 容器外
.navigationDestination(item: $selectedRegistrantPlayer) { player in
    PublicProfileView(player: player)
}
```

### HomeView 改造

新接 `onInviteAccepted` callback，同步 `MockMatch.currentPlayers`：

```swift
MyMatchesView(
    sharedChats: $chats,
    onGoHome: ...,
    onMatchCancelled: ...,
    onInviteAccepted: { matchID, friend, sourceMatchID in
        guard let sourceID = sourceMatchID,
              let idx = matches.firstIndex(where: { $0.id == sourceID }) else { return }
        matches[idx].currentPlayers += 1
    }
)
```

如果發起人本人創建的約球（`isOwnMatch = true`）的 `MockMatch.id` 與 `MyMatchItem.sourceMatchID` 沒對接好，**實現階段先 grep `CreateMatchView` 的 publish 流程**確認；如果沒填，按 title + startDate 兜底匹配（思路同 `CancelledMatchPayload` fallback）。

## 邊界情況

| # | 場景 | 行為 |
|---|---|---|
| 1 | 已在 registrants | InvitePickerSheet 該行 disabled；`handleInviteResolved` 兜底防重 +1 |
| 2 | 約球已滿員 | confirmationDialog 隱藏「私信邀請球友」項 |
| 3 | 1.6s 內退出聊天 | `Task.isCancelled` → 不注入、不回調，邀請丟失 |
| 4 | 同一好友邀兩次 | 第一次接受後 InvitePickerSheet 已標灰；模擬中時 #5 並發鎖兜底 |
| 5 | 並發 pending 邀請 | 全局單 pending：`pendingInvitation != nil` 時 toast「上一個邀請還在處理中」 |
| 6 | 接受後升級為滿員 | status: pending → confirmed；首頁 currentPlayers 同步；不觸發 BookingStore（這是發起人視角） |
| 7 | `.outgoingInvitation` 與 `isInvitationAccepted` 系統消息衝突 | 後者只掃 `.invitation` bubble，不會誤匹配；實現時驗證 `allMessages` 的 for-loop |
| 8 | 邀請列表含自己 | `mutualFollows` 本就不含自己 |
| 9 | NTRP 不符 | 不限制（業餘社交） |
| 10 | 撤回邀請 | 不在範圍 |
| 11 | `isAutoCancelled` 約球 | 卡片本身不顯示 manage 按鈕，無入口 |
| 12 | 已完成約球 | 同 #11 |

## 本地化

新增 strings（Xcode auto-extract 後在後續 commit 補譯文，參考 `742fc34` 流程）：

- `好的,我接受！`
- `不好意思,那時段我已有%@,下次再約 🙏`
- `🎾 你發起了約球邀請`
- `🎾 約球已確認！%@ 在%@`
- `已滿員,無法邀請`（保留為兜底文案，當前流程不展示）
- `上一個邀請還在處理中`
- `已報名`

## 改動文件清單

| 文件 | 變更 |
|---|---|
| `Models/MockFriendSchedule.swift` | **新建** |
| `Views/ChatDetailView.swift`（`ChatBubble` 目前是 `private struct`，定義在此檔尾） | `Content` 加 `.outgoingInvitation`；新 `OutgoingInvitationPayload` struct |
| `Components/InvitePickerSheet.swift` | `disabledPlayerNames` / `disabledReason` 參數，行 disabled 樣式 |
| `Views/MyMatchesView.swift` | `MatchRegistrant.gender`、`MyMatchItem.players/status` 改 `var`、所有 mock 種子補 gender、`pendingInvitation` 狀態、改造 `handleInvitePicked`、新增 `handleInviteResolved`、confirmationDialog 條件化、查看報名者 sheet 包 Button、`navigationDestination` 接 `PublicProfileView` |
| `Views/ChatDetailView.swift` | `pendingInvitation` / `onInviteResolved` 參數、`@State simulatedInvitationHandled`、`.task` 模擬、`outgoingInvitationCard` 渲染、`messageView` 路由 |
| `Views/HomeView.swift` | `MyMatchesView(onInviteAccepted:)` 新回調，同步 `MockMatch.currentPlayers` |
| `Localizable.xcstrings` | Xcode auto-extract（不手改） |

預估改動量：新增 ~250-350 行、修改 ~80-100 行。

## 風險

| 風險 | 緩解 |
|---|---|
| `MockMatch.id` 與發起人本人約球的 `MyMatchItem.sourceMatchID` 對接不穩 | 實現階段先核查 `CreateMatchView` 的 publish 流程；缺則 title+startDate 兜底 |
| `acceptedMatchItems` 無 gender → 預設 `.male` | mock 階段可接受，後端接入時補字段 |
| `ChatBubble.Content` 新 case 觸發所有 switch 編譯失敗 | Swift 編譯器會逐個提示，順著改 |
| 並發鎖（單 pending）對多任務批量邀請體驗略嚴格 | 1.6s 模擬視窗極短，用戶基本無感；如後續需要可放寬到「按 match 並發」 |

## 後續

- 編輯約球（下一輪）— 預期復用 `CreateMatchView` 表單，把 PublishedMatchInfo 變雙向綁定
- 關閉報名 — 加 `MyMatchItem.isClosed: Bool`，關閉後管理菜單僅剩 取消約球
- 賽事 私信邀請 — 在賽事 registrants/滿員邏輯落地後再補
- 撤回邀請 — `OutgoingInvitationPayload` 加 `status` 字段
