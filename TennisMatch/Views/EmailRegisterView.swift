//
//  EmailRegisterView.swift
//  TennisMatch
//
//  郵箱註冊 — 輸入郵箱、驗證碼、設定密碼
//

import SwiftUI

struct EmailRegisterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var verificationCode = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var codeSent = false
    @State private var countdown = 60
    @State private var canResend = false
    @State private var timer: Timer?
    @State private var showProfileSetup = false
    @State private var validationMessage = ""
    @State private var showValidationError = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, code, password, confirmPassword }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.primaryLight)
                        .frame(width: 80, height: 80)
                    Text("✉️")
                        .font(.system(size: 36))
                }
                .padding(.top, Spacing.lg)

                // Title
                VStack(spacing: Spacing.xs) {
                    Text("郵箱註冊")
                        .font(Typography.title)
                        .foregroundColor(Theme.textPrimary)
                    Text("使用郵箱地址建立帳號")
                        .font(Typography.subtitle)
                        .foregroundColor(Theme.textSecondary)
                }

                // Form card
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("郵箱地址")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        HStack(spacing: Spacing.sm) {
                            TextField("請輸入郵箱", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(Typography.fieldValue)
                                .foregroundColor(Theme.textPrimary)
                                .focused($focusedField, equals: .email)

                            Button {
                                sendCode()
                            } label: {
                                Text(codeSent ? (canResend ? "重新發送" : "\(countdown)s") : "發送驗證碼")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(sendButtonEnabled ? .white : Theme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .background(sendButtonEnabled ? Theme.primary : Theme.chipUnselectedBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .disabled(!sendButtonEnabled)
                        }
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 48)
                        .background(Theme.inputBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.inputBorder, lineWidth: 1)
                        )
                    }

                    // Verification code
                    VStack(alignment: .leading, spacing: 6) {
                        Text("驗證碼")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        TextField("請輸入 6 位驗證碼", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .font(Typography.fieldValue)
                            .foregroundColor(Theme.textPrimary)
                            .focused($focusedField, equals: .code)
                            .onChange(of: verificationCode) { _, newValue in
                                verificationCode = String(newValue.filter(\.isNumber).prefix(6))
                            }
                            .padding(.horizontal, Spacing.md)
                            .frame(height: 48)
                            .background(Theme.inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Theme.inputBorder, lineWidth: 1)
                            )
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("設定密碼")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("請輸入密碼（至少 6 位）", text: $password)
                                } else {
                                    SecureField("請輸入密碼（至少 6 位）", text: $password)
                                }
                            }
                            .textContentType(.newPassword)
                            .font(Typography.fieldValue)
                            .foregroundColor(Theme.textPrimary)
                            .focused($focusedField, equals: .password)

                            Button { showPassword.toggle() } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 48)
                        .background(Theme.inputBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.inputBorder, lineWidth: 1)
                        )
                    }

                    // Confirm password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("確認密碼")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        HStack {
                            Group {
                                if showConfirmPassword {
                                    TextField("請再次輸入密碼", text: $confirmPassword)
                                } else {
                                    SecureField("請再次輸入密碼", text: $confirmPassword)
                                }
                            }
                            .textContentType(.newPassword)
                            .font(Typography.fieldValue)
                            .foregroundColor(Theme.textPrimary)
                            .focused($focusedField, equals: .confirmPassword)

                            Button { showConfirmPassword.toggle() } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 48)
                        .background(Theme.inputBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.inputBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(Spacing.md)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                // Validation error
                if showValidationError {
                    Text(validationMessage)
                        .font(Typography.small)
                        .foregroundColor(Theme.requiredText)
                        .transition(.opacity)
                }

                // Register button
                Button {
                    validate()
                } label: {
                    Text("註冊")
                        .font(Typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isFormValid ? Theme.primary : Theme.chipUnselectedBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("郵箱註冊")
                    .font(Typography.navTitle)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showProfileSetup) {
            RegisterView()
        }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Helpers

    private var sendButtonEnabled: Bool {
        !email.isEmpty && (!codeSent || canResend)
    }

    private var isFormValid: Bool {
        !email.isEmpty
            && verificationCode.count == 6
            && password.count >= 6
            && password == confirmPassword
    }

    private func sendCode() {
        codeSent = true
        countdown = 60
        canResend = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                canResend = true
                timer?.invalidate()
            }
        }
        focusedField = .code
    }

    private func validate() {
        if email.isEmpty {
            validationMessage = "請輸入郵箱地址"
        } else if !email.contains("@") || !email.contains(".") {
            validationMessage = "請輸入有效的郵箱地址"
        } else if verificationCode.count != 6 {
            validationMessage = "請輸入 6 位驗證碼"
        } else if password.count < 6 {
            validationMessage = "密碼至少需要 6 位"
        } else if password != confirmPassword {
            validationMessage = "兩次密碼不一致"
        } else {
            showProfileSetup = true
            return
        }
        withAnimation { showValidationError = true }
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        EmailRegisterView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        EmailRegisterView()
    }
}
