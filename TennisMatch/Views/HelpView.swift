//
//  HelpView.swift
//  TennisMatch
//
//  幫助 — FAQ + 聯繫客服
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedFAQ: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(faqItems) { item in
                    faqRow(item)
                }

                contactSection
            }
            .padding(.horizontal, Spacing.md)
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
                Text("幫助")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func faqRow(_ item: FAQItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedFAQ = expandedFAQ == item.id ? nil : item.id
                }
            } label: {
                HStack {
                    Text(item.question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: expandedFAQ == item.id ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Spacing.md)
                .frame(minHeight: 44)
            }

            if expandedFAQ == item.id {
                Text(item.answer)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textBody)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var contactSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("找不到答案？")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Button {
                if let url = URL(string: "mailto:support@letstennis.app") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                    Text("聯繫客服")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.top, Spacing.md)
    }
}

// MARK: - FAQ Data

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

private let faqItems: [FAQItem] = [
    FAQItem(question: "如何發布約球？", answer: "點擊底部 Tab 欄中間的「+」按鈕，填寫約球信息後點擊「發布約球」即可。"),
    FAQItem(question: "如何報名別人的約球？", answer: "在首頁瀏覽約球列表，點擊感興趣的約球卡片進入詳情頁，點擊「報名」按鈕確認即可。"),
    FAQItem(question: "什麼是 NTRP？", answer: "NTRP（National Tennis Rating Program）是國際通用的網球技術分級標準，從 1.0（初學者）到 7.0（世界級），幫助你找到水平匹配的對手。"),
    FAQItem(question: "如何取消已報名的約球？", answer: "進入「我的約球」頁面，找到你要取消的約球，點擊「取消」按鈕確認即可。取消後會通知所有參與者。"),
    FAQItem(question: "如何創建賽事？", answer: "從側邊欄進入「賽事」頁面，點擊右上角「+ 建立賽事」按鈕，填寫賽事信息後發布。"),
    FAQItem(question: "如何封鎖其他用戶？", answer: "進入對方的個人主頁，點擊「封鎖」按鈕即可。被封鎖的用戶無法查看你的資料和約球，也無法向你發送私信。"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        HelpView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        HelpView()
    }
}
