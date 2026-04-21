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
        ContentUnavailableView(
            "暫無通知",
            systemImage: "bell.slash",
            description: Text("報名、確認、改期等通知會顯示在這裡")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    MatchNotification(type: .accepted, title: "報名已接受", body: "你報名的 Michael 單打約球（04/28 跑馬地）已確認", time: "2 天前", isRead: true),
    MatchNotification(type: .signUp, title: "新的報名", body: "阿豪 報名了你發起的雙打約球（04/25 將軍澳）", time: "2 天前", isRead: true),
    MatchNotification(type: .updated, title: "約球更新", body: "大衛 的雙打約球地點更改為歌和老街公園", time: "3 天前", isRead: true),
    MatchNotification(type: .cancelled, title: "約球取消", body: "麗莎 取消了雙打約球（04/20 香港網球中心）", time: "3 天前", isRead: true),
    MatchNotification(type: .signUp, title: "新的報名", body: "思慧 報名了你發起的單打約球（04/30 將軍澳）", time: "4 天前", isRead: true),
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
