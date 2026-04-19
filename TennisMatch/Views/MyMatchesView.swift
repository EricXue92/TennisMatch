//
//  MyMatchesView.swift
//  TennisMatch
//
//  我的約球 — 即將到來、已完成、收到邀請
//

import SwiftUI

struct MyMatchesView: View {
    @State private var selectedFilter = "即將到來"

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            filterTabs
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if selectedFilter == "即將到來" {
                        ForEach(mockUpcomingMatches) { match in
                            myMatchCard(match)
                        }
                        ForEach(mockInvitations) { invitation in
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
                            matchActionButton("管理", style: .filled)
                        } else {
                            matchActionButton("💬 聊天", style: .filled)
                            matchActionButton("取消", style: .outlined)
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

    func matchActionButton(_ title: String, style: MatchActionStyle) -> some View {
        Button {
            // TODO
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
                    // TODO: decline
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
                    // TODO: accept
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
}

private struct MyMatchInvitation: Identifiable {
    let id = UUID()
    let inviterName: String
    let matchType: String
    let details: String
}

private let mockUpcomingMatches: [MyMatchItem] = [
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
]

private let mockInvitations: [MyMatchInvitation] = [
    MyMatchInvitation(
        inviterName: "艾美",
        matchType: "單打",
        details: "04/22 · 京士柏 · NTRP 3.0"
    ),
]

// MARK: - Preview

#Preview("iPhone SE") {
    MyMatchesView()
}

#Preview("iPhone 15 Pro") {
    MyMatchesView()
}
