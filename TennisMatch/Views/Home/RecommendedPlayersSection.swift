//
//  RecommendedPlayersSection.swift
//  TennisMatch
//
//  推薦球友橫向滾動區塊，從 HomeView 抽出以減少檔案大小
//

import SwiftUI

struct RecommendedPlayersSection: View {
    @Environment(FollowStore.self) private var followStore
    @Binding var selectedPlayer: PublicPlayerData?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("📈 推薦")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    recommendCard(name: "莎拉",  gender: .female, ntrp: "3.5")
                    recommendCard(name: "王強",  gender: .male,   ntrp: "4.0")
                    recommendCard(name: "小美",  gender: .female, ntrp: "3.0")
                    recommendCard(name: "志明",  gender: .male,   ntrp: "4.5")
                    recommendCard(name: "嘉欣",  gender: .female, ntrp: "3.5")
                    recommendCard(name: "大衛",  gender: .male,   ntrp: "4.0")
                    recommendCard(name: "艾美",  gender: .female, ntrp: "3.0")
                    recommendCard(name: "阿豪",  gender: .male,   ntrp: "3.5")
                    recommendCard(name: "思慧",  gender: .female, ntrp: "4.0")
                    recommendCard(name: "Michael", gender: .male, ntrp: "5.0")
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .padding(.vertical, Spacing.sm)
        .background(.white)
    }

    // MARK: - 單張推薦卡片

    private func recommendCard(name: String, gender: Gender, ntrp: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Theme.avatarPlaceholder)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(gender.symbol)
                        .font(Typography.caption)
                        .foregroundColor(gender == .female ? Theme.genderFemale : Theme.genderMale)
                }

                Text("NTRP \(ntrp)")
                    .font(Typography.fieldLabel)
                    .foregroundColor(Theme.textCaption)

                // 關注狀態由 followStore 驅動
                let isFollowing = followStore.isFollowing(name)
                Button {
                    followStore.toggle(name)
                } label: {
                    Text(isFollowing ? "已關注" : "關注")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isFollowing ? Theme.primary : .white)
                        .frame(width: 60, height: 24)
                        .background(isFollowing ? Color.clear : Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isFollowing ? Theme.primary : Color.clear, lineWidth: 1)
                        )
                }
            }
        }
        .frame(width: 170, alignment: .leading)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.inputBorder, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // 點擊卡片導航至公開個人頁
            selectedPlayer = mockPublicPlayerData(name: name, gender: gender, ntrp: ntrp)
        }
    }
}
