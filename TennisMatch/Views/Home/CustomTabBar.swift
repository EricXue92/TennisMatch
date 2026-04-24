//
//  CustomTabBar.swift
//  TennisMatch
//
//  底部自訂 Tab Bar — 從 HomeView 提取的獨立組件
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var chatUnreadCount: Int
    var onCreateMatch: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "house.fill", label: "首頁", tag: 0)
            tabBarItem(icon: "calendar", label: "我的約球", tag: 1)
            centerTabButton
            tabBarItem(icon: "message.fill", label: "聊天", tag: 3, badgeCount: chatUnreadCount)
            tabBarItem(icon: "person.fill", label: "我的", tag: 4)
        }
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xl)
        .background(
            Rectangle()
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabBarItem(icon: String, label: LocalizedStringKey, tag: Int, badgeCount: Int = 0) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Theme.badge)
                            .clipShape(Circle())
                            .offset(x: 8, y: -4)
                    }
                }
                Text(label)
                    .font(Typography.micro)
            }
            .foregroundColor(selectedTab == tag ? Theme.primary : Theme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var centerTabButton: some View {
        Button {
            onCreateMatch()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Theme.primary)
                        .frame(width: 52, height: 52)
                        .shadow(color: Theme.primary.opacity(0.4), radius: 6, y: 2)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(y: -16)
                Text("一鍵約球")
                    .font(Typography.micro)
                    .foregroundColor(Theme.textSecondary)
                    .offset(y: -16)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
