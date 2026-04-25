//
//  NotificationsView.swift
//  TennisMatch
//
//  通知 — 約球相關通知
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationStore.self) private var notificationStore
    @State private var selectedMatchDetail: MatchDetailData?
    @State private var notificationAccepted: [AcceptedMatchInfo] = []
    @State private var notificationSignedUp: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            if notificationStore.notifications.isEmpty {
                emptyState
            } else {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            notificationStore.markAllRead()
                        }
                    } label: {
                        Text("全部已讀")
                            .font(Typography.captionMedium)
                            .foregroundColor(Theme.primary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(notificationStore.notifications) { notification in
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
                        .font(Typography.buttonMedium)
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("通知")
                    .font(Typography.sectionTitle)
            }
        }
        .navigationDestination(item: $selectedMatchDetail) { detail in
            MatchDetailView(
                match: detail,
                acceptedMatches: $notificationAccepted,
                signedUpMatchIDs: $notificationSignedUp
            )
        }
    }

    private func notificationRow(_ notification: MatchNotification) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(notification.iconBg)
                    .frame(width: 40, height: 40)
                Image(systemName: notification.icon)
                    .font(Typography.buttonMedium)
                    .foregroundColor(notification.iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 14, weight: notification.isRead ? .regular : .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(notification.body)
                    .font(Typography.caption)
                    .foregroundColor(Theme.textBody)
                    .lineLimit(2)
                Text(notification.time)
                    .font(Typography.fieldLabel)
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
        .contentShape(Rectangle())
        .onTapGesture {
            notificationStore.markRead(id: notification.id)
            selectedMatchDetail = mockMatchDetail(for: notification)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暫無通知",
            systemImage: "bell.slash",
            description: Text("報名、確認、改期等通知會顯示在這裡")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Mock Match Detail

    /// 根據通知內容生成對應的約球詳情(Mock 階段)。
    /// 每種通知類型使用不同的時間、地點、參與者，避免所有通知顯示相同資料。
    /// 生成相對於今天的日期字串（yyyy/MM/dd）
    private func relativeDate(daysFromNow: Int) -> String {
        guard let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) else { return AppDateFormatter.yearMonthDay.string(from: Date()) }
        return AppDateFormatter.yearMonthDay.string(from: date)
    }

    private func mockMatchDetail(for notification: MatchNotification) -> MatchDetailData {
        let matchType = notification.body.contains("雙打") ? "雙打" : "單打"
        // 嘗試從通知 body 的括號內提取日期（「MM/dd」格式）
        let dateStr = extractDateString(from: notification.body)

        switch notification.type {
        case .signUp:
            // 有人報名了自己發起的約球：顯示自己的約球詳情
            return MatchDetailData(
                name: extractName(from: notification.body) ?? "球友",
                gender: .male, ntrp: "3.5", reputation: 88,
                matchType: matchType,
                date: dateStr ?? relativeDate(daysFromNow: 0), timeRange: "14:00 - 16:00",
                location: extractLocation(from: notification.body) ?? "維多利亞公園網球場",
                district: "香港銅鑼灣",
                players: "2/4 人", ntrpRange: "3.0-4.5", fee: "AA ¥100",
                notes: "歡迎加入，請準時到場！",
                weather: MatchWeather(temp: "26°C", humidity: "65%", uv: "6", wind: "10"),
                participantList: [
                    MatchParticipant(name: "我", gender: .male, ntrp: "3.5", isOrganizer: true),
                    MatchParticipant(name: extractName(from: notification.body) ?? "球友",
                                     gender: .male, ntrp: "3.5", isOrganizer: false),
                ],
                isOwnMatch: true
            )
        case .accepted:
            // 自己報名被接受：顯示發起人的約球詳情
            let name = extractOrganizerName(from: notification.body) ?? "球友"
            return MatchDetailData(
                name: name,
                gender: .female, ntrp: "3.5", reputation: 90,
                matchType: matchType,
                date: dateStr ?? relativeDate(daysFromNow: -1), timeRange: "10:00 - 12:00",
                location: extractLocation(from: notification.body) ?? "維多利亞公園網球場",
                district: "香港銅鑼灣",
                players: "2/2 人", ntrpRange: "3.0-4.0", fee: "AA ¥120",
                notes: "自帶球拍和球",
                weather: MatchWeather(temp: "24°C", humidity: "55%", uv: "5", wind: "8"),
                participantList: [
                    MatchParticipant(name: name, gender: .female, ntrp: "3.5", isOrganizer: true),
                    MatchParticipant(name: "我", gender: .male, ntrp: "3.5", isOrganizer: false),
                ]
            )
        case .cancelled:
            // 約球被取消通知：顯示已取消的約球詳情
            let name = extractName(from: notification.body) ?? "球友"
            return MatchDetailData(
                name: name,
                gender: .female, ntrp: "3.0", reputation: 85,
                matchType: matchType,
                date: dateStr ?? relativeDate(daysFromNow: -1), timeRange: "09:00 - 11:00",
                location: extractLocation(from: notification.body) ?? "沙田公園網球場",
                district: "新界沙田",
                players: "1/4 人", ntrpRange: "2.5-4.0", fee: "AA ¥80",
                notes: "此約球已取消",
                weather: MatchWeather(temp: "25°C", humidity: "70%", uv: "7", wind: "12"),
                participantList: [
                    MatchParticipant(name: name, gender: .female, ntrp: "3.0", isOrganizer: true),
                ]
            )
        case .updated:
            // 約球資訊更新通知：顯示更新後的約球詳情
            let name = extractName(from: notification.body) ?? "球友"
            return MatchDetailData(
                name: name,
                gender: .male, ntrp: "4.5", reputation: 92,
                matchType: matchType,
                date: dateStr ?? relativeDate(daysFromNow: 1), timeRange: "16:30 - 18:30",
                location: extractLocation(from: notification.body) ?? "跑馬地運動場",
                district: "香港灣仔",
                players: "2/2 人", ntrpRange: "3.5-5.0", fee: "AA ¥150",
                notes: "時間已更新，請注意新的時間安排",
                weather: MatchWeather(temp: "27°C", humidity: "60%", uv: "5", wind: "15"),
                participantList: [
                    MatchParticipant(name: name, gender: .male, ntrp: "4.5", isOrganizer: true),
                    MatchParticipant(name: "我", gender: .male, ntrp: "3.5", isOrganizer: false),
                ]
            )
        }
    }

    /// 從通知 body 提取球友名字（第一個空格前的中文/英文名）。
    private func extractName(from body: String) -> String? {
        let parts = body.split(separator: " ", maxSplits: 1)
        guard let first = parts.first else { return nil }
        return String(first)
    }

    /// 從「你報名的XXX單打約球」格式中提取發起人名字。
    private func extractOrganizerName(from body: String) -> String? {
        guard body.hasPrefix("你報名的") else { return extractName(from: body) }
        let trimmed = body.dropFirst(4)
        if let range = trimmed.range(of: "單打") ?? trimmed.range(of: "雙打") {
            return String(trimmed[trimmed.startIndex..<range.lowerBound])
        }
        return nil
    }

    /// 從括號中提取地點（「04/20 跑馬地」→「跑馬地網球場」）。
    private func extractLocation(from body: String) -> String? {
        guard let open = body.firstIndex(of: "（"),
              let close = body.firstIndex(of: "）") else { return nil }
        let inside = String(body[body.index(after: open)..<close])
        let parts = inside.split(separator: " ")
        if parts.count >= 2 {
            return parts.dropFirst().joined(separator: " ") + "網球場"
        }
        return inside + "網球場"
    }

    /// 從括號中提取日期字符串（「MM/dd」→「2026/MM/dd」）。
    private func extractDateString(from body: String) -> String? {
        guard let open = body.firstIndex(of: "（"),
              let close = body.firstIndex(of: "）") else { return nil }
        let inside = String(body[body.index(after: open)..<close])
        // 取第一段（空格前）作為日期，格式如「04/20」
        let datePart = inside.split(separator: " ").first.map(String.init) ?? inside
        guard datePart.contains("/") else { return nil }
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        return "\(year)/\(datePart)"
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        NotificationsView()
            .environment(NotificationStore())
    }
    .environment(FollowStore())
    .environment(UserStore())
    .environment(BookedSlotStore())
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        NotificationsView()
            .environment(NotificationStore())
    }
    .environment(FollowStore())
    .environment(UserStore())
    .environment(BookedSlotStore())
}
