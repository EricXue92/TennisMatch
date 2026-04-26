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
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.primary)
                    .frame(width: 22, height: 22)
                    .background(Theme.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text("為你推薦")
                    .font(Typography.labelSemibold)
                    .foregroundColor(Theme.textPrimary)
                Text("水平相近的球友")
                    .font(Typography.small)
                    .foregroundColor(Theme.textCaption)
                Spacer()
            }
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
        .background(Theme.surface)
    }

    // MARK: - 單張推薦卡片

    private func recommendCard(name: String, gender: Gender, ntrp: String) -> some View {
        HStack(spacing: Spacing.sm) {
            // 漸層環頭像 — 性別主導色,女粉 / 男藍 / 全綠
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gender == .female
                                ? [Theme.genderFemale.opacity(0.85), Theme.primary]
                                : [Theme.genderMale.opacity(0.85), Theme.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 38, height: 38)
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 34, height: 34)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 3) {
                    Text(name)
                        .font(Typography.captionMedium)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(gender.symbol)
                        .font(Typography.caption)
                        .foregroundColor(gender == .female ? Theme.genderFemale : Theme.genderMale)
                }

                // NTRP 改成 chip 樣式,提升可讀性
                Text("NTRP \(ntrp)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.primaryLight)
                    .clipShape(Capsule())

                let isFollowing = followStore.isFollowing(name)
                Button {
                    followStore.toggle(name)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: isFollowing ? "checkmark" : "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(isFollowing ? LocalizedStringKey("已關注") : LocalizedStringKey("關注"))
                            .font(Typography.micro)
                    }
                    .foregroundColor(isFollowing ? Theme.primary : .white)
                    .frame(width: 64, height: 24)
                    .background(isFollowing ? Theme.primaryLight : Theme.primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isFollowing ? Theme.primary.opacity(0.4) : .clear, lineWidth: 1)
                    )
                }
            }
        }
        .frame(width: 174, alignment: .leading)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.inputBorder, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPlayer = mockPublicPlayerData(name: name, gender: gender, ntrp: ntrp)
        }
    }
}
