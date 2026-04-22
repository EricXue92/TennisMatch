//
//  TipDeveloperView.swift
//  TennisMatch
//
//  打賞開發者 — 支持 FPS / 支付寶 / 微信 / 信用卡
//

import SwiftUI

struct TipDeveloperView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAmount: Int? = 1 // nil = 自定義金額
    @State private var customAmountText: String = ""
    @State private var selectedMethod: PaymentMethod?
    @State private var showThankYou = false
    @FocusState private var customAmountFocused: Bool

    private let amounts = [
        TipAmount(label: "HK$10", subtitle: "一杯水", value: 10),
        TipAmount(label: "HK$30", subtitle: "一杯咖啡", value: 30),
        TipAmount(label: "HK$50", subtitle: "一筒新球", value: 50),
        TipAmount(label: "HK$100", subtitle: "一頓午餐", value: 100),
    ]

    private let methods: [PaymentMethod] = [
        PaymentMethod(id: "fps", name: "轉數快 FPS", icon: "banknote.fill", color: Color(hex: 0x0072CE)),
        PaymentMethod(id: "alipay", name: "支付寶", icon: "a.circle.fill", color: Color(hex: 0x1677FF)),
        PaymentMethod(id: "wechat", name: "微信支付", icon: "message.fill", color: Color(hex: 0x07C160)),
        PaymentMethod(id: "card", name: "信用卡 / Apple Pay", icon: "creditcard.fill", color: Color(hex: 0x333333)),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // 头部
                headerSection

                // 金额选择
                amountSection

                // 支付方式
                paymentMethodSection

                // 打賞按钮
                tipButton

                // 底部说明
                footerNote
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, 40)
        }
        .background(Theme.inputBg)
        .navigationTitle("打賞開發者")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                }
            }
        }
        .fullScreenCover(isPresented: $showThankYou) {
            thankYouView
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.primaryLight)
                    .frame(width: 80, height: 80)
                Text("🎾")
                    .font(.system(size: 36))
            }

            Text("感謝你的支持！")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Text("Let'sTennis 是一個免費的約球App\n你的打賞是我繼續開發的動力")
                .font(Typography.caption)
                .foregroundColor(Theme.textCaption)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Amount Selection

    /// 当前有效金额（用于按钮文案和可用性判断）
    private var effectiveAmount: Int? {
        if let index = selectedAmount {
            return amounts[index].value
        }
        return Int(customAmountText)
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("選擇金額")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(amounts.indices, id: \.self) { index in
                    let amount = amounts[index]
                    let isSelected = selectedAmount == index
                    Button {
                        selectedAmount = index
                        customAmountText = ""
                        customAmountFocused = false
                    } label: {
                        VStack(spacing: 4) {
                            Text(amount.label)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(isSelected ? .white : Theme.textPrimary)
                            Text(amount.subtitle)
                                .font(Typography.fieldLabel)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : Theme.textCaption)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(isSelected ? Theme.primary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            if !isSelected {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Theme.inputBorder, lineWidth: 1)
                            }
                        }
                    }
                }
            }

            // 自定義金額
            let isCustom = selectedAmount == nil
            HStack(spacing: Spacing.sm) {
                Text("HK$")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCustom ? Theme.primary : Theme.textCaption)

                TextField("自定義金額", text: $customAmountText)
                    .font(.system(size: 16, weight: .medium))
                    .keyboardType(.numberPad)
                    .focused($customAmountFocused)
                    .onChange(of: customAmountText) { _, newValue in
                        // 输入时切换到自定义模式
                        if !newValue.isEmpty {
                            selectedAmount = nil
                        }
                    }
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 48)
            .background(isCustom ? Theme.primaryLight : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isCustom ? Theme.primary : Theme.inputBorder, lineWidth: isCustom ? 1.5 : 1)
            }
            .onTapGesture {
                selectedAmount = nil
                customAmountFocused = true
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Payment Method

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("支付方式")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 0) {
                ForEach(methods) { method in
                    let isSelected = selectedMethod?.id == method.id
                    Button {
                        selectedMethod = method
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: method.icon)
                                .font(.system(size: 18))
                                .foregroundColor(method.color)
                                .frame(width: 32)

                            Text(method.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textPrimary)

                            Spacer()

                            ZStack {
                                Circle()
                                    .stroke(isSelected ? Theme.primary : Theme.inputBorder, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                if isSelected {
                                    Circle()
                                        .fill(Theme.primary)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 52)
                    }

                    if method.id != methods.last?.id {
                        Theme.inputBorder.frame(height: 1)
                            .padding(.leading, 56)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Tip Button

    private var canTip: Bool {
        selectedMethod != nil && effectiveAmount != nil && (effectiveAmount ?? 0) > 0
    }

    private var tipButton: some View {
        Button {
            showThankYou = true
        } label: {
            let label = effectiveAmount.map { "打賞 HK$\($0)" } ?? "打賞"
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canTip ? Theme.primary : Theme.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(!canTip)
    }

    // MARK: - Footer

    private var footerNote: some View {
        VStack(spacing: 4) {
            Text("所有打賞金額將直接用於 App 開發與伺服器維護")
                .font(Typography.fieldLabel)
                .foregroundColor(Theme.textCaption)
            Text("打賞非必要，你的使用就是最大的支持 ❤️")
                .font(Typography.fieldLabel)
                .foregroundColor(Theme.textCaption)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Thank You

    private var thankYouView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.primaryLight)
                    .frame(width: 120, height: 120)
                Text("🙏")
                    .font(.system(size: 56))
            }

            Text("感謝你的打賞！")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Text("你的支持讓 Let'sTennis 變得更好\n我們會繼續努力開發更多功能")
                .font(Typography.caption)
                .foregroundColor(Theme.textCaption)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()

            Button {
                showThankYou = false
                dismiss()
            } label: {
                Text("返回")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.inputBg)
    }
}

// MARK: - Models

private struct TipAmount {
    let label: String
    let subtitle: String
    let value: Int
}

private struct PaymentMethod: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TipDeveloperView()
    }
}
