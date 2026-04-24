//
//  DrawerView.swift
//  TennisMatch
//
//  側邊抽屜導航 — 從 HomeView 抽取，供所有需要側邊選單的頁面使用
//

import SwiftUI

// MARK: - 抽屜目標頁面枚舉

enum DrawerDestination: Hashable {
    case tournaments
    case matchAssistant
    case reviews
    case notifications
    case blockList
    case inviteFriends
    case tipDeveloper
    case settings
    case help
}

// MARK: - DrawerView

struct DrawerView: View {
    @Binding var isPresented: Bool
    let unreadNotificationCount: Int
    let onNavigate: (DrawerDestination) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            // 半透明背景，點擊關閉抽屜
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isPresented = false
                    }
                }

            // 抽屜面板
            drawerPanel
                .frame(width: 300)
                .transition(.move(edge: .leading))
        }
    }

    // MARK: - 抽屜面板

    private var drawerPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 60)

            // 選單項目列表
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    drawerMenuItem(icon: "🏆", label: "賽事") {
                        onNavigate(.tournaments)
                    }
                    drawerMenuItem(icon: "🤖", label: "約球助理") {
                        onNavigate(.matchAssistant)
                    }
                    drawerMenuItem(icon: "⭐", label: "評價", badge: 2) {
                        onNavigate(.reviews)
                    }
                    drawerMenuItem(
                        icon: "🔔",
                        label: "通知",
                        badge: unreadNotificationCount
                    ) {
                        onNavigate(.notifications)
                    }
                    drawerMenuItem(icon: "🚫", label: "封鎖名單") {
                        onNavigate(.blockList)
                    }
                    drawerMenuItem(icon: "📨", label: "邀請好友") {
                        onNavigate(.inviteFriends)
                    }
                    drawerMenuItem(icon: "☕", label: "打賞開發者") {
                        onNavigate(.tipDeveloper)
                    }

                    // 分隔線
                    Rectangle()
                        .fill(Theme.inputBorder)
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.vertical, Spacing.sm)

                    drawerMenuItem(icon: "⚙️", label: "設定", isSecondary: true) {
                        onNavigate(.settings)
                    }
                    drawerMenuItem(icon: "❓", label: "幫助", isSecondary: true) {
                        onNavigate(.help)
                    }
                }
            }

            Spacer()

            // 版本號
            Text("v0.1.0")
                .font(Typography.fieldLabel)
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
        }
        .frame(maxHeight: .infinity)
        .background(Theme.surface)
    }

    // MARK: - 抽屜選單項目

    private func drawerMenuItem(
        icon: String,
        label: LocalizedStringKey,
        badge: Int = 0,
        isSecondary: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            withAnimation(.easeIn(duration: 0.2)) {
                isPresented = false
            }
            action?()
        } label: {
            HStack {
                Text(icon)
                    .font(.system(size: 20))
                    .frame(width: 28)
                Text(label)
                    .font(Typography.bodyMedium)
                    .foregroundColor(isSecondary ? Theme.textCaption : Theme.textPrimary)
                Spacer()
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Theme.badge)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .frame(height: 48)
        }
    }
}
