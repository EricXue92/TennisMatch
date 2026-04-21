//
//  MyMatchesView.swift
//  TennisMatch
//
//  我的約球 — 即將到來、已完成、收到邀請
//

import SwiftUI

struct MyMatchesView: View {
    @Binding var acceptedMatches: [AcceptedMatchInfo]
    /// Fires when a user-signed-up match is cancelled. Passes the originating HomeView match ID (or nil for mock/invitation-accept items).
    var onMatchCancelled: ((UUID?) -> Void)? = nil
    @State private var selectedFilter = "即將到來"
    @State private var selectedChat: MockChat?
    @State private var matchToCancel: MyMatchItem?
    @State private var showCancelAlert = false
    @State private var showCancelledToast = false
    @State private var showManageSheet = false
    @State private var matchToManage: MyMatchItem?
    @State private var showRejectToast = false
    @State private var comingSoonMessage: String?
    @State private var rejectedInvitations: Set<UUID> = []
    @State private var upcomingMatches: [MyMatchItem] = mockUpcomingMatchesInitial
    @State private var acceptedInvitation: MyMatchInvitation?
    @State private var showAcceptSuccess = false
    @State private var pendingDMContact: MyMatchInvitation?
    @State private var dmChat: MockChat?
    @State private var dmMatchContext: String?

    private var acceptedMatchItems: [MyMatchItem] {
        acceptedMatches.map { info in
            let timeStr = info.time
            let startHour = Int(timeStr.prefix(2)) ?? 10
            let endHour = startHour + info.durationHours
            let endTime = String(format: "%02d:00", endHour)
            return MyMatchItem(
                title: "\(info.organizerName) 發起的\(info.matchType)",
                isOrganizer: false,
                status: .confirmed,
                dateLabel: "\(info.dateString)",
                location: "\(info.location)網球場",
                timeRange: "\(timeStr) - \(endTime)",
                players: "2/2 · NTRP 3.0-4.0",
                weather: "☀️ 24°C",
                matchType: info.matchType,
                acceptedMatchID: info.id,
                sourceMatchID: info.sourceMatchID
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            filterTabs
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if selectedFilter == "即將到來" {
                        ForEach(acceptedMatchItems) { match in
                            myMatchCard(match)
                        }
                        ForEach(upcomingMatches) { match in
                            myMatchCard(match)
                        }
                        ForEach(mockInvitations.filter { !rejectedInvitations.contains($0.id) }) { invitation in
                            invitationCard(invitation)
                        }
                    } else {
                        ForEach(mockCompletedMatches) { match in
                            myMatchCard(match)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, 100)
            }
        }
        .background(Theme.inputBg)
        .navigationDestination(item: $selectedChat) { chat in
            ChatDetailView(chat: chat, acceptedMatches: $acceptedMatches)
        }
        .alert("取消約球", isPresented: $showCancelAlert) {
            Button("再想想", role: .cancel) {
                matchToCancel = nil
            }
            Button("確認取消", role: .destructive) {
                if let match = matchToCancel {
                    withAnimation {
                        if let aid = match.acceptedMatchID {
                            acceptedMatches.removeAll { $0.id == aid }
                        }
                        upcomingMatches.removeAll { $0.id == match.id }
                    }
                    onMatchCancelled?(match.sourceMatchID)
                    showCancelledToast = true
                }
                matchToCancel = nil
            }
        } message: {
            if let match = matchToCancel {
                Text("確定要取消「\(match.title)」嗎？取消後將通知所有參與者。")
            }
        }
        .confirmationDialog("管理約球", isPresented: $showManageSheet, presenting: matchToManage) { match in
            Button("編輯約球") {
                comingSoonMessage = "編輯約球功能即將推出"
            }
            Button("查看報名者") {
                comingSoonMessage = "查看報名者功能即將推出"
            }
            Button("關閉報名") {
                comingSoonMessage = "關閉報名功能即將推出"
            }
            Button("取消約球", role: .destructive) {
                matchToCancel = match
                showCancelAlert = true
            }
            Button("取消", role: .cancel) {}
        } message: { match in
            Text(match.title)
        }
        .overlay(alignment: .top) {
            if showCancelledToast {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("已取消約球，已通知所有參與者")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule().fill(Theme.textBody)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, Spacing.lg)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showCancelledToast = false }
                    }
                }
            }
        }
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
        .overlay(alignment: .top) {
            if let message = comingSoonMessage {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "hourglass")
                        .foregroundColor(.white)
                    Text(message)
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
                        withAnimation { comingSoonMessage = nil }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showAcceptSuccess, onDismiss: {
            if let inv = pendingDMContact {
                dmChat = MockChat(
                    type: .personal(name: inv.inviterName, symbol: "♂", symbolColor: Theme.genderMale),
                    lastMessage: "點擊開始聊天",
                    time: "now",
                    unreadCount: 0
                )
                dmMatchContext = "🎾 已接受約球邀請\n🏸 \(inv.matchType)\n📋 \(inv.details)"
                pendingDMContact = nil
            }
        }) {
            if let inv = acceptedInvitation {
                InvitationAcceptSuccessView(invitation: inv, onContactOrganizer: {
                    pendingDMContact = inv
                    showAcceptSuccess = false
                })
            }
        }
        .navigationDestination(item: $dmChat) { chat in
            ChatDetailView(chat: chat, acceptedMatches: $acceptedMatches, matchContext: dmMatchContext)
                .onDisappear { dmMatchContext = nil }
        }
    }

    private func openChat(for match: MyMatchItem) {
        // Extract location name from "XXX網球場" → "XXX"
        let locationBase = match.location
            .replacingOccurrences(of: "網球場", with: "")
            .replacingOccurrences(of: "遊樂場", with: "")
        let chatTitle = "\(locationBase) \(match.matchType)"
        // Extract date/time from timeRange "10:00 - 12:00" → "10:00"
        let startTime = match.timeRange.components(separatedBy: " - ").first ?? ""
        let dateTime = "\(match.dateLabel.replacingOccurrences(of: "明天 · ", with: "")) \(startTime)"

        selectedChat = MockChat(
            type: .match(title: chatTitle, dateTime: dateTime),
            lastMessage: "點擊開始聊天",
            time: "now",
            unreadCount: 0
        )
    }
}

// MARK: - Header & Filters

private extension MyMatchesView {
    var headerBar: some View {
        HStack {
            Text("我的約球")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            if !mockInvitations.isEmpty {
                Text("邀請 \(mockInvitations.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 26)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(.white)
    }

    var filterTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(["即將到來", "已完成"], id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = tab
                        }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Text(tab)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedFilter == tab ? Theme.primary : Theme.textBody)
                                .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(selectedFilter == tab ? Theme.primary : .clear)
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
}

// MARK: - Match Card

private extension MyMatchesView {
    func myMatchCard(_ match: MyMatchItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            dateBanner(match)

            VStack(alignment: .leading, spacing: 6) {
                // Avatar + title + weather
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(Color(hex: 0xE0E0E0))
                        .frame(width: 36, height: 36)

                    HStack(spacing: 4) {
                        Text(match.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)

                        if match.isOrganizer {
                            Text("發起人")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.primary)
                                .padding(.horizontal, 6)
                                .frame(height: 18)
                                .background(Theme.confirmedBg)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }

                    Spacer()

                    Text(match.weather)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textBody)
                }

                // Detail rows
                matchDetailRow(icon: "📍", text: match.location)
                matchDetailRow(icon: "🕐", text: match.timeRange)
                matchDetailRow(icon: "👥", text: match.players)

                // Action buttons
                if match.status != .completed {
                    HStack {
                        Spacer()
                        if match.isOrganizer {
                            matchActionButton("管理", style: .filled) {
                                matchToManage = match
                                showManageSheet = true
                            }
                            matchActionButton("取消", style: .outlined) {
                                matchToCancel = match
                                showCancelAlert = true
                            }
                        } else {
                            matchActionButton("💬 聊天", style: .filled) {
                                openChat(for: match)
                            }
                            matchActionButton("取消", style: .outlined) {
                                matchToCancel = match
                                showCancelAlert = true
                            }
                        }
                    }
                }
            }
            .padding(Spacing.sm)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }

    func dateBanner(_ match: MyMatchItem) -> some View {
        HStack {
            Text("🗓️ \(match.dateLabel)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Text(match.status.rawValue)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xs)
                .frame(height: 20)
                .background(match.status.badgeColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, Spacing.sm)
        .frame(height: 30)
        .background(match.status.bannerColor)
    }

    func matchDetailRow(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Theme.textBody)
        }
        .padding(.leading, 48)
    }

    func matchActionButton(_ title: String, style: MatchActionStyle, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(style == .filled ? .white : Theme.textBody)
                .padding(.horizontal, Spacing.sm)
                .frame(height: 30)
                .background(style == .filled ? Theme.primary : .white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    if style == .outlined {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    }
                }
                .frame(minWidth: 44, minHeight: 44)
        }
    }
}

// MARK: - Invitation Card

private extension MyMatchesView {
    func invitationCard(_ invitation: MyMatchInvitation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner
            Text("📩 收到邀請")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Spacing.sm)
                .frame(height: 26, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.requiredBg)

            // Content
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color(hex: 0xE0E0E0))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(invitation.inviterName) 邀請你打\(invitation.matchType)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(invitation.details)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textBody)
                }

                Spacer()

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

                Button {
                    acceptedMatches.append(AcceptedMatchInfo(
                        organizerName: invitation.inviterName,
                        matchType: invitation.matchType,
                        dateString: invitation.details.components(separatedBy: " · ").first ?? "",
                        time: invitation.time,
                        location: invitation.details.components(separatedBy: " · ").dropFirst().first ?? "",
                        sourceMatchID: nil,
                        durationHours: invitation.durationHours
                    ))
                    acceptedInvitation = invitation
                    showAcceptSuccess = true
                } label: {
                    Text("接受")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 26)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }
}

// MARK: - Data

private enum MyMatchStatus: String {
    case confirmed = "已確認"
    case pending = "等待中"
    case completed = "已完成"

    var bannerColor: Color {
        switch self {
        case .confirmed: return Theme.confirmedBg
        case .pending: return Theme.pendingBg
        case .completed: return Theme.chipUnselectedBg
        }
    }

    var badgeColor: Color {
        switch self {
        case .confirmed: return Theme.primary
        case .pending: return Theme.pendingBadge
        case .completed: return Theme.textSecondary
        }
    }
}

private enum MatchActionStyle {
    case filled, outlined
}

private struct MyMatchItem: Identifiable {
    let id = UUID()
    let title: String
    let isOrganizer: Bool
    let status: MyMatchStatus
    let dateLabel: String
    let location: String
    let timeRange: String
    let players: String
    let weather: String
    var matchType: String = "單打"
    var acceptedMatchID: UUID?  // links back to AcceptedMatchInfo for cancellation
    var sourceMatchID: UUID?    // links back to the originating HomeView match (if any)
}

private struct MyMatchInvitation: Identifiable {
    let id = UUID()
    let inviterName: String
    let matchType: String
    let details: String
    let time: String            // "14:00"
    let durationHours: Int      // e.g. 2
}

private let mockUpcomingMatchesInitial: [MyMatchItem] = [
    MyMatchItem(
        title: "莎拉 發起的單打",
        isOrganizer: false,
        status: .confirmed,
        dateLabel: "明天 · 04/19（六）",
        location: "維多利亞公園網球場",
        timeRange: "10:00 - 12:00",
        players: "2/2 · NTRP 3.0-4.0",
        weather: "☀️ 24°C"
    ),
    MyMatchItem(
        title: "我發起的雙打",
        isOrganizer: true,
        status: .pending,
        dateLabel: "04/20（日）",
        location: "跑馬地遊樂場",
        timeRange: "14:00 - 16:00",
        players: "2/4 · NTRP 3.5-4.5",
        weather: "⛅ 26°C"
    ),
    MyMatchItem(
        title: "嘉欣 發起的單打",
        isOrganizer: false,
        status: .confirmed,
        dateLabel: "04/23（三）",
        location: "香港公園",
        timeRange: "09:00 - 11:00",
        players: "2/2 · NTRP 2.5-3.5",
        weather: "🌤 26°C"
    ),
    MyMatchItem(
        title: "我發起的雙打",
        isOrganizer: true,
        status: .pending,
        dateLabel: "04/25（五）",
        location: "將軍澳運動場",
        timeRange: "18:00 - 20:00",
        players: "3/4 · NTRP 3.0-4.0",
        weather: "☀️ 27°C",
        matchType: "雙打"
    ),
    MyMatchItem(
        title: "Michael 發起的單打",
        isOrganizer: false,
        status: .confirmed,
        dateLabel: "04/27（日）",
        location: "跑馬地遊樂場",
        timeRange: "08:00 - 10:00",
        players: "2/2 · NTRP 4.5-5.0",
        weather: "☀️ 25°C"
    ),
]

private let mockCompletedMatches: [MyMatchItem] = [
    MyMatchItem(
        title: "王強 發起的雙打",
        isOrganizer: false,
        status: .completed,
        dateLabel: "04/12（六）",
        location: "九龍仔公園",
        timeRange: "14:00 - 16:00",
        players: "4/4 · NTRP 3.5-4.5",
        weather: "☀️ 28°C"
    ),
    MyMatchItem(
        title: "我發起的單打",
        isOrganizer: true,
        status: .completed,
        dateLabel: "04/10（四）",
        location: "香港網球中心",
        timeRange: "09:00 - 11:00",
        players: "2/2 · NTRP 3.0-4.0",
        weather: "🌤 25°C"
    ),
    MyMatchItem(
        title: "大衛 發起的雙打",
        isOrganizer: false,
        status: .completed,
        dateLabel: "04/06（日）",
        location: "歌和老街公園",
        timeRange: "16:00 - 18:00",
        players: "4/4 · NTRP 4.0-5.0",
        weather: "☀️ 27°C",
        matchType: "雙打"
    ),
    MyMatchItem(
        title: "嘉欣 發起的雙打",
        isOrganizer: false,
        status: .completed,
        dateLabel: "03/29（六）",
        location: "沙田公園",
        timeRange: "10:00 - 12:00",
        players: "4/4 · NTRP 3.0-3.5",
        weather: "⛅ 23°C",
        matchType: "雙打"
    ),
    MyMatchItem(
        title: "我發起的單打",
        isOrganizer: true,
        status: .completed,
        dateLabel: "03/22（六）",
        location: "維多利亞公園網球場",
        timeRange: "08:00 - 10:00",
        players: "2/2 · NTRP 3.5-4.0",
        weather: "☀️ 22°C"
    ),
]

private let mockInvitations: [MyMatchInvitation] = [
    MyMatchInvitation(
        inviterName: "艾美",
        matchType: "單打",
        details: "04/22 · 京士柏 · NTRP 3.0",
        time: "14:00",
        durationHours: 2
    ),
    MyMatchInvitation(
        inviterName: "俊傑",
        matchType: "雙打",
        details: "04/25 · 將軍澳 · NTRP 3.5-4.5",
        time: "18:00",
        durationHours: 2
    ),
    MyMatchInvitation(
        inviterName: "思慧",
        matchType: "單打",
        details: "04/27 · 香港公園 · NTRP 3.0-3.5",
        time: "09:00",
        durationHours: 2
    ),
]

// MARK: - Invitation Accept Success

private struct InvitationAcceptSuccessView: View {
    let invitation: MyMatchInvitation
    var onContactOrganizer: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    private var detailParts: [String] {
        invitation.details.components(separatedBy: " · ")
    }

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

            Text("已接受邀請！")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textDark)

            Text("你已加入\(invitation.inviterName)的\(invitation.matchType)約球")
                .font(.system(size: 15))
                .foregroundColor(Theme.textHint)
                .padding(.top, Spacing.xs)

            Spacer().frame(height: Spacing.lg)

            // Summary card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let date = detailParts.first {
                    summaryRow(icon: "calendar", text: date)
                }
                if detailParts.count > 1 {
                    summaryRow(icon: "mappin.and.ellipse", text: detailParts[1])
                }
                if detailParts.count > 2 {
                    summaryRow(icon: "figure.tennis", text: "\(invitation.matchType) · \(detailParts[2])")
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.inputBorder, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.md)

            Spacer().frame(height: Spacing.md)

            // Action buttons
            VStack(spacing: Spacing.sm) {
                outlineButton(icon: "bubble.left.fill", label: "私信\(invitation.inviterName)") {
                    onContactOrganizer?()
                }
                outlineButton(icon: "calendar.badge.plus", label: "加入日曆") {
                    // TODO: add to calendar
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            Button { dismiss() } label: {
                Text("返回我的約球")
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

    private func summaryRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.textHint)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Theme.textDark)
        }
    }

    private func outlineButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Theme.accentGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.accentGreen, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    MyMatchesView(acceptedMatches: .constant([]))
}

#Preview("iPhone 15 Pro") {
    MyMatchesView(acceptedMatches: .constant([]))
}
