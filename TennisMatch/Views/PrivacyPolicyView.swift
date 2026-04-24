//
//  PrivacyPolicyView.swift
//  TennisMatch
//
//  隱私政策頁面
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Group {
                    sectionTitle("1. 引言")
                    sectionBody("""
                    Let's Tennis（以下簡稱「我們」）非常重視您的隱私。本隱私政策說明我們如何收集、使用、\
                    儲存和保護您的個人資訊。使用本應用即表示您同意本政策的內容。
                    """)

                    sectionTitle("2. 我們收集的資訊")
                    sectionBody("""
                    2.1 帳號資訊：用戶名、性別、年齡段、手機號碼或郵箱地址。\n\
                    2.2 運動資訊：NTRP 等級、比賽類型偏好、常去球場、可用時間。\n\
                    2.3 互動資訊：聊天記錄、約球記錄、評價內容、關注列表。\n\
                    2.4 裝置資訊：裝置型號、作業系統版本、應用版本。\n\
                    2.5 位置資訊：僅在您授權後用於球場推薦，不會在後台持續追蹤。
                    """)

                    sectionTitle("3. 資訊的使用")
                    sectionBody("""
                    3.1 提供約球匹配與球友推薦服務。\n\
                    3.2 維護信譽系統，計算信譽積分。\n\
                    3.3 發送約球通知、系統公告等消息。\n\
                    3.4 改善應用功能與用戶體驗。\n\
                    3.5 保障平台安全，防止欺詐和濫用。
                    """)

                    sectionTitle("4. 資訊共享")
                    sectionBody("""
                    4.1 我們不會向第三方出售您的個人資訊。\n\
                    4.2 您的公開資料（用戶名、NTRP、信譽分）對其他用戶可見，以便約球匹配。\n\
                    4.3 以下情況可能共享資訊：\n\
                    　　• 經您明確授權同意；\n\
                    　　• 法律法規要求或政府機關依法調取；\n\
                    　　• 為保護用戶安全或公共利益而必要時。
                    """)

                    sectionTitle("5. 資訊儲存與安全")
                    sectionBody("""
                    5.1 您的資訊儲存在安全的伺服器中，採用業界標準的加密技術保護。\n\
                    5.2 我們定期進行安全評估，持續改善資訊安全措施。\n\
                    5.3 儘管我們竭力保護您的資訊，但無法保證互聯網傳輸的絕對安全。\n\
                    5.4 帳號刪除後，我們將在合理期限內（不超過 30 天）刪除您的個人資訊。
                    """)
                }

                Group {
                    sectionTitle("6. 您的權利")
                    sectionBody("""
                    6.1 查閱權：您可隨時查閱您的個人資訊。\n\
                    6.2 更正權：您可修改個人資料中的不準確資訊。\n\
                    6.3 刪除權：您可申請刪除帳號及相關資訊。\n\
                    6.4 撤回同意權：您可隨時撤回對資訊收集和使用的授權。\n\
                    6.5 導出權：您可申請導出您的個人資訊副本。
                    """)

                    sectionTitle("7. Cookie 與追蹤技術")
                    sectionBody("""
                    7.1 本應用可能使用 Cookie 或類似技術以改善服務。\n\
                    7.2 您可以在裝置設定中管理 Cookie 偏好。\n\
                    7.3 我們不使用第三方追蹤工具收集您的瀏覽習慣。
                    """)

                    sectionTitle("8. 未成年人保護")
                    sectionBody("""
                    8.1 14 歲以下的未成年人不應使用本應用。\n\
                    8.2 14-18 歲未成年人應在監護人知情同意下使用本應用。\n\
                    8.3 如我們發現未經監護人同意收集了未成年人資訊，將立即刪除。
                    """)

                    sectionTitle("9. 隱私政策更新")
                    sectionBody("""
                    9.1 我們可能不時更新本隱私政策。\n\
                    9.2 重大變更將通過應用內通知告知您。\n\
                    9.3 繼續使用本應用即表示您接受更新後的政策。
                    """)

                    sectionTitle("10. 聯繫我們")
                    sectionBody("""
                    如您對本隱私政策有任何疑問或建議，歡迎通過以下方式聯繫我們：\n\
                    郵箱：support@letstennis.app\n\
                    應用內：設定 → 幫助與客服
                    """)

                    Text("最後更新日期：2026 年 4 月 1 日")
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textHint)
                        .padding(.top, Spacing.sm)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.sectionTitle)
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("隱私政策")
                    .font(Typography.navTitle)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Components

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Typography.button)
            .foregroundColor(Theme.textPrimary)
            .padding(.top, Spacing.xs)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(Typography.bodyMedium)
            .foregroundColor(Theme.textBody)
            .lineSpacing(4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
