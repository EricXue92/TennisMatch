//
//  TermsView.swift
//  TennisMatch
//
//  服務條款頁面
//

import SwiftUI

struct TermsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Group {
                    sectionTitle("1. 服務概述")
                    sectionBody("""
                    歡迎使用 Let's Tennis（以下簡稱「本應用」）。本應用由 Let's Tennis 團隊開發並運營，\
                    旨在為業餘網球愛好者提供約球、社交及球友匹配服務。\
                    使用本應用即表示您同意遵守以下服務條款。如果您不同意任何條款，請停止使用本應用。
                    """)

                    sectionTitle("2. 帳號與註冊")
                    sectionBody("""
                    2.1 您須提供真實、準確的個人資訊進行註冊。\n\
                    2.2 每位用戶僅可註冊一個帳號，禁止冒用他人資訊。\n\
                    2.3 您有義務妥善保管帳號密碼，因帳號洩漏導致的損失由用戶自行承擔。\n\
                    2.4 我們保留因違規行為暫停或終止帳號的權利。
                    """)

                    sectionTitle("3. 用戶行為規範")
                    sectionBody("""
                    3.1 用戶應以友善、尊重的態度與其他球友互動。\n\
                    3.2 禁止發布任何違法、色情、暴力、歧視性或騷擾性內容。\n\
                    3.3 禁止惡意刷分、虛報 NTRP 水平或偽造比賽記錄。\n\
                    3.4 約球後無故爽約將影響信譽積分，連續爽約可能導致帳號限制。\n\
                    3.5 禁止利用本應用進行任何商業推廣或非法交易。
                    """)

                    sectionTitle("4. 約球與匹配服務")
                    sectionBody("""
                    4.1 本應用提供約球發布與智能匹配功能，但不保證每次匹配均能成功。\n\
                    4.2 用戶在使用約球服務時，應自行確認場地可用性和天氣狀況。\n\
                    4.3 因天氣、場地等不可控因素導致的約球取消，不計入爽約記錄。\n\
                    4.4 本應用不對用戶間因約球產生的任何人身傷害或財產損失承擔責任。
                    """)

                    sectionTitle("5. 信譽與評價系統")
                    sectionBody("""
                    5.1 用戶可在完成約球後進行互評，評價應客觀真實。\n\
                    5.2 惡意差評、報復性評價將被系統過濾並可能影響評價者自身信譽。\n\
                    5.3 信譽積分根據出勤率、評價、活躍度等綜合計算。\n\
                    5.4 本應用保留對信譽系統進行調整的權利。
                    """)
                }

                Group {
                    sectionTitle("6. 知識產權")
                    sectionBody("""
                    6.1 本應用的所有內容（包括但不限於介面設計、圖標、文字、代碼）均受知識產權法保護。\n\
                    6.2 未經書面授權，用戶不得複製、修改或傳播本應用的任何內容。\n\
                    6.3 用戶在本應用發布的內容，授予本應用非獨佔性使用權。
                    """)

                    sectionTitle("7. 免責聲明")
                    sectionBody("""
                    7.1 本應用按「現狀」提供服務，不對服務的及時性、安全性、準確性作出保證。\n\
                    7.2 因網絡狀況、系統維護等原因造成的服務中斷，本應用不承擔責任。\n\
                    7.3 用戶通過本應用約球而參加運動時，應注意自身安全，本應用不對運動傷害負責。\n\
                    7.4 本應用不對用戶間私下達成的任何協議或交易承擔擔保責任。
                    """)

                    sectionTitle("8. 條款修改")
                    sectionBody("""
                    8.1 本應用保留隨時修改服務條款的權利。\n\
                    8.2 條款修改後，繼續使用本應用即表示您接受修改後的條款。\n\
                    8.3 重大條款變更將通過應用內通知提前告知用戶。
                    """)

                    sectionTitle("9. 適用法律與爭議解決")
                    sectionBody("""
                    9.1 本條款受中華人民共和國香港特別行政區法律管轄。\n\
                    9.2 因本條款引起的任何爭議，雙方應友好協商解決；協商不成的，提交有管轄權的法院裁定。
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
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("服務條款")
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
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Theme.textPrimary)
            .padding(.top, Spacing.xs)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(Theme.textBody)
            .lineSpacing(4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TermsView()
    }
}
