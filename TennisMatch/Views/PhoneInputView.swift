//
//  PhoneInputView.swift
//  TennisMatch
//
//  手機號碼輸入 — 填寫號碼後獲取驗證碼
//

import SwiftUI

struct PhoneInputView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPhoneFocused: Bool

    @State private var phoneNumber = ""
    @State private var countryCode = "+852"
    @State private var showVerification = false
    @State private var errorMessage = ""
    @State private var showError = false

    private let countryCodes: [(code: String, label: String, lengths: [Int])] = [
        ("+852", "🇭🇰 +852", [8]),
        ("+86",  "🇨🇳 +86",  [11]),
        ("+886", "🇹🇼 +886", [9, 10]),
        ("+1",   "🇺🇸 +1",   [10]),
        ("+44",  "🇬🇧 +44",  [10, 11]),
        ("+81",  "🇯🇵 +81",  [10, 11]),
    ]

    private var expectedLengths: [Int] {
        countryCodes.first { $0.code == countryCode }?.lengths ?? [8, 11]
    }

    private var lengthHint: String {
        let lengths = expectedLengths
        if lengths.count == 1 {
            return "\(lengths[0]) 位"
        }
        return "\(lengths.min()!)-\(lengths.max()!) 位"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.lg) {
                Spacer(minLength: 0)

                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.primaryLight)
                        .frame(width: 80, height: 80)
                    Text("📱")
                        .font(.system(size: 36))
                }

                // Title
                VStack(spacing: Spacing.xs) {
                    Text("手機號碼登入")
                        .font(Typography.title)
                        .foregroundColor(Theme.textPrimary)
                    Text("請輸入您的手機號碼，我們將發送驗證碼")
                        .font(Typography.subtitle)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Phone input
                HStack(spacing: Spacing.sm) {
                    // Country code picker
                    Menu {
                        ForEach(countryCodes, id: \.code) { item in
                            Button(item.label) {
                                countryCode = item.code
                                withAnimation { showError = false }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(countryCode)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.inputBorder, lineWidth: 1)
                        )
                    }

                    TextField("請輸入手機號碼", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .focused($isPhoneFocused)
                        .onChange(of: phoneNumber) { _, newValue in
                            phoneNumber = String(newValue.filter(\.isNumber).prefix(11))
                            if showError { withAnimation { showError = false } }
                        }
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(showError ? Theme.requiredText : Theme.inputBorder, lineWidth: showError ? 1.5 : 1)
                        )
                }
                .padding(.horizontal, Spacing.md)

                // 號碼長度提示
                Text("請輸入 \(lengthHint) 數字的手機號碼")
                    .font(Typography.fieldLabel)
                    .foregroundColor(Theme.textHint)

                // 錯誤提示
                if showError {
                    Text(errorMessage)
                        .font(Typography.small)
                        .foregroundColor(Theme.requiredText)
                        .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.md)

            // Button
            Button {
                let digits = phoneNumber.filter(\.isNumber)
                if digits.isEmpty {
                    errorMessage = "請輸入手機號碼"
                    withAnimation { showError = true }
                } else if !expectedLengths.contains(digits.count) {
                    errorMessage = "手機號碼長度不正確，\(countryCode) 號碼應為 \(lengthHint) 數字"
                    withAnimation { showError = true }
                } else {
                    showVerification = true
                }
            } label: {
                Text("獲取驗證碼")
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(!phoneNumber.isEmpty ? Theme.primary : Theme.chipUnselectedBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(phoneNumber.isEmpty)
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
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
                Text("手機登入")
                    .font(Typography.navTitle)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { isPhoneFocused = true }
        .navigationDestination(isPresented: $showVerification) {
            PhoneVerificationView(phoneNumber: maskedDisplay)
        }
    }

    // MARK: - Helpers

    private var maskedDisplay: String {
        let digits = phoneNumber.filter(\.isNumber)
        if digits.count >= 8 {
            let prefix = String(digits.prefix(3))
            let suffix = String(digits.suffix(4))
            return "\(countryCode) \(prefix)****\(suffix)"
        }
        return "\(countryCode) \(digits)"
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        PhoneInputView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        PhoneInputView()
    }
}
