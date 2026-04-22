//
//  SettingsView.swift
//  TennisMatch
//
//  設定頁面
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") private var isLoggedIn = true
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
                isLoggedIn = false
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
                    .font(Typography.fieldValue)
                    .foregroundColor(Theme.textPrimary)
            }
            .tint(Theme.primary)

            Toggle(isOn: $chatNotifications) {
                Label("聊天消息", systemImage: "bubble.left.fill")
                    .font(Typography.fieldValue)
                    .foregroundColor(Theme.textPrimary)
            }
            .tint(Theme.primary)

            Toggle(isOn: $tournamentUpdates) {
                Label("賽事更新", systemImage: "trophy.fill")
                    .font(Typography.fieldValue)
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
                    .font(Typography.fieldValue)
                    .foregroundColor(Theme.textPrimary)
            }

            Picker(selection: $dmPermission) {
                Text("所有人").tag("所有人")
                Text("僅關注者").tag("僅關注者")
                Text("關閉").tag("關閉")
            } label: {
                Label("誰能私信我", systemImage: "envelope.fill")
                    .font(Typography.fieldValue)
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
                .font(Typography.fieldValue)
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
