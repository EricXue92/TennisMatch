//
//  SettingsView.swift
//  TennisMatch
//
//  設定頁面
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("maskedPhone") private var maskedPhone = ""
    @AppStorage("matchReminders") private var matchReminders = true
    @AppStorage("chatNotifications") private var chatNotifications = true
    @AppStorage("tournamentUpdates") private var tournamentUpdates = true
    @AppStorage("profileVisibility") private var profileVisibility = "所有人"
    @AppStorage("dmPermission") private var dmPermission = "所有人"
    @State private var showLogoutAlert = false
    @State private var toastMessage: String?
    @State private var showChangePassword = false
    @State private var showLinkedAccounts = false
    @State private var showTerms = false
    @State private var showPrivacy = false

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
        .overlay(alignment: .top) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, Spacing.xs)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { toastMessage = nil }
                        }
                    }
            }
        }
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
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet()
        }
        .sheet(isPresented: $showLinkedAccounts) {
            LinkedAccountsSheet()
        }
        .navigationDestination(isPresented: $showTerms) {
            TermsView()
        }
        .navigationDestination(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section {
            settingsRow(icon: "phone.fill", title: "手機號碼", value: maskedPhone.isEmpty ? "未綁定" : maskedPhone)
            tappableRow(icon: "lock.fill", title: "修改密碼") {
                showChangePassword = true
            }
            tappableRow(icon: "link", title: "關聯帳號", value: "微信、Apple") {
                showLinkedAccounts = true
            }
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
            tappableRow(icon: "doc.text.fill", title: "用戶協議") {
                showTerms = true
            }
            tappableRow(icon: "hand.raised.fill", title: "隱私政策") {
                showPrivacy = true
            }
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

    private func settingsRow(icon: String, title: String, value: String? = nil) -> some View {
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
        }
    }

    private func tappableRow(icon: String, title: String, value: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

// MARK: - 修改密碼

private struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var toastMessage: String?
    @FocusState private var focusedField: PasswordField?

    private enum PasswordField { case current, new, confirm }

    private var canSubmit: Bool {
        !currentPassword.isEmpty && newPassword.count >= 6 && newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("請輸入當前密碼並設定新密碼")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textCaption)

                VStack(spacing: Spacing.md) {
                    passwordField(title: "當前密碼", text: $currentPassword, field: .current)
                    passwordField(title: "新密碼（至少 6 位）", text: $newPassword, field: .new)
                    passwordField(title: "確認新密碼", text: $confirmPassword, field: .confirm)
                }

                if !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword != confirmPassword {
                    Text("兩次輸入的密碼不一致")
                        .font(Typography.small)
                        .foregroundColor(Theme.requiredText)
                }

                Spacer()

                Button {
                    focusedField = nil
                    // 驗證當前密碼
                    guard !currentPassword.isEmpty else {
                        withAnimation { toastMessage = "請輸入目前的密碼" }
                        return
                    }
                    // 驗證新密碼長度（Mock 階段：接受任何非空當前密碼）
                    guard newPassword.count >= 6 else {
                        withAnimation { toastMessage = "新密碼至少需要 6 位" }
                        return
                    }
                    // 驗證兩次新密碼一致
                    guard newPassword == confirmPassword else {
                        withAnimation { toastMessage = "兩次新密碼不一致" }
                        return
                    }
                    // 所有驗證通過，顯示成功並關閉
                    withAnimation { toastMessage = "密碼修改成功" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        dismiss()
                    }
                } label: {
                    Text("確認修改")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canSubmit ? Theme.primary : Theme.chipUnselectedBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!canSubmit)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .overlay(alignment: .top) {
                if let msg = toastMessage {
                    Text(msg)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Capsule().fill(msg == "密碼修改成功" ? Theme.primary : Theme.requiredText))
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("修改密碼")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func passwordField(title: String, text: Binding<String>, field: PasswordField) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textBody)
            SecureField("", text: text)
                .font(Typography.fieldValue)
                .padding(Spacing.sm)
                .background(Theme.inputBg)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(focusedField == field ? Theme.primary : Theme.inputBorder, lineWidth: 1)
                )
                .focused($focusedField, equals: field)
        }
    }
}

// MARK: - 關聯帳號

private struct LinkedAccountsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("linkedWechat") private var wechatLinked = true
    @AppStorage("linkedApple") private var appleLinked = true
    @AppStorage("linkedGoogle") private var googleLinked = false
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("管理第三方登錄方式")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textCaption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)

                VStack(spacing: 0) {
                    accountRow(
                        icon: "message.fill",
                        iconColor: Theme.accentGreen,
                        title: "微信",
                        isLinked: $wechatLinked
                    )
                    Theme.divider.frame(height: 1).padding(.leading, 60)
                    accountRow(
                        icon: "apple.logo",
                        iconColor: Theme.textPrimary,
                        title: "Apple",
                        isLinked: $appleLinked
                    )
                    Theme.divider.frame(height: 1).padding(.leading, 60)
                    accountRow(
                        icon: "g.circle.fill",
                        iconColor: .red,
                        title: "Google",
                        isLinked: $googleLinked
                    )
                }
                .padding(.horizontal, Spacing.md)

                Spacer()

                Text("至少需要保留一種登錄方式")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.bottom, Spacing.lg)
            }
            .overlay(alignment: .top) {
                if let msg = toastMessage {
                    Text(msg)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Capsule().fill(Color.black.opacity(0.8)))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, Spacing.xs)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { toastMessage = nil }
                            }
                        }
                }
            }
            .navigationTitle("關聯帳號")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func accountRow(icon: String, iconColor: Color, title: String, isLinked: Binding<Bool>) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)

            Text(title)
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button {
                let linkedCount = [wechatLinked, appleLinked, googleLinked].filter { $0 }.count
                if isLinked.wrappedValue && linkedCount <= 1 {
                    withAnimation { toastMessage = "至少需要保留一種登錄方式" }
                    return
                }
                withAnimation {
                    isLinked.wrappedValue.toggle()
                    toastMessage = isLinked.wrappedValue ? "已關聯\(title)" : "已取消關聯\(title)"
                }
            } label: {
                Text(isLinked.wrappedValue ? "已關聯" : "關聯")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isLinked.wrappedValue ? Theme.textBody : .white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 32)
                    .background(isLinked.wrappedValue ? .clear : Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        if isLinked.wrappedValue {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.inputBorder, lineWidth: 1)
                        }
                    }
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.sm)
    }
}

// NOTE: TermsView and PrivacyPolicyView are now standalone files.

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
