# Navigation Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up every button in the app to its correct destination — 10 new pages + 7 existing page modifications, as defined in `docs/superpowers/specs/2026-04-21-navigation-flow-design.md`.

**Architecture:** All new pages are SwiftUI views using mock data (no backend). Navigation uses NavigationStack push for page transitions, sheet for half-screen overlays, fullScreenCover for modal flows, and confirmationDialog for action menus. All pages follow existing Theme/Typography/Spacing tokens and include 2 previews (iPhone SE + iPhone 15 Pro).

**Tech Stack:** SwiftUI, iOS 16+, SF Symbols, no third-party dependencies.

---

## File Structure

### New Files (10 views)
- `TennisMatch/Views/SettingsView.swift` — App settings with logout
- `TennisMatch/Views/HelpView.swift` — FAQ + contact support
- `TennisMatch/Views/NotificationsView.swift` — Match-related notifications
- `TennisMatch/Views/BlockListView.swift` — Blocked users list
- `TennisMatch/Views/InviteFriendsView.swift` — Share invite link
- `TennisMatch/Views/ReviewsView.swift` — Ratings received + pending
- `TennisMatch/Views/FollowingView.swift` — Followed players feed
- `TennisMatch/Views/PublicProfileView.swift` — Read-only player profile
- `TennisMatch/Views/MatchAssistantView.swift` — AI-recommended matches
- `TennisMatch/Views/AchievementsView.swift` �� All achievement badges

### Modified Files (7 views)
- `TennisMatch/Views/HomeView.swift` — Drawer menu wiring + signup→chat redirect
- `TennisMatch/Views/MatchDetailView.swift` — Wire signup, DM, follow buttons
- `TennisMatch/Views/TournamentView.swift` — Wire tournament signup + follow
- `TennisMatch/Views/MyMatchesView.swift` — Manage ActionSheet + reject invite
- `TennisMatch/Views/ChatDetailView.swift` — "..." menu with group/DM options
- `TennisMatch/Views/ProfileView.swift` — Wire settings, tournament "全部", achievements "全部"
- `TennisMatch/Views/LoginView.swift` — Wire Apple login, WeChat, register, help links

---

## Phase 1: Simple New Pages (standalone, no cross-dependencies)

### Task 1: SettingsView

**Files:**
- Create: `TennisMatch/Views/SettingsView.swift`

- [ ] **Step 1: Create SettingsView with grouped list**

```swift
//
//  SettingsView.swift
//  TennisMatch
//
//  設定頁面
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var matchReminders = true
    @State private var chatNotifications = true
    @State private var tournamentUpdates = true
    @State private var profileVisibility = "所有人"
    @State private var dmPermission = "所有人"
    @State private var showLogoutAlert = false

    var body: some View {
        List {
            accountSection
            notificationSection
            privacySection
            aboutSection
            logoutSection
        }
        .listStyle(.insetGrouped)
        .background(Theme.background)
        .scrollContentBackground(.hidden)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("設定")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .alert("退出登錄", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) {}
            Button("確認退出", role: .destructive) {
                // TODO: clear user state, navigate to LoginView
            }
        } message: {
            Text("確定要退出登錄嗎？")
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section {
            settingsRow(icon: "phone.fill", title: "手機號碼", value: "+86 138****8888")
            settingsRow(icon: "lock.fill", title: "修改密碼", showChevron: true)
            settingsRow(icon: "link", title: "關聯帳號", value: "微信、Apple")
        } header: {
            Text("帳號與安全")
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle(isOn: $matchReminders) {
                Label("約球提醒", systemImage: "bell.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textPrimary)
            }
            .tint(Theme.primary)

            Toggle(isOn: $chatNotifications) {
                Label("聊天消息", systemImage: "bubble.left.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textPrimary)
            }
            .tint(Theme.primary)

            Toggle(isOn: $tournamentUpdates) {
                Label("賽事更新", systemImage: "trophy.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textPrimary)
            }
            .tint(Theme.primary)
        } header: {
            Text("通知偏好")
        }
    }

    private var privacySection: some View {
        Section {
            Picker(selection: $profileVisibility) {
                Text("所有人").tag("所有人")
                Text("僅關注者").tag("僅關注者")
                Text("僅自己").tag("僅自己")
            } label: {
                Label("誰能看到我的資料", systemImage: "eye.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textPrimary)
            }

            Picker(selection: $dmPermission) {
                Text("所有人").tag("所有人")
                Text("僅關注者").tag("僅關注者")
                Text("關閉").tag("關閉")
            } label: {
                Label("誰能私信我", systemImage: "envelope.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textPrimary)
            }
        } header: {
            Text("隱私設置")
        }
    }

    private var aboutSection: some View {
        Section {
            settingsRow(icon: "info.circle.fill", title: "版本", value: "v0.1.0")
            settingsRow(icon: "doc.text.fill", title: "用戶協議", showChevron: true)
            settingsRow(icon: "hand.raised.fill", title: "隱私政策", showChevron: true)
        } header: {
            Text("關於我們")
        }
    }

    private var logoutSection: some View {
        Section {
            Button {
                showLogoutAlert = true
            } label: {
                HStack {
                    Spacer()
                    Text("退出登錄")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.requiredText)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers

    private func settingsRow(icon: String, title: String, value: String? = nil, showChevron: Bool = false) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.system(size: 15))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        SettingsView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        SettingsView()
    }
}
```

- [ ] **Step 2: Build and verify preview renders**

Run: Xcode build or `xcodebuild` to verify no compile errors.

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/SettingsView.swift
git commit -m "feat: add SettingsView with account, notification, privacy, and logout sections"
```

---

### Task 2: HelpView

**Files:**
- Create: `TennisMatch/Views/HelpView.swift`

- [ ] **Step 1: Create HelpView with FAQ and contact support**

```swift
//
//  HelpView.swift
//  TennisMatch
//
//  幫助 — FAQ + 聯繫客服
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedFAQ: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(faqItems) { item in
                    faqRow(item)
                }

                contactSection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("幫助")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func faqRow(_ item: FAQItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedFAQ = expandedFAQ == item.id ? nil : item.id
                }
            } label: {
                HStack {
                    Text(item.question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: expandedFAQ == item.id ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Spacing.md)
                .frame(minHeight: 44)
            }

            if expandedFAQ == item.id {
                Text(item.answer)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textBody)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var contactSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("找不到答案？")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Button {
                if let url = URL(string: "mailto:support@letstennis.app") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                    Text("聯繫客服")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.top, Spacing.md)
    }
}

// MARK: - FAQ Data

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

private let faqItems: [FAQItem] = [
    FAQItem(question: "如何發布約球？", answer: "點擊底部 Tab 欄中間的「+」按鈕，填寫約球信息後點擊「發布約球」即可。"),
    FAQItem(question: "如何報名別人的約球？", answer: "在首頁瀏覽約球列表，點擊感興趣的約球卡片進入詳情頁，點擊「報名」按鈕確認即可。"),
    FAQItem(question: "什麼是 NTRP？", answer: "NTRP（National Tennis Rating Program）是國際通用的網球技術分級標準，從 1.0（初學者）到 7.0（世界級），幫助你找到水平匹配的對手。"),
    FAQItem(question: "如何取消已報名的約球？", answer: "進入「我的約球」頁面，找到你要取消的約球，點擊「取消」按鈕確認即可。取消後會通知所有參與者。"),
    FAQItem(question: "如何創建賽事？", answer: "從側邊欄進入「賽事」頁面，點擊右上角「+ 建立賽事」按鈕，填寫賽事信息後發布。"),
    FAQItem(question: "如何封鎖其他��戶？", answer: "進入對方的個人主頁，點擊「封鎖」按鈕即可。被封鎖的用戶無法查看你的資料和約球，也無法向你發送私信。"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        HelpView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        HelpView()
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/HelpView.swift
git commit -m "feat: add HelpView with FAQ accordion and contact support"
```

---

### Task 3: NotificationsView

**Files:**
- Create: `TennisMatch/Views/NotificationsView.swift`

- [ ] **Step 1: Create NotificationsView with match-related notifications**

```swift
//
//  NotificationsView.swift
//  TennisMatch
//
//  通知 — 約球相關通知
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [MatchNotification] = mockNotifications
    @State private var selectedMatchDetail: MatchDetailData?

    var body: some View {
        VStack(spacing: 0) {
            if notifications.isEmpty {
                emptyState
            } else {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            for i in notifications.indices {
                                notifications[i].isRead = true
                            }
                        }
                    } label: {
                        Text("全部已讀")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.primary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(notifications) { notification in
                            notificationRow(notification)
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("通知")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func notificationRow(_ notification: MatchNotification) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(notification.iconBg)
                    .frame(width: 40, height: 40)
                Image(systemName: notification.icon)
                    .font(.system(size: 16))
                    .foregroundColor(notification.iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 14, weight: notification.isRead ? .regular : .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(notification.body)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textBody)
                Text(notification.time)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(Theme.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(notification.isRead ? .white : Theme.primaryLight.opacity(0.3))
        .onTapGesture {
            if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[idx].isRead = true
            }
            // TODO: navigate to MatchDetailView via selectedMatchDetail
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.textSecondary)
            Text("暫無通知")
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data

private struct MatchNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let body: String
    let time: String
    var isRead: Bool

    var icon: String {
        switch type {
        case .signUp: return "person.badge.plus"
        case .accepted: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .updated: return "arrow.triangle.2.circlepath"
        }
    }

    var iconBg: Color {
        switch type {
        case .signUp: return Theme.primaryLight
        case .accepted: return Theme.confirmedBg
        case .cancelled: return Theme.requiredBg
        case .updated: return Theme.pendingBg
        }
    }

    var iconColor: Color {
        switch type {
        case .signUp: return Theme.primary
        case .accepted: return Theme.primary
        case .cancelled: return Theme.requiredText
        case .updated: return Theme.pendingBadge
        }
    }
}

private enum NotificationType {
    case signUp, accepted, cancelled, updated
}

private let mockNotifications: [MatchNotification] = [
    MatchNotification(type: .signUp, title: "新的報名", body: "王強 報名了你發起的雙打約球（04/20 跑馬地）", time: "10 分鐘前", isRead: false),
    MatchNotification(type: .accepted, title: "報名已接受", body: "你報名的莎拉單打約球（04/19 維多利亞公園）已確認", time: "2 小時前", isRead: false),
    MatchNotification(type: .updated, title: "約球更新", body: "志明 的單打約球時間更改為 16:30", time: "3 小時前", isRead: true),
    MatchNotification(type: .cancelled, title: "約球取消", body: "小美 取消了雙打約球（04/22 沙田公園）", time: "昨天", isRead: true),
    MatchNotification(type: .signUp, title: "新的報名", body: "嘉欣 報名了你發起的雙打約球（04/20 跑馬地）", time: "昨天", isRead: true),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        NotificationsView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        NotificationsView()
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/NotificationsView.swift
git commit -m "feat: add NotificationsView with match-related notification types"
```

---

### Task 4: BlockListView

**Files:**
- Create: `TennisMatch/Views/BlockListView.swift`

- [ ] **Step 1: Create BlockListView**

```swift
//
//  BlockListView.swift
//  TennisMatch
//
//  封鎖名單
//

import SwiftUI

struct BlockListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blockedUsers: [BlockedUser] = mockBlockedUsers
    @State private var userToUnblock: BlockedUser?
    @State private var showUnblockAlert = false

    var body: some View {
        VStack(spacing: 0) {
            if blockedUsers.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textSecondary)
                    Text("沒有封鎖的用戶")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(blockedUsers) { user in
                        HStack(spacing: Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: 0xE0E0E0))
                                    .frame(width: 44, height: 44)
                                Text(String(user.name.prefix(1)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                                Text("封鎖於 \(user.blockedDate)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }

                            Spacer()

                            Button {
                                userToUnblock = user
                                showUnblockAlert = true
                            } label: {
                                Text("解除封鎖")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.textBody)
                                    .padding(.horizontal, Spacing.sm)
                                    .frame(height: 30)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Theme.inputBorder, lineWidth: 1)
                                    }
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("封鎖名單")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .alert("解除封鎖", isPresented: $showUnblockAlert) {
            Button("取消", role: .cancel) { userToUnblock = nil }
            Button("確認解除", role: .destructive) {
                if let user = userToUnblock {
                    withAnimation {
                        blockedUsers.removeAll { $0.id == user.id }
                    }
                }
                userToUnblock = nil
            }
        } message: {
            if let user = userToUnblock {
                Text("確定要解除對「\(user.name)」的封鎖嗎？")
            }
        }
    }
}

// MARK: - Data

private struct BlockedUser: Identifiable {
    let id = UUID()
    let name: String
    let blockedDate: String
}

private let mockBlockedUsers: [BlockedUser] = [
    BlockedUser(name: "張三", blockedDate: "2026/04/10"),
    BlockedUser(name: "李四", blockedDate: "2026/03/25"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        BlockListView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        BlockListView()
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/BlockListView.swift
git commit -m "feat: add BlockListView with unblock confirmation"
```

---

### Task 5: InviteFriendsView

**Files:**
- Create: `TennisMatch/Views/InviteFriendsView.swift`

- [ ] **Step 1: Create InviteFriendsView with share sheet**

```swift
//
//  InviteFriendsView.swift
//  TennisMatch
//
//  邀請好友
//

import SwiftUI

struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    private let inviteCode = "LT2026XUE"
    private let inviteLink = "https://letstennis.app/invite/LT2026XUE"

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer().frame(height: Spacing.xl)

            // Illustration
            ZStack {
                Circle()
                    .fill(Theme.primaryLight)
                    .frame(width: 100, height: 100)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.primary)
            }

            Text("邀請好友一起打球")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Text("分享你的邀請碼給朋友，一起加入 Let's Tennis")
                .font(.system(size: 14))
                .foregroundColor(Theme.textBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            // Invite code card
            VStack(spacing: Spacing.sm) {
                Text("你的邀請碼")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)

                Text(inviteCode)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                    .tracking(4)

                Button {
                    UIPasteboard.general.string = inviteCode
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                        Text("複製邀請碼")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Theme.primary)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
            .padding(.horizontal, Spacing.md)

            Spacer()

            // Share button
            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                    Text("分享給朋友")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("邀請好友")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["來 Let's Tennis 一起打網球！我的邀請碼：\(inviteCode)\n\(inviteLink)"])
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        InviteFriendsView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        InviteFriendsView()
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/InviteFriendsView.swift
git commit -m "feat: add InviteFriendsView with invite code and share sheet"
```

---

### Task 6: AchievementsView

**Files:**
- Create: `TennisMatch/Views/AchievementsView.swift`

- [ ] **Step 1: Create AchievementsView with badge grid**

```swift
//
//  AchievementsView.swift
//  TennisMatch
//
//  成就徽章
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("已解鎖 · \(mockAchievements.filter(\.unlocked).count)/\(mockAchievements.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(mockAchievements) { badge in
                        achievementBadge(badge)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("成就")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func achievementBadge(_ badge: Achievement) -> some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(badge.unlocked ? Theme.primaryLight : Color(hex: 0xF3F4F6))
                    .frame(width: 56, height: 56)
                Text(badge.icon)
                    .font(.system(size: 26))
                    .opacity(badge.unlocked ? 1 : 0.4)
            }

            Text(badge.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .opacity(badge.unlocked ? 1 : 0.4)

            Text(badge.description)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .opacity(badge.unlocked ? 1 : 0.4)
        }
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(badge.unlocked ? 0.06 : 0.02), radius: 4, y: 1)
    }
}

// MARK: - Data

private struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let description: String
    let unlocked: Bool
}

private let mockAchievements: [Achievement] = [
    Achievement(icon: "🏆", name: "新手上路", description: "完成第一場約球", unlocked: true),
    Achievement(icon: "⚡", name: "活躍球手", description: "累計完成 10 場約球", unlocked: true),
    Achievement(icon: "✨", name: "守時達人", description: "連續 5 場準時到達", unlocked: true),
    Achievement(icon: "🎯", name: "高手之路", description: "NTRP 達到 4.0", unlocked: false),
    Achievement(icon: "🤝", name: "社交達人", description: "與 20 位不同球友打球", unlocked: false),
    Achievement(icon: "🏅", name: "賽事冠軍", description: "贏得一場賽事冠軍", unlocked: true),
    Achievement(icon: "🔥", name: "連勝王", description: "比賽連勝 5 場", unlocked: false),
    Achievement(icon: "💪", name: "鐵人", description: "一週打球 5 次", unlocked: false),
    Achievement(icon: "⭐", name: "��星好評", description: "累計獲得 10 個五星評價", unlocked: true),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        AchievementsView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        AchievementsView()
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/AchievementsView.swift
git commit -m "feat: add AchievementsView with badge grid"
```

---

### Task 7: ReviewsView

**Files:**
- Create: `TennisMatch/Views/ReviewsView.swift`

- [ ] **Step 1: Create ReviewsView with received/pending tabs**

```swift
//
//  ReviewsView.swift
//  TennisMatch
//
//  評價 — 收到的評價 / 待評價
//

import SwiftUI

struct ReviewsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = "收到的評價"
    @State private var pendingReviews: [PendingReview] = mockPendingReviews
    @State private var reviewTarget: PendingReview?
    @State private var reviewRating: Int = 5
    @State private var reviewText = ""
    @State private var showReviewSheet = false
    @State private var showSubmitToast = false

    var body: some View {
        VStack(spacing: 0) {
            filterTabs

            ScrollView {
                VStack(spacing: Spacing.sm) {
                    if selectedTab == "收到的評價" {
                        ForEach(mockReceivedReviews) { review in
                            receivedReviewCard(review)
                        }
                    } else {
                        ForEach(pendingReviews) { review in
                            pendingReviewCard(review)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("評價")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            if let target = reviewTarget {
                ReviewFormSheet(
                    targetName: target.name,
                    rating: $reviewRating,
                    text: $reviewText,
                    onSubmit: {
                        withAnimation {
                            pendingReviews.removeAll { $0.id == target.id }
                        }
                        showReviewSheet = false
                        showSubmitToast = true
                        reviewTarget = nil
                        reviewRating = 5
                        reviewText = ""
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .overlay(alignment: .top) {
            if showSubmitToast {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("評價提交成功")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Capsule().fill(Theme.textBody))
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, Spacing.lg)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showSubmitToast = false }
                    }
                }
            }
        }
    }

    private var filterTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(["收到的評價", "待評價"], id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Text(tab)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedTab == tab ? Theme.primary : Theme.textBody)
                                .frame(maxWidth: .infinity)
                            Rectangle()
                                .fill(selectedTab == tab ? Theme.primary : .clear)
                                .frame(width: 60, height: 3)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.top, Spacing.sm)
            Theme.inputBorder.frame(height: 1)
        }
        .background(.white)
    }

    private func receivedReviewCard(_ review: ReceivedReview) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xE0E0E0))
                    .frame(width: 40, height: 40)
                Text(String(review.name.prefix(1)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(review.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(review.date)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < review.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(i < review.rating ? Color(hex: 0xFACC15) : Theme.textSecondary)
                    }
                }

                Text(review.comment)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textBody)
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func pendingReviewCard(_ review: PendingReview) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xE0E0E0))
                    .frame(width: 40, height: 40)
                Text(String(review.name.prefix(1)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(review.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text(review.matchInfo)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button {
                reviewTarget = review
                showReviewSheet = true
            } label: {
                Text("評價")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 30)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Review Form Sheet

private struct ReviewFormSheet: View {
    let targetName: String
    @Binding var rating: Int
    @Binding var text: String
    var onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("評價 \(targetName)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Spacing.xs) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        rating = i
                    } label: {
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundColor(i <= rating ? Color(hex: 0xFACC15) : Theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            TextField("說說你的打球體驗...", text: $text, axis: .vertical)
                .font(.system(size: 14))
                .lineLimit(3...5)
                .padding(Spacing.sm)
                .background(Theme.inputBg)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.inputBorder, lineWidth: 1)
                )

            Spacer()

            Button(action: onSubmit) {
                Text("提交評價")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }
}

// MARK: - Data

private struct ReceivedReview: Identifiable {
    let id = UUID()
    let name: String
    let rating: Int
    let comment: String
    let date: String
}

private struct PendingReview: Identifiable {
    let id = UUID()
    let name: String
    let matchInfo: String
}

private let mockReceivedReviews: [ReceivedReview] = [
    ReceivedReview(name: "莎拉", rating: 5, comment: "很準時，球技很好，打得很開心！", date: "04/19"),
    ReceivedReview(name: "王強", rating: 4, comment: "配合默契的雙打搭檔", date: "04/15"),
    ReceivedReview(name: "小美", rating: 5, comment: "球品好，推薦！", date: "04/10"),
]

private let mockPendingReviews: [PendingReview] = [
    PendingReview(name: "志���", matchInfo: "04/21 單打 · 香港網球中心"),
    PendingReview(name: "嘉欣", matchInfo: "04/18 雙打 · 沙田公園"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        ReviewsView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        ReviewsView()
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/ReviewsView.swift
git commit -m "feat: add ReviewsView with received/pending tabs and rating form"
```

---

## Phase 2: Pages With Cross-Navigation

### Task 8: PublicProfileView

**Files:**
- Create: `TennisMatch/Views/PublicProfileView.swift`

- [ ] **Step 1: Create PublicProfileView (read-only profile with follow/DM/block)**

```swift
//
//  PublicProfileView.swift
//  TennisMatch
//
//  球友公開主頁 — 只讀版個人資料
//

import SwiftUI

struct PublicProfileView: View {
    let player: PublicPlayerData
    @Environment(\.dismiss) private var dismiss
    @State private var isFollowing = false
    @State private var showBlockAlert = false
    @State private var selectedChat: MockChat?

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    statsCard
                    matchHistoryCard
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, 100)
            }

            bottomBar
        }
        .background(Theme.background)
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .alert("封鎖用戶", isPresented: $showBlockAlert) {
            Button("取消", role: .cancel) {}
            Button("確認封鎖", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("封鎖「\(player.name)」後，對方將無法查看你的資料和約球，也無法向你發送私信。")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 80)

            HStack(alignment: .top, spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                    Text(String(player.name.prefix(1)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.primary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(player.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text(player.gender == .female ? "♀" : "♂")
                            .font(.system(size: 18))
                            .foregroundColor(player.gender == .female ? Theme.genderFemale : Theme.genderMale)
                    }

                    Text("NTRP \(player.ntrp) · 信譽分 \(player.reputation)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))

                    Text(player.bio)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)

            // Follow + block row
            HStack {
                Button {
                    withAnimation { isFollowing.toggle() }
                } label: {
                    Text(isFollowing ? "已關注" : "關注")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isFollowing ? Theme.textBody : .white)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 32)
                        .background(isFollowing ? .white : .white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.white.opacity(0.6), lineWidth: 1)
                        )
                }

                Button {
                    showBlockAlert = true
                } label: {
                    Image(systemName: "nosign")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
        }
        .background(Theme.primary)
    }

    // MARK: - Stats

    private var statsCard: some View {
        HStack(spacing: Spacing.xs) {
            statItem(value: player.ntrp, label: "NTRP")
            statItem(value: "\(player.reputation)", label: "信譽積分")
            statItem(value: "\(player.matchCount)", label: "場次")
        }
        .padding(.vertical, Spacing.sm)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    // MARK: - Match History

    private var matchHistoryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("🎾 約球記錄")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            ForEach(player.recentMatches, id: \.self) { match in
                HStack(spacing: Spacing.sm) {
                    Text("📅")
                        .font(.system(size: 12))
                    Text(match)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textBody)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        Button {
            selectedChat = MockChat(
                type: .personal(name: player.name, symbol: player.gender == .female ? "♀" : "♂", symbolColor: player.gender == .female ? Theme.genderFemale : Theme.genderMale),
                lastMessage: "點擊開始聊天",
                time: "now",
                unreadCount: 0
            )
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 14))
                Text("私信")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xl)
        .background(
            Rectangle()
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 4, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Data

struct PublicPlayerData: Hashable {
    let name: String
    let gender: Gender
    let ntrp: String
    let reputation: Int
    let matchCount: Int
    let bio: String
    let recentMatches: [String]
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        PublicProfileView(player: previewPlayer)
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        PublicProfileView(player: previewPlayer)
    }
}

private let previewPlayer = PublicPlayerData(
    name: "莎���", gender: .female, ntrp: "3.5", reputation: 90, matchCount: 28,
    bio: "週末固定在維多利亞公園打球",
    recentMatches: [
        "04/19 單打 · 維多利亞公園",
        "04/15 雙打 · 跑馬地",
        "04/10 單打 · 九龍仔公園",
    ]
)
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/PublicProfileView.swift
git commit -m "feat: add PublicProfileView with follow, DM, and block actions"
```

---

### Task 9: FollowingView

**Files:**
- Create: `TennisMatch/Views/FollowingView.swift`

- [ ] **Step 1: Create FollowingView with player list**

```swift
//
//  FollowingView.swift
//  TennisMatch
//
//  關注 — 已關注球友列表
//

import SwiftUI

struct FollowingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var followedPlayers: [FollowedPlayer] = mockFollowedPlayers
    @State private var playerToUnfollow: FollowedPlayer?
    @State private var showUnfollowAlert = false
    @State private var selectedPlayer: PublicPlayerData?

    var body: some View {
        VStack(spacing: 0) {
            if followedPlayers.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Spacer()
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textSecondary)
                    Text("還沒有關注的球友")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.sm) {
                        ForEach(followedPlayers) { player in
                            playerRow(player)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                }
            }
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("關注")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .navigationDestination(item: $selectedPlayer) { player in
            PublicProfileView(player: player)
        }
        .alert("取消關注", isPresented: $showUnfollowAlert) {
            Button("取消", role: .cancel) { playerToUnfollow = nil }
            Button("確認", role: .destructive) {
                if let p = playerToUnfollow {
                    withAnimation {
                        followedPlayers.removeAll { $0.id == p.id }
                    }
                }
                playerToUnfollow = nil
            }
        } message: {
            if let p = playerToUnfollow {
                Text("確定要取消關注「\(p.name)」嗎？")
            }
        }
    }

    private func playerRow(_ player: FollowedPlayer) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xE0E0E0))
                    .frame(width: 48, height: 48)
                Text(String(player.name.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(player.gender == .female ? "♀" : "♂")
                        .font(.system(size: 15))
                        .foregroundColor(player.gender == .female ? Theme.genderFemale : Theme.genderMale)
                }
                Text("NTRP \(player.ntrp) · \(player.latestActivity)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button {
                playerToUnfollow = player
                showUnfollowAlert = true
            } label: {
                Text("已關注")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textBody)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 30)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    }
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPlayer = PublicPlayerData(
                name: player.name,
                gender: player.gender,
                ntrp: player.ntrp,
                reputation: 88,
                matchCount: 20,
                bio: "熱愛網球",
                recentMatches: ["04/19 單打 · 維多利亞公園"]
            )
        }
    }
}

// MARK: - Data

private struct FollowedPlayer: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let ntrp: String
    let latestActivity: String
}

private let mockFollowedPlayers: [FollowedPlayer] = [
    FollowedPlayer(name: "莎拉", gender: .female, ntrp: "3.5", latestActivity: "剛發布了一場單打約球"),
    FollowedPlayer(name: "王強", gender: .male, ntrp: "4.0", latestActivity: "報名了春季公開賽"),
    FollowedPlayer(name: "小美", gender: .female, ntrp: "3.0", latestActivity: "3 天前活躍"),
    FollowedPlayer(name: "志明", gender: .male, ntrp: "4.5", latestActivity: "1 週前活躍"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        FollowingView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        FollowingView()
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/FollowingView.swift
git commit -m "feat: add FollowingView with player list and unfollow"
```

---

### Task 10: MatchAssistantView

**Files:**
- Create: `TennisMatch/Views/MatchAssistantView.swift`

- [ ] **Step 1: Create MatchAssistantView with recommended match feed**

```swift
//
//  MatchAssistantView.swift
//  TennisMatch
//
//  約球助理 — 智能推薦匹配的約球
//

import SwiftUI

struct MatchAssistantView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Intro card
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Theme.primaryLight)
                            .frame(width: 44, height: 44)
                        Text("🤖")
                            .font(.system(size: 22))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("約球助理")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("根據你的 NTRP 3.5、常去球場和空閒時間為你推薦")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("為你推薦")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                ForEach(mockRecommendations) { rec in
                    recommendedCard(rec)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("約球助理")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func recommendedCard(_ rec: RecommendedMatch) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xE0E0E0))
                        .frame(width: 40, height: 40)
                    Text(String(rec.name.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(rec.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text(rec.gender == .female ? "♀" : "♂")
                            .font(.system(size: 14))
                            .foregroundColor(rec.gender == .female ? Theme.genderFemale : Theme.genderMale)
                        Text(rec.matchType)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textBody)
                            .padding(.horizontal, 6)
                            .frame(height: 18)
                            .background(Theme.chipUnselectedBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    Text("NTRP \(rec.ntrp)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textCaption)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("匹配度")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(rec.matchScore)%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.primary)
                }
            }

            HStack(spacing: Spacing.xs) {
                Text("📅 \(rec.dateTime)")
                Text("📍 \(rec.location)")
            }
            .font(.system(size: 12))
            .foregroundColor(Theme.textBody)
            .padding(.leading, 52)

            HStack(spacing: Spacing.xs) {
                Text(rec.reason)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 22)
                    .background(Theme.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                Button {
                    // TODO: navigate to MatchDetailView
                } label: {
                    Text("查看")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 30)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.leading, 52)
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }
}

// MARK: - Data

private struct RecommendedMatch: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let ntrp: String
    let matchType: String
    let dateTime: String
    let location: String
    let matchScore: Int
    let reason: String
}

private let mockRecommendations: [RecommendedMatch] = [
    RecommendedMatch(name: "莎拉", gender: .female, ntrp: "3.5", matchType: "單打", dateTime: "04/19 10:00", location: "維多利亞公園", matchScore: 95, reason: "NTRP 完全匹配"),
    RecommendedMatch(name: "美琪", gender: .female, ntrp: "3.5", matchType: "單打", dateTime: "04/21 08:30", location: "九龍仔公園", matchScore: 88, reason: "常去球場"),
    RecommendedMatch(name: "小美", gender: .female, ntrp: "3.0", matchType: "雙打", dateTime: "04/22 10:00", location: "沙田公園", matchScore: 82, reason: "時間吻合"),
    RecommendedMatch(name: "俊傑", gender: .male, ntrp: "4.0", matchType: "雙打", dateTime: "04/23 15:00", location: "將軍澳運動場", matchScore: 75, reason: "水平接近"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        MatchAssistantView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        MatchAssistantView()
    }
}
```

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/Views/MatchAssistantView.swift
git commit -m "feat: add MatchAssistantView with AI-recommended match feed"
```

---

## Phase 3: Wiring Existing Pages

### Task 11: Wire HomeView drawer menu

**Files:**
- Modify: `TennisMatch/Views/HomeView.swift:218-239` (drawer menu items)

- [ ] **Step 1: Add navigation state variables to HomeView**

Add these `@State` properties at the top of HomeView (after `@State private var acceptedMatches`):

```swift
@State private var showMatchAssistant = false
@State private var showReviews = false
@State private var showNotifications = false
@State private var showFollowing = false
@State private var showBlockList = false
@State private var showInviteFriends = false
@State private var showSettings = false
@State private var showHelp = false
```

- [ ] **Step 2: Wire drawer menu item actions**

Replace the drawer menu items block (lines ~220-239) to pass actions to each:

```swift
drawerMenuItem(icon: "🏆", label: "賽事") {
    showTournaments = true
}
drawerMenuItem(icon: "🤖", label: "約球助理") {
    showMatchAssistant = true
}
drawerMenuItem(icon: "⭐", label: "評價", badge: 2) {
    showReviews = true
}
drawerMenuItem(icon: "🔔", label: "通知", badge: 5) {
    showNotifications = true
}
drawerMenuItem(icon: "👥", label: "關注") {
    showFollowing = true
}
drawerMenuItem(icon: "🚫", label: "封鎖名單") {
    showBlockList = true
}
drawerMenuItem(icon: "📨", label: "邀請好友") {
    showInviteFriends = true
}

// Divider stays the same

drawerMenuItem(icon: "⚙️", label: "設定", isSecondary: true) {
    showSettings = true
}
drawerMenuItem(icon: "❓", label: "幫助", isSecondary: true) {
    showHelp = true
}
```

- [ ] **Step 3: Add navigationDestination modifiers to HomeView body**

Add these after the existing `.navigationDestination(item: $selectedMatchDetail)` (line ~84):

```swift
.navigationDestination(isPresented: $showMatchAssistant) {
    MatchAssistantView()
}
.navigationDestination(isPresented: $showReviews) {
    ReviewsView()
}
.navigationDestination(isPresented: $showNotifications) {
    NotificationsView()
}
.navigationDestination(isPresented: $showFollowing) {
    FollowingView()
}
.navigationDestination(isPresented: $showBlockList) {
    BlockListView()
}
.navigationDestination(isPresented: $showInviteFriends) {
    InviteFriendsView()
}
.navigationDestination(isPresented: $showSettings) {
    SettingsView()
}
.navigationDestination(isPresented: $showHelp) {
    HelpView()
}
```

**Important:** These use `navigationDestination(isPresented:)` because HomeView is already wrapped in a `NavigationStack` in `TennisMatchApp.swift`. The drawer closes first (via `showDrawer = false`), then the navigation state triggers.

- [ ] **Step 4: Build and verify all drawer menu items navigate correctly**

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "feat: wire all HomeView drawer menu items to their target pages"
```

---

### Task 12: Wire ProfileView buttons

**Files:**
- Modify: `TennisMatch/Views/ProfileView.swift:80-82` (settings button), `209-211` (tournament 全部), `296-298` (achievement 全部)

- [ ] **Step 1: Add navigation state to ProfileView**

Add after `@State private var showEditProfile = false`:

```swift
@State private var showSettings = false
@State private var showTournaments = false
@State private var showAchievements = false
```

- [ ] **Step 2: Wire settings button**

Replace the settings button (line ~80) `// TODO: settings` block:

```swift
Button {
    showSettings = true
} label: {
    Image(systemName: "gearshape")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(.white)
        .frame(width: 44, height: 44)
}
```

- [ ] **Step 3: Wire tournament "全部" button**

Replace the tournament "全部" button (line ~210) `// TODO: show all tournament records` block:

```swift
Button {
    showTournaments = true
} label: {
    Text("全部")
        .font(.system(size: 12))
        .foregroundColor(Theme.primary)
}
```

- [ ] **Step 4: Wire achievement "全部" button**

Replace the achievement "全部" button (line ~297) `// TODO: show all achievements` block:

```swift
Button {
    showAchievements = true
} label: {
    Text("全部")
        .font(.system(size: 12))
        .foregroundColor(Theme.primary)
}
```

- [ ] **Step 5: Add navigationDestinations to ProfileView body**

Add after the closing of `ScrollView` but within the outer VStack, before `.background(Theme.background)`:

```swift
.navigationDestination(isPresented: $showSettings) {
    SettingsView()
}
.navigationDestination(isPresented: $showAchievements) {
    AchievementsView()
}
.fullScreenCover(isPresented: $showTournaments) {
    TournamentView()
}
```

- [ ] **Step 6: Build and verify**

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/ProfileView.swift
git commit -m "feat: wire ProfileView settings, tournament, and achievements buttons"
```

---

### Task 13: Wire MatchDetailView buttons (signup, DM, follow)

**Files:**
- Modify: `TennisMatch/Views/MatchDetailView.swift:81-92` (follow button), `289-313` (bottom bar DM + signup)

- [ ] **Step 1: Add state for follow toggle and signup/chat navigation**

Add to MatchDetailView after `@State private var showInviteSheet = false`:

```swift
@State private var isFollowing = false
@State private var showSignUpConfirm = false
@State private var showSignUpSuccess = false
@State private var navigateToChat = false
```

- [ ] **Step 2: Wire the follow button**

Replace the follow button (line ~81-92):

```swift
Button {
    withAnimation { isFollowing.toggle() }
} label: {
    Text(isFollowing ? "已關注" : "關注")
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(isFollowing ? .white : Color(hex: 0x333333))
        .frame(width: 60, height: 44)
        .background(isFollowing ? Theme.primary : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            if !isFollowing {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(hex: 0xCCCCCC), lineWidth: 1)
            }
        }
}
```

- [ ] **Step 3: Wire the bottom bar DM and signup buttons**

Replace the else branch of bottom bar (lines ~289-313) where `!match.isOwnMatch`:

```swift
Button {
    navigateToChat = true
} label: {
    Text("💬 私信")
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(Color(hex: 0x218C21))
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(hex: 0x218C21), lineWidth: 1.5)
        }
}

Button {
    showSignUpConfirm = true
} label: {
    Text("報名")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color(hex: 0x218C21))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
}
```

- [ ] **Step 4: Add sheet/navigation modifiers for signup flow and DM**

Add to the MatchDetailView body, after the existing `.sheet(isPresented: $showInviteSheet)`:

```swift
.sheet(isPresented: $showSignUpConfirm) {
    SignUpConfirmSheetForDetail(match: match) {
        showSignUpSuccess = true
    }
    .presentationDetents([.medium])
}
.fullScreenCover(isPresented: $showSignUpSuccess) {
    SignUpSuccessViewForDetail(match: match)
}
.navigationDestination(isPresented: $navigateToChat) {
    ChatDetailView(
        chat: MockChat(
            type: .personal(name: match.name, symbol: match.gender == .female ? "♀" : "♂", symbolColor: match.gender == .female ? Theme.genderFemale : Theme.genderMale),
            lastMessage: "點擊開始聊天",
            time: "now",
            unreadCount: 0
        ),
        acceptedMatches: .constant([])
    )
}
```

- [ ] **Step 5: Add SignUpConfirmSheetForDetail and SignUpSuccessViewForDetail**

Add at the bottom of MatchDetailView.swift (these are simplified versions reusing the existing pattern):

```swift
// MARK: - Sign Up from Detail

private struct SignUpConfirmSheetForDetail: View {
    let match: MatchDetailData
    var onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("確認報名")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                infoRow(icon: "calendar", text: "\(match.date) \(match.timeRange)")
                infoRow(icon: "mappin.circle.fill", text: match.location)
                infoRow(icon: "figure.tennis", text: "\(match.matchType) · NTRP \(match.ntrpRange)")
                infoRow(icon: "dollarsign.circle.fill", text: match.fee)
            }

            Theme.divider.frame(height: 1)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("給發起人留言（選填）")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                TextField("例如：我會準時到！", text: $message, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(3...5)
                    .padding(Spacing.sm)
                    .background(Theme.inputBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
            }

            Spacer()

            Button {
                dismiss()
                onConfirm()
            } label: {
                Text("確認報名")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

private struct SignUpSuccessViewForDetail: View {
    let match: MatchDetailData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.textDark)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.xs)

            Spacer().frame(height: Spacing.xxl)

            ZStack {
                Circle().fill(Theme.primary).frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer().frame(height: Spacing.md)

            Text("報名成功！")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textDark)

            Text("你已成功加入\(match.name)的約球")
                .font(.system(size: 15))
                .foregroundColor(Theme.textHint)
                .padding(.top, Spacing.xs)

            Spacer()

            Button { dismiss() } label: {
                Text("進入群聊")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color(hex: 0xFFF0F0).opacity(0.3))
    }
}
```

- [ ] **Step 6: Build and verify**

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/MatchDetailView.swift
git commit -m "feat: wire MatchDetailView signup, DM, and follow buttons"
```

---

### Task 14: Wire MyMatchesView manage button + reject invitation

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift:237-241` (manage button), `347-349` (reject button), `361-369` (accept button)

- [ ] **Step 1: Add state for manage action sheet**

Add to MyMatchesView after `@State private var showCancelledToast = false`:

```swift
@State private var showManageSheet = false
@State private var matchToManage: MyMatchItem?
@State private var showRejectToast = false
@State private var rejectedInvitations: Set<UUID> = []
```

- [ ] **Step 2: Wire manage button to confirmationDialog**

Replace the manage button `matchActionButton("管理", style: .filled)` (line ~238):

```swift
matchActionButton("管理", style: .filled) {
    matchToManage = match
    showManageSheet = true
}
```

- [ ] **Step 3: Add confirmationDialog for manage**

Add to the MyMatchesView body, after the existing `.alert`:

```swift
.confirmationDialog("管理約球", isPresented: $showManageSheet, presenting: matchToManage) { match in
    Button("編輯約球") {
        // TODO: edit match
    }
    Button("查看報名者") {
        // TODO: view applicants
    }
    Button("關閉報名") {
        // TODO: close signups
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

- [ ] **Step 4: Wire reject invitation button**

Replace the reject button `// TODO: decline` (line ~348):

```swift
Button {
    withAnimation {
        rejectedInvitations.insert(invitation.id)
    }
    showRejectToast = true
} label: {
    Text("拒絕")
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(Theme.textBody)
        .frame(width: 48, height: 26)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.inputBorder, lineWidth: 1)
        }
        .frame(minWidth: 44, minHeight: 44)
}
```

- [ ] **Step 5: Wire accept invitation button to jump to chat**

Replace the accept button `// TODO: accept` (line ~362):

```swift
Button {
    acceptedMatches.append(AcceptedMatchInfo(
        organizerName: invitation.inviterName,
        matchType: invitation.matchType,
        dateString: invitation.details.components(separatedBy: " · ").first ?? "",
        time: "10:00",
        location: invitation.details.components(separatedBy: " · ").dropFirst().first ?? ""
    ))
    // Navigate to chat
    let chatTitle = "\(invitation.details.components(separatedBy: " · ").dropFirst().first ?? "") \(invitation.matchType)"
    selectedChat = MockChat(
        type: .match(title: chatTitle, dateTime: invitation.details.components(separatedBy: " · ").first ?? ""),
        lastMessage: "已加入約球",
        time: "now",
        unreadCount: 0
    )
} label: {
    Text("接受")
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.white)
        .frame(width: 48, height: 26)
        .background(Theme.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(minWidth: 44, minHeight: 44)
}
```

- [ ] **Step 6: Filter out rejected invitations in the ForEach**

Change the invitation ForEach from:
```swift
ForEach(mockInvitations) { invitation in
```
To:
```swift
ForEach(mockInvitations.filter { !rejectedInvitations.contains($0.id) }) { invitation in
```

- [ ] **Step 7: Add reject toast overlay**

Add alongside the existing cancelled toast overlay:

```swift
.overlay(alignment: .top) {
    if showRejectToast {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.white)
            Text("已拒絕邀請")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Capsule().fill(Theme.textBody))
        .transition(.move(edge: .top).combined(with: .opacity))
        .padding(.top, Spacing.lg)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showRejectToast = false }
            }
        }
    }
}
```

- [ ] **Step 8: Build and verify**

- [ ] **Step 9: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "feat: wire MyMatchesView manage ActionSheet, reject invitation, and accept→chat"
```

---

### Task 15: Wire ChatDetailView "..." menu

**Files:**
- Modify: `TennisMatch/Views/ChatDetailView.swift`

- [ ] **Step 1: Add state for the menu**

Add to ChatDetailView after `@State private var selectedPhotoData: Data?`:

```swift
@State private var showChatMenu = false
```

- [ ] **Step 2: Find and wire the "..." button in the toolbar**

Locate the toolbar "..." button (currently has no action or may not exist). Add it to the `.toolbar` section:

```swift
ToolbarItem(placement: .navigationBarTrailing) {
    Button {
        showChatMenu = true
    } label: {
        Image(systemName: "ellipsis")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Theme.textPrimary)
            .frame(width: 44, height: 44)
    }
}
```

- [ ] **Step 3: Add confirmationDialog based on chat type**

Add to the ChatDetailView body:

```swift
.confirmationDialog("", isPresented: $showChatMenu) {
    switch chat.type {
    case .match:
        Button("查看約球詳情") {
            // TODO: navigate to MatchDetailView
        }
        Button("查看群成員") {
            // TODO: show members
        }
        Button("靜音通知") {
            // TODO: toggle mute
        }
        Button("退出群聊", role: .destructive) {
            dismiss()
        }
    case .personal(let name, _, _):
        Button("���看 \(name) 的資料") {
            // TODO: navigate to PublicProfileView
        }
        Button("靜音通知") {
            // TODO: toggle mute
        }
        Button("封鎖對方", role: .destructive) {
            // TODO: block
        }
        Button("刪除聊天", role: .destructive) {
            dismiss()
        }
    }
    Button("取消", role: .cancel) {}
}
```

- [ ] **Step 4: Build and verify**

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Views/ChatDetailView.swift
git commit -m "feat: wire ChatDetailView ellipsis menu with group/DM options"
```

---

### Task 16: Wire TournamentDetailView signup + follow

**Files:**
- Modify: `TennisMatch/Views/TournamentView.swift:476-486` (follow button), `551-576` (signup button)

- [ ] **Step 1: Add state for follow and signup**

Add to TournamentDetailView after `@Environment(\.dismiss) private var dismiss`:

```swift
@State private var isFollowing = false
@State private var showSignUpConfirm = false
@State private var showSignUpSuccess = false
```

- [ ] **Step 2: Wire the follow button in organizerCard**

Replace the follow button `// TODO: follow` (line ~477-486):

```swift
Button {
    withAnimation { isFollowing.toggle() }
} label: {
    Text(isFollowing ? "已關注" : "關注")
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(isFollowing ? .white : Color(hex: 0x333333))
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(isFollowing ? Theme.primary : Color(hex: 0xF2F2F2))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
}
```

- [ ] **Step 3: Wire the signup button in bottomBar**

Replace the signup button `// TODO: sign up` (line ~555-564):

```swift
Button {
    showSignUpConfirm = true
} label: {
    Text("立即報名 · \(tournament.fee)")
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: 0x26AD61))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
}
```

- [ ] **Step 4: Add signup confirmation sheet and success cover**

Add modifiers to TournamentDetailView body:

```swift
.sheet(isPresented: $showSignUpConfirm) {
    TournamentSignUpSheet(tournament: tournament) {
        showSignUpSuccess = true
    }
    .presentationDetents([.medium])
}
.fullScreenCover(isPresented: $showSignUpSuccess) {
    TournamentSignUpSuccessView(tournament: tournament)
}
```

- [ ] **Step 5: Add TournamentSignUpSheet and TournamentSignUpSuccessView**

Add at the bottom of TournamentView.swift:

```swift
// MARK: - Tournament Sign Up

private struct TournamentSignUpSheet: View {
    let tournament: MockTournament
    var onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("確認報名")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                infoRow(icon: "trophy.fill", text: tournament.name)
                infoRow(icon: "calendar", text: tournament.dateRange)
                infoRow(icon: "mappin.circle.fill", text: tournament.location)
                infoRow(icon: "dollarsign.circle.fill", text: tournament.fee)
            }

            Spacer()

            Button {
                dismiss()
                onConfirm()
            } label: {
                Text("確認報名")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

private struct TournamentSignUpSuccessView: View {
    let tournament: MockTournament
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.textDark)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.xs)

            Spacer().frame(height: Spacing.xxl)

            ZStack {
                Circle().fill(Theme.primary).frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer().frame(height: Spacing.md)

            Text("報名成功！")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textDark)

            Text("你已成功報名「\(tournament.name)」")
                .font(.system(size: 15))
                .foregroundColor(Theme.textHint)
                .padding(.top, Spacing.xs)

            Spacer()

            Button { dismiss() } label: {
                Text("進入賽事群聊")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color(hex: 0xFFF0F0).opacity(0.3))
    }
}
```

- [ ] **Step 6: Build and verify**

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/TournamentView.swift
git commit -m "feat: wire TournamentDetailView signup flow and follow button"
```

---

### Task 17: Wire LoginView buttons

**Files:**
- Modify: `TennisMatch/Views/LoginView.swift:134-163` (WeChat + Apple buttons), `193-220` (footer links)

- [ ] **Step 1: Add state for Apple Sign In and navigation**

Add to LoginView after `@State private var showVerification = false`:

```swift
@State private var showAppleSignIn = false
@State private var showHelpView = false
```

Add `import AuthenticationServices` at the top of the file.

- [ ] **Step 2: Wire the WeChat button**

Replace the WeChat button action (line ~137, currently empty):

```swift
loginButton(
    title: "微信登录",
    icon: "bubble.left.fill",
    bg: wechat,
    fg: .white,
    delay: 0.60,
    action: { showVerification = true }  // Reuse phone verification flow for now
)
```

- [ ] **Step 3: Wire the Apple button**

Replace the Apple button `Button(action: {})` (line ~144):

```swift
Button(action: { showVerification = true }) {
    HStack(spacing: 10) {
        Image(systemName: "apple.logo")
            .font(.system(size: 18, weight: .semibold))
        Text("Apple 登录")
            .font(.system(size: 16, weight: .semibold))
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .frame(height: 54)
    .background(Color.white.opacity(0.07))
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
    )
}
.opacity(appeared ? 1 : 0)
.offset(y: appeared ? 0 : 24)
.animation(.easeOut(duration: 0.6).delay(0.70), value: appeared)
```

- [ ] **Step 4: Wire footer links**

Replace "立即註冊" button (line ~202):

```swift
Button(action: { showVerification = true }) {
    Text("立即註冊")
        .foregroundColor(chartreuse)
        .underline()
}
```

Replace "聯繫客服" (line ~211) — wrap in a Button that navigates:

```swift
Button(action: { showHelpView = true }) {
    Text("聯繫客服")
        .foregroundColor(chartreuse.opacity(0.6))
}
```

- [ ] **Step 5: Add navigation destination for HelpView**

Add after the existing `.navigationDestination(isPresented: $showVerification)`:

```swift
.navigationDestination(isPresented: $showHelpView) {
    HelpView()
}
```

- [ ] **Step 6: Build and verify**

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/LoginView.swift
git commit -m "feat: wire LoginView WeChat, Apple, register, and help buttons"
```

---

## Phase 4: Final Verification

### Task 18: Full build and navigation smoke test

- [ ] **Step 1: Full project build**

```bash
cd /Users/xue/AppProjects/TennisMatch
xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 2: Fix any compilation errors**

Address any type mismatches, missing imports, or naming conflicts.

- [ ] **Step 3: Verify each navigation path**

Test these paths in Xcode previews or simulator:
1. Drawer → each of the 9 menu items opens correct page
2. Match card → detail → signup → success
3. Match card → detail → DM → chat
4. Match card → detail → follow toggle
5. Tournament → detail → signup → success
6. Tournament → detail → follow toggle
7. My matches → manage → ActionSheet appears
8. My matches → invitation → accept / reject
9. Chat → "..." menu → options appear
10. Profile → settings / tournament 全部 / achievements 全部
11. Login → each button navigates

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "fix: resolve any compilation issues from navigation wiring"
```
