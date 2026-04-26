# DM 邀請報名閉環 + 報名者主頁跳轉 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 補齊「管理約球 → 私信邀請球友」的完整閉環(模擬好友自動回覆/接受時 registrants 與 currentPlayers +1),並修「查看報名者」點球員不能進個人主頁的問題。

**Architecture:** 方案 1(輕量回調)— 邀請發出後 ChatDetailView 在 `.task` 中模擬 1.6s 延遲,查 `MockFriendSchedule` 判斷檔期衝突,通過 `onInviteResolved` 回調回寫到 MyMatchesView,再經現有 callback 鏈同步到 HomeView。

**Tech Stack:** Swift / SwiftUI / `@Observable` / `@AppStorage` / `Task` async/await

**Spec:** `docs/superpowers/specs/2026-04-25-dm-invite-flow-design.md`

**Project context:**
- 無單元測試框架 — 每個任務的驗證 = `xcodebuild` 編譯通過 + Xcode 模擬器手動冒煙
- ChatBubble 的 enum 名稱實際為 `BubbleContent`(在 `ChatDetailView.swift:622`)
- 發起人本人經 `CreateMatchView` 發布的 `MockMatch` 不會自動進 `MyMatchesView.upcomingMatches`(現有現實),`onInviteAccepted` 在 `sourceMatchID == nil` 時 no-op

**Build command (CLI):**
```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```
或 Xcode 內 `⌘B`。

---

## File Structure

| 文件 | 動作 | 職責 |
|---|---|---|
| `TennisMatch/Models/MockFriendSchedule.swift` | **Create** | 互關好友的 mock 檔期 + `conflict(for:start:end:)` 查詢 |
| `TennisMatch/Views/ChatDetailView.swift` | Modify | 加 `OutgoingInvitationPayload` / `PendingDMInvitation` / 新 BubbleContent case / 渲染 / 模擬流程 / 新 init 參數 |
| `TennisMatch/Components/InvitePickerSheet.swift` | Modify | 加 `disabledPlayerNames` / `disabledReason` 參數,行禁用樣式 |
| `TennisMatch/Views/MyMatchesView.swift` | Modify | `MatchRegistrant.gender`、`MyMatchItem.players/status` 改 `var`、所有 mock 種子補 gender、`@State pendingInvitation`、`handleInvitePicked` 改造、新 `handleInviteResolved`、confirmationDialog 條件化、查看報名者 sheet 包 Button、`navigationDestination` → `PublicProfileView` |
| `TennisMatch/Views/HomeView.swift` | Modify | `MyMatchesView(onInviteAccepted:)` 新回調 |

---

## Tasks

### Task 1: Build baseline + branch setup

**Files:** none

- [ ] **Step 1: Confirm clean working tree on the right branch**

```bash
git status
git log --oneline -3
```

Expected: working tree clean; on `fix/cancelled-match-reappears`(或從這裡新建 `feat/dm-invite-flow` 也可，本計畫直接在 `fix/cancelled-match-reappears` 上接著做)。

- [ ] **Step 2: Baseline build to confirm starting point compiles**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。如果失敗,先解決後再進下一 task,不要在壞的基線上開工。

---

### Task 2: 給 `MatchRegistrant` 加 `gender`,backfill 所有 mock 種子

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift`

**Why:** 為 Task 4「點報名者進 PublicProfileView」做準備 — `mockPublicPlayerData(name:gender:ntrp:)` 需要 gender。

- [ ] **Step 1: 給 `MatchRegistrant` struct 加 gender 欄位**

`MyMatchesView.swift` 約 line 1060-1064:

```swift
private struct MatchRegistrant {
    let name: String
    let gender: Gender
    let ntrp: String
    let isOrganizer: Bool
}
```

- [ ] **Step 2: 編譯一次,讓編譯器列出所有需要補 gender 的調用點**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build 2>&1 | grep -E "error:" | head -40
```

Expected: 約 20 處 `MatchRegistrant(name:..., ntrp:..., isOrganizer:...)` 缺 gender 的編譯錯誤。

- [ ] **Step 3: 補 gender 到 `mockUpcomingMatchesInitial`(line 1200-1284)**

依姓名性別:
- 莎拉、嘉欣、艾美、美琪、雅婷、Kelly、思慧、詠琪、曉彤、麗莎、小美 → `.female`
- 小李、王強、大衛、Michael、阿豪、俊傑、志明、林叔、阿杰、Peter、陳教練、家明、國輝、張偉、老張 → `.male`

逐一在每個 `MatchRegistrant(name: "X", ntrp: "Y", isOrganizer: Z)` 中插入 `gender: .female / .male`。例:

```swift
MatchRegistrant(name: "莎拉", gender: .female, ntrp: "4.0", isOrganizer: true),
MatchRegistrant(name: "小李", gender: .male,   ntrp: "3.5", isOrganizer: false),
```

- [ ] **Step 4: 補 gender 到 `mockCompletedMatches`(line 1287-1383)** — 同上規則。

- [ ] **Step 5: 補 gender 到 `acceptedMatchItems` 內的 registrant 構造(line 152-155)**

`MyMatchesView.swift` 約 line 152-155:

```swift
let registrants: [MatchRegistrant] = [
    MatchRegistrant(name: info.organizerName, gender: .male, ntrp: ntrpMid, isOrganizer: true),
    MatchRegistrant(name: "小李", gender: .male, ntrp: ntrpMid, isOrganizer: false),
]
```

註:`AcceptedMatchInfo` 沒有 organizer 性別欄位,預設 `.male`(spec 已標註,後端接入時補)。

- [ ] **Step 6: 編譯確認無錯**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "$(cat <<'EOF'
refactor(my-matches): 給 MatchRegistrant 加 gender 欄位

為「查看報名者點球員進 PublicProfileView」做準備;mockPublicPlayer-
Data(gender:) 需要這個資料。所有現有 mock 種子按姓名補上 .female /
.male;acceptedMatchItems 從 BookingStore 合成的 registrant 預設 .male
(AcceptedMatchInfo 無此欄位,後端接入時補)。
EOF
)"
```

---

### Task 3: `MyMatchItem.players` 與 `status` 改 `var`

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift` (line 1066-1104, struct `MyMatchItem`)

**Why:** 接受邀請時要遞增 currentPlayers(改 players 字串)+ 升級 status(等待中 → 已確認)。

- [ ] **Step 1: 把 `let players` 改 `var players`**

`MyMatchesView.swift` line 1074:

```swift
var players: String
```

- [ ] **Step 2: 把 `let status` 改 `var status`**

`MyMatchesView.swift` line 1070:

```swift
var status: MyMatchStatus
```

- [ ] **Step 3: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`(struct 內字段可變改動,所有 init 仍兼容)。

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "refactor(my-matches): MyMatchItem.players/status 改 var

接受 DM 邀請時需要遞增 currentPlayers(改 players 字串)+ 升級
status(等待中 → 已確認),預先放開可變性。"
```

---

### Task 4: 「查看報名者」點球員 → `PublicProfileView`

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift` (line 507-552, registrant sheet)

**Why:** Spec 範圍 #2;Task 2 提供的 gender 終於有用。

- [ ] **Step 1: 加新 `@State` 接 selected registrant**

`MyMatchesView.swift` 約 line 56(在其他 `@State` 旁):

```swift
@State private var selectedRegistrantPlayer: PublicPlayerData?
```

- [ ] **Step 2: 把 registrant sheet 中每行的 HStack 包成 Button**

`MyMatchesView.swift` line 510-538(在 `.sheet(item: $registrantMatch)` 裡):

```swift
ForEach(Array(match.registrants.enumerated()), id: \.offset) { i, registrant in
    Button {
        selectedRegistrantPlayer = mockPublicPlayerData(
            name: registrant.name,
            gender: registrant.gender,
            ntrp: registrant.ntrp
        )
    } label: {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 36, height: 36)
                Text(String(registrant.name.suffix(1)))
                    .font(Typography.labelSemibold)
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(registrant.name)
                    .font(Typography.bodyMedium)
                    .foregroundColor(Theme.textPrimary)
                Text("NTRP \(registrant.ntrp)")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
            if registrant.isOrganizer {
                Text("發起人")
                    .font(Typography.micro)
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, Spacing.xs)
                    .frame(height: 20)
                    .background(Theme.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textHint)
        }
    }
    .buttonStyle(.plain)
}
```

注意新加的 `Image(systemName: "chevron.right")` — 點擊提示。

- [ ] **Step 3: 在 sheet 容器外加 `navigationDestination`**

`registrantMatch` sheet 的 `NavigationStack` 內 List 之外、`.toolbar` 之前加:

```swift
.navigationDestination(item: $selectedRegistrantPlayer) { player in
    PublicProfileView(player: player)
}
```

完整位置示例(`.sheet(item: $registrantMatch)` block 的 NavigationStack 內):

```swift
NavigationStack {
    List { /* ForEach... */ }
        .listStyle(.plain)
        .navigationTitle("報名者 (\(match.playerCounts.current)/\(match.playerCounts.max))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedRegistrantPlayer) { player in
            PublicProfileView(player: player)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { registrantMatch = nil }
            }
        }
}
```

- [ ] **Step 4: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 5: Manual smoke test in simulator**

Xcode `⌘R`(iPhone 16 sim)。流程:
1. 我的約球 tab → 即將到來
2. 在「我發起的雙打」上點 管理 → 查看報名者
3. 點 列表中任一球員(例:王強)
4. **預期:** 跳轉到 PublicProfileView,顯示王強的頭像/NTRP/戰績
5. 返回 → 再點 莎拉(從另一條約球)→ 同樣可進

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "feat(my-matches): 查看報名者點球員可進 PublicProfileView

報名者 sheet 每一行包成 Button,點擊用 mockPublicPlayerData(...)
構造 PublicPlayerData 並通過 navigationDestination 跳 PublicProfile
View。行尾加 chevron.right 視覺提示。"
```

---

### Task 5: 新建 `MockFriendSchedule.swift`

**Files:**
- Create: `TennisMatch/Models/MockFriendSchedule.swift`

**Why:** Spec §2.1 — 模擬好友檔期數據,讓「邀請因衝突婉拒」分支有觸發條件。

- [ ] **Step 1: 創建文件**

```bash
ls TennisMatch/Models/
```

確認該目錄存在。

- [ ] **Step 2: 寫入內容**

`TennisMatch/Models/MockFriendSchedule.swift`:

```swift
//
//  MockFriendSchedule.swift
//  TennisMatch
//
//  互關好友的 mock 已有約球檔期 — 模擬「DM 邀請後,被邀好友自己也有時段衝突」場景。
//  僅 demo 用,真實場景由後端查好友日曆。
//

import Foundation

/// 一個已被佔用的時段。`label` 用於婉拒文案,如 "雙打" / "教練課"。
struct FriendBusySlot {
    let start: Date
    let end: Date
    let label: String
}

enum MockFriendSchedule {
    /// 互關好友姓名 → 已佔用時段。未列出的好友視為完全空閒(永遠接受)。
    /// 時段對齊 mockUpcomingMatchesInitial 中已有的時段,讓「邀請該好友到那個時段」
    /// 能穩定觸發婉拒分支,demo 容易演。
    static var busySlots: [String: [FriendBusySlot]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func slot(daysFromNow: Int, startHour: Int, startMinute: Int = 0,
                  endHour: Int, endMinute: Int = 0, label: String) -> FriendBusySlot {
            let day = cal.date(byAdding: .day, value: daysFromNow, to: today) ?? today
            var s = cal.dateComponents([.year, .month, .day], from: day)
            s.hour = startHour; s.minute = startMinute
            var e = s
            e.hour = endHour; e.minute = endMinute
            let start = cal.date(from: s) ?? day
            let end = cal.date(from: e) ?? start.addingTimeInterval(2 * 3600)
            return FriendBusySlot(start: start, end: end, label: label)
        }

        return [
            // 莎拉 — 第 1 天 10:00-12:00 與「莎拉 發起的單打」一致;
            // 如果再邀她 第 1 天 10:00 開始的約球 → 衝突婉拒
            "莎拉":  [slot(daysFromNow: 1, startHour: 10, endHour: 12, label: "單打")],
            // 嘉欣 — 第 -1 天 9:00-11:00(已過期但仍可匹配時段)
            "嘉欣":  [slot(daysFromNow: 6, startHour: 9, endHour: 11, label: "雙打")],
            // 大衛 — 第 4 天 18:30-20:30 與已有約球同
            "大衛":  [slot(daysFromNow: 4, startHour: 18, startMinute: 30, endHour: 20, endMinute: 30, label: "雙打")],
            // 其餘互關好友視為空閒
        ]
    }

    /// 返回衝突的 slot,nil 表示無衝突。半開區間判斷:`a.start < b.end && b.start < a.end`
    static func conflict(for name: String, start: Date, end: Date) -> FriendBusySlot? {
        guard let slots = busySlots[name] else { return nil }
        return slots.first { slot in
            start < slot.end && slot.start < end
        }
    }
}
```

- [ ] **Step 3: 把新文件加進 Xcode project**

兩種方式:
- **Xcode**:右鍵 `Models` group → Add Files to TennisMatch → 選 `MockFriendSchedule.swift`
- **CLI(若項目用 file system synchronized groups)**:Xcode 自動偵測;如未,需 Xcode UI 加入

確認 `TennisMatch.xcodeproj/project.pbxproj` 中包含此文件:

```bash
grep MockFriendSchedule TennisMatch.xcodeproj/project.pbxproj | head -3
```

Expected:至少 2 行匹配(`fileRef` + `buildFile`)。沒有就在 Xcode 裡 Add Files。

- [ ] **Step 4: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/MockFriendSchedule.swift TennisMatch.xcodeproj/project.pbxproj
git commit -m "feat(models): add MockFriendSchedule for invite simulation

互關好友的 mock 已佔用檔期。DM 邀請發出後查 conflict(for:start:end:)
判斷被邀好友是否時段衝突 — 衝突則模擬婉拒,不衝突則模擬接受。
時段對齊 mockUpcomingMatchesInitial,demo 容易演兩條分支。"
```

---

### Task 6: ChatBubble 加 `.outgoingInvitation` + `OutgoingInvitationPayload` 類型

**Files:**
- Modify: `TennisMatch/Views/ChatDetailView.swift` (line 612-628 ChatBubble + 加文件級類型)

**Why:** Spec §2.3 — 為外發邀請氣泡定義數據模型。`OutgoingInvitationPayload` 需從 MyMatchesView 引用,因此放在文件級別(internal 預設)。

- [ ] **Step 1: 在 `ChatDetailView.swift` 文件頂部 import 之後、`struct ChatDetailView` 之前加類型**

```swift
// MARK: - DM Invitation Types

/// DM 邀請的展示載荷 — 渲染外發邀請氣泡用。
struct OutgoingInvitationPayload: Equatable {
    let title: String        // "我發起的雙打"
    let dateLabel: String    // "明天 · 04/26（六）"
    let timeRange: String    // "14:00 - 16:00"
    let location: String
    let players: String      // "2/4 · NTRP 3.5-4.5"
}

/// MyMatchesView → ChatDetailView 傳的「待模擬」邀請。`matchID` 對應
/// MyMatchItem.id,模擬完通過 onInviteResolved(matchID, invitee, accepted) 回拋。
struct PendingDMInvitation: Equatable {
    let matchID: UUID
    let invitee: FollowPlayer
    let payload: OutgoingInvitationPayload
    let startDate: Date
    let endDate: Date
}
```

注意:`FollowPlayer` 是現有類型(`Components/InvitePickerSheet.swift` 已用),如果 `Equatable` 對 `FollowPlayer` 不可用,把 `PendingDMInvitation` 的 `Equatable` 拿掉(只在 `.task(id:)` 用 matchID,不需要整個 struct 可比較)。

- [ ] **Step 2: 給 `ChatBubble.BubbleContent` 加 case**

`ChatDetailView.swift` line 622-628:

```swift
enum BubbleContent {
    case incoming(String)
    case outgoing(String)
    case outgoingImage(Data)
    case invitation(date: String, location: String, startDate: Date, endDate: Date)
    case outgoingInvitation(OutgoingInvitationPayload)
    case systemMessage(String)
}
```

- [ ] **Step 3: 編譯,讓編譯器列出 `messageView` 的 switch 缺 case 錯誤**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build 2>&1 | grep -E "error:" | head -10
```

Expected: 有 1 處 "Switch must be exhaustive" 在 `messageView` 函數附近(約 line 244)。

- [ ] **Step 4: 在 `messageView` switch 加 `.outgoingInvitation` 路由(暫時 placeholder)**

`ChatDetailView.swift` 約 line 243-273(`messageView` 函數):

找到現有 switch:

```swift
switch message.content {
case .incoming(let text):
    incomingBubble(text, ...)
case .outgoing(let text):
    outgoingBubble(text, ...)
case .outgoingImage(let data):
    outgoingImageBubble(data, ...)
case .invitation(let date, let location, let start, let end):
    invitationCard(...)
case .systemMessage(let text):
    systemMessageBubble(text)
}
```

在 `.invitation` 後加新 case:

```swift
case .outgoingInvitation(let payload):
    outgoingInvitationCard(payload: payload, timestamp: message.timestamp)
```

- [ ] **Step 5: 加 `outgoingInvitationCard` view builder**

緊接 `invitationCard(...)` 函數之後(約 line 480 附近),加:

```swift
// MARK: - Outgoing Invitation Card

private func outgoingInvitationCard(payload: OutgoingInvitationPayload,
                                    timestamp: String?) -> some View {
    HStack(alignment: .top, spacing: Spacing.xs) {
        Spacer(minLength: 40)
        VStack(alignment: .leading, spacing: 6) {
            Text("🎾 你發起了約球邀請")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            Text(payload.title)
                .font(Typography.captionMedium)
                .foregroundColor(.white)
            Text("📅 \(payload.dateLabel) \(payload.timeRange)")
                .font(Typography.fieldLabel)
                .foregroundColor(.white.opacity(0.92))
            Text("📍 \(payload.location)")
                .font(Typography.fieldLabel)
                .foregroundColor(.white.opacity(0.92))
            Text("👥 \(payload.players)")
                .font(Typography.fieldLabel)
                .foregroundColor(.white.opacity(0.92))
            if let ts = timestamp {
                Text(ts)
                    .font(Typography.micro)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 2)
            }
        }
        .padding(Spacing.md)
        .frame(minWidth: 180, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.primary)
        )
    }
}
```

- [ ] **Step 6: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/ChatDetailView.swift
git commit -m "feat(chat): 加 BubbleContent.outgoingInvitation + 渲染卡

為 DM 邀請的外發氣泡定義 OutgoingInvitationPayload + Pending-
DMInvitation 兩個文件級類型(MyMatchesView 也要引用,需 internal)。
新增 .outgoingInvitation case 與 outgoingInvitationCard 渲染 — 右
對齊綠色卡片,顯示約球標題/日期/地點/人數。本任務尚未接駁,只是
先把類型與渲染落地。"
```

---

### Task 7: `InvitePickerSheet` 加禁用支持

**Files:**
- Modify: `TennisMatch/Components/InvitePickerSheet.swift`

**Why:** Spec §2.5 — 邀請前置校驗,已報名好友標灰禁用。

- [ ] **Step 1: 加新參數**

`InvitePickerSheet.swift` line 42-47:

```swift
struct InvitePickerSheet: View {
    let target: InviteTarget
    var disabledPlayerNames: Set<String> = []
    var disabledReason: String = "已報名"
    let onPick: (FollowPlayer) -> Void

    @Environment(FollowStore.self) private var followStore
    @Environment(\.dismiss) private var dismiss
```

- [ ] **Step 2: 行渲染依 disabled 狀態變樣式**

`InvitePickerSheet.swift` line 60-69(`ForEach` 內):

```swift
ForEach(mutualFollows) { player in
    let isDisabled = disabledPlayerNames.contains(player.name)
    Button {
        onPick(player)
        dismiss()
    } label: {
        playerRow(player, disabled: isDisabled)
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
}
```

- [ ] **Step 3: 改 `playerRow` 簽名,disabled 時換右側元素**

`InvitePickerSheet.swift` line 91-122,改成:

```swift
private func playerRow(_ player: FollowPlayer, disabled: Bool) -> some View {
    HStack(spacing: Spacing.sm) {
        ZStack {
            Circle()
                .fill(Theme.avatarPlaceholder)
                .frame(width: 40, height: 40)
            Text(String(player.name.prefix(1)))
                .font(Typography.labelSemibold)
                .foregroundColor(.white)
        }
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Spacing.xs) {
                Text(player.name)
                    .font(Typography.bodyMedium)
                    .foregroundColor(disabled ? Theme.textSecondary : Theme.textPrimary)
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
        if disabled {
            Text(disabledReason)
                .font(Typography.smallMedium)
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, Spacing.xs)
                .frame(height: 22)
                .background(Theme.chipUnselectedBg)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            Image(systemName: "paperplane.fill")
                .foregroundColor(Theme.primary)
        }
    }
    .padding(.vertical, Spacing.xs)
    .frame(minHeight: 44)
    .contentShape(Rectangle())
    .opacity(disabled ? 0.6 : 1.0)
}
```

- [ ] **Step 4: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`(現有調用點 `disabledPlayerNames` 用預設值,無編譯影響)。

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Components/InvitePickerSheet.swift
git commit -m "feat(invite-picker): 加 disabledPlayerNames 支援已報名標灰

行 disabled 時:
- 標題色變淡(textSecondary)
- 右側用「已報名」chip 替換 paperplane 圖標
- 整行 0.6 透明 + Button.disabled

現有調用點不傳這個參數,行為不變。"
```

---

### Task 8: ChatDetailView 加 `pendingInvitation` / `onInviteResolved` + 模擬流程

**Files:**
- Modify: `TennisMatch/Views/ChatDetailView.swift`

**Why:** Spec §3.2 — 邀請發出後 1.6s 內查檔期模擬回覆。

- [ ] **Step 1: 加新 init 參數 + State**

`ChatDetailView.swift` 約 line 11-32,在現有屬性後加:

```swift
struct ChatDetailView: View {
    let chat: MockChat
    var matchContext: String? = nil
    var initialMessage: String? = nil
    // ... 已有 onRemoveChat / onBlockUser ...

    /// 待模擬的 DM 邀請。若非 nil,進 view 立刻 push 外發邀請氣泡,1.6s 後查
    /// MockFriendSchedule 模擬接受/婉拒並通過 onInviteResolved 回拋。
    var pendingInvitation: PendingDMInvitation? = nil
    /// 模擬結束時上拋:(matchID, invitee, accepted)。
    var onInviteResolved: ((UUID, FollowPlayer, Bool) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(BookingStore.self) private var bookingStore
    // ...
}
```

把這兩個放在現有 var 屬性的最後,@Environment 之前。

- [ ] **Step 2: 加 `@State` 防重入**

跟其他 `@State` 放一起(約 line 28-35):

```swift
@State private var lastHandledInvitationID: UUID? = nil
```

- [ ] **Step 3: 在 body 上加 `.task(id:)` 處理模擬**

在 ChatDetailView body 末尾(`.toast($chatMenuToast, ...)` 之後)加:

```swift
.task(id: pendingInvitation?.matchID) {
    guard let p = pendingInvitation,
          p.matchID != lastHandledInvitationID else { return }
    lastHandledInvitationID = p.matchID

    // 1. 立刻 push 外發邀請氣泡
    let outTs = AppDateFormatter.hourMinute.string(from: Date())
    sentMessages.append(ChatBubble(
        .outgoingInvitation(p.payload), timestamp: outTs
    ))

    // 2. 等 1.6s,讓用戶看到外發氣泡
    try? await Task.sleep(nanoseconds: 1_600_000_000)
    guard !Task.isCancelled else { return }

    // 3. 查檔期決定接受 / 婉拒
    let inTs = AppDateFormatter.hourMinute.string(from: Date())
    if let conflict = MockFriendSchedule.conflict(
        for: p.invitee.name, start: p.startDate, end: p.endDate
    ) {
        let body = "不好意思,那時段我已有\(conflict.label),下次再約 🙏"
        sentMessages.append(ChatBubble(.incoming(body), timestamp: inTs))
        onInviteResolved?(p.matchID, p.invitee, false)
    } else {
        sentMessages.append(ChatBubble(.incoming("好的,我接受！"), timestamp: inTs))
        sentMessages.append(ChatBubble(.systemMessage(
            "🎾 約球已確認！\(p.payload.dateLabel) 在\(p.payload.location)"
        )))
        onInviteResolved?(p.matchID, p.invitee, true)
    }
}
```

- [ ] **Step 4: 確認 `allMessages` 的 isInvitationAccepted 不會誤匹配新 case**

`ChatDetailView.swift` line 100-110:

```swift
for msg in mockMessages {
    messages.append(msg)
    if case .invitation(let date, let location, _, _) = msg.content,
       isInvitationAccepted(date: date, location: location) {
        messages.append(ChatBubble(
            .systemMessage("🎾 約球已確認！\(date) 在\(location),記得準時到達！")
        ))
    }
}
```

只 match `.invitation` 不會誤匹配 `.outgoingInvitation` — Swift 區分嚴格。**保留現狀,無需改動。**

- [ ] **Step 5: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/ChatDetailView.swift
git commit -m "feat(chat): pendingInvitation 模擬流程

新增 ChatDetailView.pendingInvitation / onInviteResolved 參數。進 view
立刻 push 外發邀請氣泡,1.6s 後查 MockFriendSchedule.conflict(...) 模
擬被邀好友接受/婉拒,並通過回調上拋結果。lastHandledInvitationID 防
重入(.task 因父層 state 變動再次觸發時不重跑)。Task.isCancelled
保護用戶 1.6s 內退出聊天的場景 — 邀請丟失,符合 spec 設計。"
```

---

### Task 9: MyMatchesView 接駁 — pendingInvitation 狀態 / 改造 handleInvitePicked / 新 handleInviteResolved / 條件菜單 / 並發鎖

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift`

**Why:** Spec §3.1 §3.3 — 邀請發出時設置 pendingInvitation,接受時更新 registrants/players/status。

- [ ] **Step 1: 加新 `@State`**

`MyMatchesView.swift` 約 line 56,在 `selectedCompletedMatch` 旁:

```swift
@State private var selectedCompletedMatch: MyMatchItem?
@State private var pendingInvitation: PendingDMInvitation?
```

(Task 4 已加 `selectedRegistrantPlayer`,跟它放一起也可。)

- [ ] **Step 2: 加新回調 var(給 HomeView 接的接口)**

`MyMatchesView.swift` line 19 後加:

```swift
var onMatchCancelled: ((CancelledMatchPayload) -> Void)? = nil
/// 邀請被接受時回拋給 HomeView,讓首頁 MockMatch.currentPlayers +1。
/// sourceMatchID == nil(種子假資料 / 邀請接受 / 聊天接受)時 HomeView no-op。
var onInviteAccepted: ((UUID, FollowPlayer, UUID?) -> Void)? = nil
```

- [ ] **Step 3: confirmationDialog 條件化「私信邀請球友」**

`MyMatchesView.swift` line 386-413,用 `if` 包住該 Button:

```swift
.confirmationDialog("管理約球", isPresented: $showManageSheet, presenting: matchToManage) { match in
    Button("查看報名者") {
        registrantMatch = match
    }
    Button("編輯約球") {
        toast = .init(kind: .info, text: L10n.string("編輯約球功能即將推出"))
    }
    Button("關閉報名") {
        toast = .init(kind: .info, text: L10n.string("關閉報名功能即將推出"))
    }
    if match.playerCounts.current < match.playerCounts.max {
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

- [ ] **Step 4: 改造 `handleInvitePicked` — 構造 PendingDMInvitation**

`MyMatchesView.swift` line 182-208:

```swift
private func handleInvitePicked(player: FollowPlayer, target: InviteTarget) {
    // 並發保護 — 上一個邀請尚在 1.6s 模擬中,拒絕新發起。
    if pendingInvitation != nil {
        toast = .init(kind: .info, text: L10n.string("上一個邀請還在處理中"))
        return
    }

    // 找/建 chat with player
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

    // 約球邀請走新模擬流;賽事邀請仍走舊 matchContext 字串路徑(本次不改)。
    if case .match(let id, let title, let dateLabel, let timeRange, let location, let players) = target,
       let item = upcomingMatches.first(where: { $0.id == id }) {
        pendingInvitation = PendingDMInvitation(
            matchID: id,
            invitee: player,
            payload: OutgoingInvitationPayload(
                title: title,
                dateLabel: dateLabel,
                timeRange: timeRange,
                location: location,
                players: players
            ),
            startDate: item.startDate,
            endDate: item.endDate
        )
        selectedChatMatchContext = nil  // 不再用靜態 context 卡
    } else {
        // 賽事/兜底 — 保留舊邏輯
        selectedChatMatchContext = target.chatContext
    }
    selectedChat = chat

    if pendingInvitation == nil {
        // 賽事路徑保留舊提示
        toast = .init(kind: .success, text: L10n.string("已為你開啟與 \(player.name) 的私信"))
    }
}
```

- [ ] **Step 5: 加 `handleInviteResolved`**

緊接 `handleInvitePicked` 之後:

```swift
private func handleInviteResolved(matchID: UUID, friend: FollowPlayer, accepted: Bool) {
    // 釋放並發鎖,無論成功/失敗。
    defer { pendingInvitation = nil }

    guard accepted else {
        toast = .init(kind: .warning, text: L10n.string("\(friend.name) 婉拒了邀請"))
        return
    }
    guard let idx = upcomingMatches.firstIndex(where: { $0.id == matchID }) else { return }
    var match = upcomingMatches[idx]

    // 防重 +1(InvitePickerSheet 已禁用,這是兜底)
    guard !match.registrants.contains(where: { $0.name == friend.name }) else { return }

    // 1. registrants +1
    match.registrants.append(MatchRegistrant(
        name: friend.name,
        gender: friend.gender,
        ntrp: friend.ntrp,
        isOrganizer: false
    ))

    // 2. players 字串 currentPlayers +1
    let (cur, mx) = match.playerCounts
    let newCurrent = cur + 1
    let ntrpRange = match.players.components(separatedBy: "NTRP ").last ?? ""
    match.players = "\(newCurrent)/\(mx) · NTRP \(ntrpRange)"

    // 3. 滿員時 status 升級
    if newCurrent >= mx {
        match.status = .confirmed
    }

    upcomingMatches[idx] = match

    // 4. 同步 HomeView(若有 sourceMatchID)
    onInviteAccepted?(matchID, friend, match.sourceMatchID)

    toast = .init(kind: .success, text: L10n.string("\(friend.name) 已接受邀請"))
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}
```

- [ ] **Step 6: 改造 InvitePickerSheet 調用 — 傳 disabledPlayerNames**

`MyMatchesView.swift` line 553-557:

```swift
.sheet(item: $inviteTarget) { target in
    let disabled: Set<String> = {
        if case .match(let id, _, _, _, _, _) = target,
           let item = upcomingMatches.first(where: { $0.id == id }) {
            return Set(item.registrants.map { $0.name })
        }
        return []
    }()
    InvitePickerSheet(
        target: target,
        disabledPlayerNames: disabled,
        disabledReason: L10n.string("已報名")
    ) { player in
        handleInvitePicked(player: player, target: target)
    }
}
```

- [ ] **Step 7: 改造 `selectedChat` navigationDestination — 接 ChatDetailView 新參數 + 退出時清 pending**

`MyMatchesView.swift` line 298-301:

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
        // 用戶在 1.6s 內退出 → onInviteResolved 沒被調 → 兜底清 pending
        // 避免 pendingInvitation 永久卡住,後續邀請被並發鎖擋
        pendingInvitation = nil
    }
}
```

- [ ] **Step 8: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 9: Commit(尚未接 HomeView,但 MyMatchesView 內部閉環已通)**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "feat(my-matches): DM 邀請的發起/結算/並發鎖

- 新 @State pendingInvitation,並發鎖避免兩個邀請同時模擬
- handleInvitePicked 在 .match target 時構造 PendingDMInvitation
  傳給 ChatDetailView 走新模擬流(賽事/兜底仍走舊 matchContext 卡)
- handleInviteResolved:接受 → registrants +1, players 遞增,
  滿員時 status 升 .confirmed;婉拒 → toast 提示
- confirmationDialog 約球已滿員時隱藏「私信邀請球友」項
- InvitePickerSheet 傳入 disabledPlayerNames(已報名標灰)
- ChatDetailView .onDisappear 兜底清 pending,避免 1.6s 內退出後
  pendingInvitation 永久卡住"
```

---

### Task 10: HomeView 接 `onInviteAccepted` 同步首頁 currentPlayers

**Files:**
- Modify: `TennisMatch/Views/HomeView.swift`

**Why:** Spec §3.4 — 用戶自己創建的約球(MockMatch + MyMatchItem 雙邊存在,有 sourceMatchID)接受邀請後首頁 +1。種子假資料(sourceMatchID == nil)no-op。

- [ ] **Step 1: 找到現有 `MyMatchesView(...)` 調用,加新 callback**

`HomeView.swift` line 60-69:

```swift
case 1: MyMatchesView(
    sharedChats: $sharedChats,
    onGoHome: { selectedTab = 0 },
    onGoTournaments: { showTournaments = true },
    onMatchCancelled: { payload in
        handleMyMatchCancellation(payload)
    },
    onInviteAccepted: { _, _, sourceMatchID in
        // 種子假資料無 sourceMatchID → 首頁無對應 MockMatch,no-op
        guard let id = sourceMatchID,
              let idx = matches.firstIndex(where: { $0.id == id })
        else { return }
        matches[idx].currentPlayers += 1
    }
)
```

- [ ] **Step 2: 編譯確認**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "feat(home): 同步 DM 邀請接受後的 currentPlayers

當被邀好友接受邀請,且該約球有 sourceMatchID(來自首頁 MockMatch 報名
流而非種子假資料)時,首頁對應 MockMatch.currentPlayers +1。
種子假資料(sourceMatchID == nil)路徑下首頁本就沒這條 MockMatch,
no-op 即可。"
```

---

### Task 11: 端到端手動測試 + 修補 bug

**Files:** none(若無 bug);否則修對應文件。

**Why:** Spec 驗收標準 7 項全跑。

- [ ] **Step 1: Clean build + 開模擬器**

```bash
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -quiet clean build
```

然後 Xcode `⌘R` 跑起來。

- [ ] **Step 2: 場景 1 — Happy path 接受**

1. 我的約球 → 即將到來
2. 找一條「我發起的雙打 (2/4)」(`mockUpcomingMatchesInitial` 第 4 條,將軍澳運動場 18:00-20:00)
3. 點 管理 → 私信邀請球友
4. **空閒好友(不在 MockFriendSchedule.busySlots key 列表)**例如「林叔」、「Peter」(若 mutualFollows 有他們),選一個
5. 進入聊天:**預期**立刻看到右側綠色卡「🎾 你發起了約球邀請 / 我發起的雙打 / 將軍澳運動場 / 18:00-20:00 / 2/4 · NTRP 3.0-4.0」
6. 等 ~1.6s:**預期**左側出現「好的,我接受！」 + 系統消息「🎾 約球已確認！」
7. 看到 toast「\(name) 已接受邀請」,觸覺反饋
8. 返回 我的約球 → 「我發起的雙打」現在顯示 3/4,registrants 多了一個

- [ ] **Step 3: 場景 2 — 因衝突婉拒**

1. 重新打開模擬器或回到 我的約球
2. 找另一條「我發起的雙打 (2/4)」(將軍澳 18:00-20:00,daysFromNow=6)
3. 管理 → 私信邀請球友 → 選「嘉欣」(MockFriendSchedule 安排在第 6 天 9-11,**注意這個時段不衝突**)— 改選「莎拉」邀請到第 1 天 10:00 的約球?

   **注意:** 場景 2 需要找「該好友的 busySlot 與要邀請的約球時段重疊」。檢查 MockFriendSchedule 安排:
   - 莎拉 → 第 1 天 10:00-12:00
   - 嘉欣 → 第 6 天 9:00-11:00
   - 大衛 → 第 4 天 18:30-20:30

   `mockUpcomingMatchesInitial` 中的「我發起的雙打 (2/4) 將軍澳 第 6 天 18:00-20:00」與嘉欣的時段不重疊;考慮邀請大衛到「我發起的雙打 (2/4) 跑馬地 第 3 天」也不衝突。

   **如果發現所有 MyMatchItem 的時段都不能跟 MockFriendSchedule 對上,在 Task 5 的 busySlots 中再加一條,或調整 mockUpcomingMatchesInitial 的時段。** 例如增加:
   ```swift
   "莎拉":  [slot(daysFromNow: 3, startHour: 14, endHour: 16, label: "教練課"),  // 與「我發起的雙打」第 3 天 14:00 一致
            slot(daysFromNow: 1, startHour: 10, endHour: 12, label: "單打")]
   ```
   把這個調整作為 bug 修補一同 commit。

4. 邀請後等 ~1.6s
5. **預期:** 左側出現「不好意思,那時段我已有教練課,下次再約 🙏」+ toast「莎拉 婉拒了邀請」
6. 返回 我的約球 → registrants 不變,players 不變

- [ ] **Step 4: 場景 3 — InvitePickerSheet 防重複**

1. 場景 1 接受過的好友(例如林叔)
2. 同一條約球再點 管理 → 私信邀請球友
3. **預期:** 林叔那行標灰、不可點、右側顯示「已報名」chip

- [ ] **Step 5: 場景 4 — 滿員菜單隱藏**

1. 找一條 4/4 的滿員 match(若無,先把場景 1 那條邀至滿員,或臨時改 mockUpcomingMatchesInitial 一條為 4/4 測試完再改回)
2. 管理 →
3. **預期:** 菜單裡只有「查看報名者 / 編輯約球 / 關閉報名 / 取消約球」**沒有**「私信邀請球友」

- [ ] **Step 6: 場景 5 — 並發鎖**

1. 邀請好友 A → 進入聊天 → 立刻按返回
2. (在 1.6s 內)再進另一條 約球的 管理 → 私信邀請球友 → 選好友 B
3. **預期:** **不進聊天,toast 提示「上一個邀請還在處理中」** — 但因為 .onDisappear 已清掉 pending(Step 1 結尾返回時觸發),這個場景實際難以復現。**接受結果:** 並發鎖在用戶不返回的情況下生效;返回會清除鎖。

- [ ] **Step 7: 場景 6 — 1.6s 內退出聊天**

1. 邀請好友 → 立刻按返回(< 1.6s)
2. **預期:** 不報錯,沒 toast(因為 onInviteResolved 沒調)
3. 再進同一聊天:**預期**不會重跑模擬(`lastHandledInvitationID` 仍為該 matchID,但 .onDisappear 清了 pendingInvitation,進來時 pendingInvitation == nil,.task guard 直接 return)
4. 邀請丟失(spec 設計)

- [ ] **Step 8: 場景 7 — 查看報名者跳 PublicProfileView**

(Task 4 已驗,這裡再走一次確認沒回退。)

1. 任一約球 → 管理 → 查看報名者 → 點任一球員
2. **預期:** 進 PublicProfileView,看到頭像/NTRP

- [ ] **Step 9: 若 Step 3 發現 MockFriendSchedule 時段沒對上,調整並 commit**

```bash
git add TennisMatch/Models/MockFriendSchedule.swift  # 或 mockUpcomingMatchesInitial 調整
git commit -m "fix(mock-schedule): 調整 busySlots 時段對齊現有 mock 約球

第一輪手測發現 MockFriendSchedule 的好友檔期與 mockUpcomingMatches-
Initial 的時段沒有重疊,導致「衝突婉拒」分支 demo 無法觸發。把莎拉
加一個第 3 天 14:00-16:00 的教練課,正好對上「我發起的雙打 跑馬地」
的時段。"
```

- [ ] **Step 10: 若全部場景通過,標記任務完成**

最終 push:

```bash
git push
```

---

## Self-Review

### Spec 覆蓋核對

| Spec 章節 / 要求 | 對應 Task |
|---|---|
| §2.1 MockFriendSchedule 文件 | Task 5 |
| §2.2 MatchRegistrant 加 gender + backfill | Task 2 |
| §2.3 OutgoingInvitationPayload + .outgoingInvitation case | Task 6 |
| §2.4 ChatDetailView 新參數 + 模擬流程 | Task 8 |
| §2.5 InvitePickerSheet disabled 支持 | Task 7 |
| §3.1 邀請發出狀態流(handleInvitePicked) | Task 9 |
| §3.2 ChatDetailView .task 模擬 | Task 8 |
| §3.3 handleInviteResolved + 數據回寫 | Task 9 |
| §3.4 HomeView 同步 currentPlayers | Task 10 |
| §邊界 #1 已報名兜底防重 +1 | Task 9 (handleInviteResolved guard) |
| §邊界 #2 滿員隱藏菜單項 | Task 9 (confirmationDialog if) |
| §邊界 #3 1.6s 內退出 | Task 8 (Task.isCancelled) + Task 9 (.onDisappear 清 pending) |
| §邊界 #5 並發單 pending | Task 9 (handleInvitePicked guard) |
| §邊界 #6 滿員時 status 升 .confirmed | Task 9 (handleInviteResolved 第 3 步) |
| §邊界 #7 isInvitationAccepted 不誤匹配 | Task 8 Step 4 確認 |
| §查看報名者 → PublicProfile | Task 4 |
| §本地化新 strings | 散落各 Task 的 `L10n.string(...)` 調用,Localizable.xcstrings 由 Xcode auto-extract 補(獨立 chore commit,本計畫不含) |

無遺漏。

### Type / 命名一致性核對

- `OutgoingInvitationPayload` — Task 6 定義,Task 8 / Task 9 引用 ✓
- `PendingDMInvitation` — Task 6 定義,Task 8 / Task 9 引用 ✓
- `BubbleContent.outgoingInvitation` — Task 6 加,Task 8 messageView routing 引用 ✓
- `MatchRegistrant(gender:)` — Task 2 加欄位,Task 9 構造時用,Task 4 讀取時用 ✓
- `MyMatchItem.players` / `.status` — Task 3 改 var,Task 9 寫入 ✓
- `pendingInvitation: PendingDMInvitation?` — Task 8 init 參數,Task 9 @State + 傳遞 ✓
- `onInviteResolved: ((UUID, FollowPlayer, Bool) -> Void)?` — Task 8 init 參數,Task 9 `handleInviteResolved` 函數簽名匹配 ✓
- `onInviteAccepted: ((UUID, FollowPlayer, UUID?) -> Void)?` — Task 9 declare,Task 10 implement ✓
- `MockFriendSchedule.conflict(for:start:end:) -> FriendBusySlot?` — Task 5 定義,Task 8 引用 ✓

無不一致。

### Placeholder / TODO 掃描

無 TBD / TODO / "implement later" / "fill in details"。所有步驟含實際代碼或精確指令。

### 風險

- **MockFriendSchedule 時段可能對不上 mock 約球** → Task 11 Step 3 / Step 9 在手測中發現並修正,作為計畫一部分。
- **Task 5 Step 3(Xcode project.pbxproj 加文件)** 在不同 Xcode 版本/配置下行為不同。如果 project 用 file system synchronized groups,自動偵測;否則需 UI 手動加。已給檢測命令。
- **`FollowPlayer` 是否 `Equatable`** 影響 Task 6 `PendingDMInvitation: Equatable` 能否成立。如果不能,把 `Equatable` 拿掉 — `.task(id:)` 用的是 `pendingInvitation?.matchID` 即 UUID,本來就不需要整個 struct 比較。

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-25-dm-invite-flow.md`. Two execution options:

1. **Subagent-Driven (recommended)** — 派 fresh subagent 跑每個 task,任務間做兩階段 review,迭代快、上下文乾淨。
2. **Inline Execution** — 在當前 session 用 executing-plans 跑,批量執行 + checkpoint review。

哪個?
