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
                            .font(.system(size: 13, weight: .medium))
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
                    .font(Typography.caption)
                    .foregroundColor(Theme.textBody)
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
        .onTapGesture {
            notificationStore.markRead(id: notification.id)
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

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        NotificationsView()
            .environment(NotificationStore())
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        NotificationsView()
            .environment(NotificationStore())
    }
}
