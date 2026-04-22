//
//  PhoneVerificationView.swift
//  TennisMatch
//
//  手機驗證碼頁面 — 6 位數 OTP 輸入
//

import SwiftUI

struct PhoneVerificationView: View {
    let phoneNumber: String

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFieldFocused: Bool

    @AppStorage("maskedPhone") private var maskedPhone = ""

    @State private var code = ""
    @State private var countdown = 60
    @State private var canResend = false
    @State private var timer: Timer?
    @State private var showRegister = false
    @State private var toastMessage: String?
    @State private var isLoading = false

    private let codeLength = 6

    var body: some View {
        VStack(spacing: 0) {
            content
            Spacer(minLength: 0)
            actionSection
                .padding(.bottom, Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
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
                Text("驗證碼")
                    .font(Typography.navTitle)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { startCountdown(); isFieldFocused = true }
        .onDisappear { timer?.invalidate() }
        .navigationDestination(isPresented: $showRegister) {
            RegisterView()
        }
        .overlay(alignment: .top) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.textDeep.opacity(0.92))
                    .clipShape(Capsule())
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { toastMessage = nil }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toastMessage)
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: 0)
            iconView
            textGroup
            codeInputRow
            countdownText
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Icon

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Theme.primaryLight)
                .frame(width: 80, height: 80)
            Text("📱")
                .font(.system(size: 36))
        }
    }

    // MARK: - Text Group

    private var textGroup: some View {
        VStack(spacing: Spacing.xs) {
            Text("輸入驗證碼")
                .font(Typography.title)
                .foregroundColor(Theme.textPrimary)

            Text("我們已將 6 位數驗證碼發送至")
                .font(Typography.subtitle)
                .foregroundColor(Theme.textSecondary)

            Text(phoneNumber)
                .font(Typography.body)
                .foregroundColor(Theme.textPrimary)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Code Input

    private var codeInputRow: some View {
        ZStack {
            // Hidden TextField to capture keyboard input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFieldFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { oldValue, newValue in
                    let filtered = String(newValue.filter(\.isNumber).prefix(codeLength))
                    if filtered != newValue { code = filtered }
                }

            HStack(spacing: Spacing.sm) {
                ForEach(0..<codeLength, id: \.self) { index in
                    codeBox(at: index)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFieldFocused = true }
        }
    }

    private func codeBox(at index: Int) -> some View {
        let isFilled = index < code.count
        let isActive = index == code.count && isFieldFocused
        let digit = isFilled
            ? String(code[code.index(code.startIndex, offsetBy: index)])
            : ""

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isFilled || isActive ? Theme.primary : Theme.border,
                    lineWidth: isFilled || isActive ? 2 : 1.5
                )

            if isFilled {
                Text(digit)
                    .font(Typography.codeDigit)
                    .foregroundColor(Theme.textPrimary)
            } else if isActive {
                CursorView()
            }
        }
        .frame(width: 48, height: 56)
    }

    // MARK: - Countdown

    private var countdownText: some View {
        Text("\(countdown) 秒後可重新發送")
            .font(Typography.caption)
            .foregroundColor(Theme.textSecondary)
            .opacity(canResend ? 0 : 1)
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: Spacing.md) {
            Button {
                guard code.count == codeLength else { return }
                isLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    isLoading = false
                    maskedPhone = phoneNumber
                    showRegister = true
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Text("驗證並登入")
                        .font(Typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(code.count == codeLength ? Theme.primary : Theme.chipUnselectedBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .disabled(code.count != codeLength || isLoading)

            HStack(spacing: 0) {
                Text("沒有收到驗證碼？")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textSecondary)

                Button {
                    guard canResend else { return }
                    resend()
                } label: {
                    Text("重新發送")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(canResend ? Theme.primary : Theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Timer

    private func startCountdown() {
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
    }

    private func resend() {
        code = ""
        startCountdown()
        withAnimation { toastMessage = "驗證碼已重新發送至 \(phoneNumber)" }
    }
}

// MARK: - Cursor Blink

private struct CursorView: View {
    @State private var visible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Theme.primary)
            .frame(width: 2, height: 24)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        PhoneVerificationView(phoneNumber: "+86 138****8888")
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        PhoneVerificationView(phoneNumber: "+86 138****8888")
    }
}
