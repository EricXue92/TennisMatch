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
            TermsOfServiceView()
        }
        .navigationDestination(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section {
            settingsRow(icon: "phone.fill", title: "手機號碼", value: "+86 138****8888")
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
                        .background(Capsule().fill(Theme.primary))
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
    @State private var wechatLinked = true
    @State private var appleLinked = true
    @State private var googleLinked = false
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

// MARK: - 用戶協議

private struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("最後更新：2026 年 4 月 1 日")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)

                sectionBlock(title: "1. 服務說明") {
                    "Let'stennis（以下簡稱「本平台」）是一款面向業餘網球愛好者的約球社交應用程式。本平台為用戶提供發布約球、匹配球友、賽事報名及社交互動等服務。使用本平台即表示您同意遵守本協議的所有條款。"
                }

                sectionBlock(title: "2. 用戶資格") {
                    "您必須年滿 16 歲方可註冊使用本平台。未成年用戶需在監護人同意下使用。您需要提供真實、準確的個人資料,包括 NTRP 自評水平。"
                }

                sectionBlock(title: "3. 用戶行為準則") {
                    "用戶在使用本平台時應遵守以下規範：\n\n• 準時參加已報名的約球活動,連續爽約將影響信譽積分\n• 尊重其他球友,禁止發布侮辱性或歧視性言論\n• 如實填寫 NTRP 水平,禁止故意虛報以獲取不當匹配\n• 約球取消需提前通知,以便其他參與者調整安排\n• 禁止利用平台從事任何商業推廣或廣告行為"
                }

                sectionBlock(title: "4. 信譽系統") {
                    "本平台採用信譽積分系統以維護社區品質。爽約、遲到、不當行為將扣減信譽積分。積分過低可能導致帳號功能限制或停用。球友互評結果可能影響您的 NTRP 校準建議。"
                }

                sectionBlock(title: "5. 免責聲明") {
                    "本平台僅提供約球媒合服務,不對用戶在線下活動中發生的任何意外、傷害或糾紛承擔責任。用戶參與約球活動時應注意自身安全,建議購買適當的運動保險。天氣資訊僅供參考,用戶應自行判斷是否適合進行戶外活動。"
                }

                sectionBlock(title: "6. 知識產權") {
                    "本平台的所有內容（包括但不限於介面設計、圖標、文字及程式碼）均受知識產權法保護。未經授權,禁止複製、修改或分發本平台的任何內容。"
                }

                sectionBlock(title: "7. 帳號終止") {
                    "本平台保留在用戶違反本協議或法律法規的情況下，暫停或終止用戶帳號的權利。用戶可隨時申請刪除帳號,帳號刪除後相關數據將在 30 天內永久清除。"
                }

                sectionBlock(title: "8. 協議修改") {
                    "本平台保留隨時修改本協議的權利。重大修改將通過應用內通知告知用戶。繼續使用本平台即表示您接受修改後的協議。"
                }

                Text("如有任何疑問,請聯繫 support@letstennis.app")
                    .font(Typography.caption)
                    .foregroundColor(Theme.primary)
                    .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.lg)
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
                Text("用戶協議")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func sectionBlock(title: String, content: () -> String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Text(content())
                .font(Typography.caption)
                .foregroundColor(Theme.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 隱私政策

private struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("最後更新：2026 年 4 月 1 日")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)

                sectionBlock(title: "1. 資訊收集") {
                    "我們可能收集以下資訊：\n\n• 帳號資訊：手機號碼、暱稱、性別、地區\n• 運動資訊：NTRP 自評水平、約球記錄、賽事成績\n• 社交資訊：關注列表、聊天記錄、評價內容\n• 設備資訊：設備型號、作業系統版本（用於優化體驗）\n• 位置資訊：僅在您授權後用於就近推薦球場"
                }

                sectionBlock(title: "2. 資訊使用") {
                    "我們收集的資訊將用於：\n\n• 提供約球媒合及球友推薦服務\n• NTRP 水平校準與匹配優化\n• 信譽積分計算與社區品質維護\n• 發送約球提醒、報名確認等通知\n• 改善應用體驗及功能開發"
                }

                sectionBlock(title: "3. 資訊共享") {
                    "您的個人資料（暱稱、NTRP、信譽分等）會在以下場景對其他用戶可見：\n\n• 發布或報名約球時,其他參與者可看到您的基本資料\n• 公開個人主頁中展示的資訊（可在隱私設置中調整可見範圍）\n• 賽事排名及成績\n\n我們不會將您的個人資訊出售給第三方。"
                }

                sectionBlock(title: "4. 資訊保護") {
                    "我們採取合理的技術和管理措施保護您的個人資訊安全,包括數據加密傳輸、存取權限控制及定期安全審計。但請注意,互聯網環境下不存在絕對安全的傳輸方式。"
                }

                sectionBlock(title: "5. 用戶權利") {
                    "您有權：\n\n• 查閱和更正您的個人資料\n• 調整隱私設置,控制資料的可見範圍\n• 要求刪除您的帳號及相關數據\n• 撤回位置授權等可選權限\n• 匯出您的個人數據副本"
                }

                sectionBlock(title: "6. Cookie 與追蹤") {
                    "本應用不使用網頁 Cookie。我們可能使用匿名統計工具分析應用使用情況,以改善服務品質。您可以在設備設置中關閉數據分析。"
                }

                sectionBlock(title: "7. 未成年人保護") {
                    "我們不會故意收集 16 歲以下未成年人的個人資訊。如發現未成年人未經監護人同意註冊,我們將及時刪除相關帳號及資訊。"
                }

                sectionBlock(title: "8. 政策更新") {
                    "本隱私政策可能不定期更新。重大變更將通過應用內通知告知您。建議您定期查閱本政策以了解最新的隱私保護措施。"
                }

                Text("隱私相關問題請聯繫 privacy@letstennis.app")
                    .font(Typography.caption)
                    .foregroundColor(Theme.primary)
                    .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.lg)
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
                Text("隱私政策")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func sectionBlock(title: String, content: () -> String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Text(content())
                .font(Typography.caption)
                .foregroundColor(Theme.textBody)
                .fixedSize(horizontal: false, vertical: true)
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
