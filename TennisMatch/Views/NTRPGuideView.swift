//
//  NTRPGuideView.swift
//  TennisMatch
//
//  NTRP 技術分級標準頁面
//

import SwiftUI

struct NTRPGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("🎾 網球 NTRP 技術分級標準（精簡版）")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textDark)

                Text("根據您的實際水平選擇對應的 NTRP 等級")
                    .font(Typography.small)
                    .foregroundColor(Theme.textHint)

                ForEach(ntrpLevels) { level in
                    NTRPCard(level: level)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
        }
        .background(Theme.inputBg)
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
                Text("NTRP 技術分級標準")
                    .font(Typography.navTitle)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.accentGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Card

private struct NTRPCard: View {
    let level: NTRPLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(level.range)  \(level.name)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.accentGreen)

            Text(level.englishName)
                .font(Typography.fieldLabel)
                .foregroundColor(Theme.textHint)

            Theme.inputBorder
                .frame(height: 1)

            ForEach(level.descriptions, id: \.self) { text in
                Text(text)
                    .font(Typography.small)
                    .foregroundColor(Theme.textDark)
            }

            if !level.skills.isEmpty {
                Text("技術重點：")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textMedium)

                ForEach(level.skills, id: \.self) { skill in
                    Text("· \(skill)")
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textHint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

// MARK: - Data Model

private struct NTRPLevel: Identifiable {
    let id = UUID()
    let range: String
    let name: String
    let englishName: String
    let descriptions: [String]
    let skills: [String]
}

private let ntrpLevels: [NTRPLevel] = [
    NTRPLevel(
        range: "1.5 – 2.0",
        name: "純初學者",
        englishName: "The Novice",
        descriptions: [
            "1.5：剛開始打球。目標是能擊中球，並學習場地的基本界線。",
            "2.0：能進行慢速的簡短拉球。熟悉單雙打的基本站位。"
        ],
        skills: [
            "正手：正在嘗試建立穩定的揮拍動作。",
            "反手：盡量回避反手，握拍姿勢常有錯誤。",
            "發球：能發球入場，但雙誤非常頻繁。"
        ]
    ),
    NTRPLevel(
        range: "2.5 – 3.0",
        name: "進階初學者",
        englishName: "Intermediate Beginner",
        descriptions: [
            "2.5：能判斷來球方向，但跑動仍較生硬。能與同水平球友進行短距離拉球。",
            "3.0：業餘比賽的起點。擊球動作趨於穩定，能以中速控制球的方向。"
        ],
        skills: [
            "網前：在網前感到舒適，能完成基礎的截擊。",
            "戰術：理解基本的雙打站位（一前一後）。"
        ]
    ),
    NTRPLevel(
        range: "3.5 – 4.0",
        name: "競技中級",
        englishName: "Competitive Intermediate",
        descriptions: [
            "3.5：中速球的穩定性與方向感提升。開始成功運用挑高球、高壓球和隨球上網。",
            "4.0：擊球可靠，正反手均能控制落點的深度與方向。"
        ],
        skills: [
            "發球：能運用力量和旋轉，二發開始具有壓迫性。",
            "拉球：能在底線穩定對攻，開始有意識地「組織」進攻。"
        ]
    ),
    NTRPLevel(
        range: "4.5 – 5.0",
        name: "高級玩家",
        englishName: "The Advanced Player",
        descriptions: [
            "4.5：開始掌握力量與旋轉。能處理快球，步法扎實，能控制回球深度。",
            "5.0：預判能力強。擁有可以作為「殺手鐧」的招牌動作，並以此構建戰術體系。"
        ],
        skills: [
            "戰術：能根據對手改變策略。面對淺球能直接打出制勝分或逼對方失誤。"
        ]
    ),
    NTRPLevel(
        range: "5.5 – 7.0",
        name: "精英/職業級",
        englishName: "Elite / Professional",
        descriptions: [
            "5.5：具備極高的穩定性，能打出具有力量和變化的「重球」。",
            "6.0+：經過長期高強度訓練，通常為國家級比賽選手或職業巡迴賽球員。"
        ],
        skills: []
    )
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        NTRPGuideView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        NTRPGuideView()
    }
}
