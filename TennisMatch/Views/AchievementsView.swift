//
//  AchievementsView.swift
//  TennisMatch
//
//  成就徽章
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("已解鎖 · \(mockAchievements.filter(\.unlocked).count)/\(mockAchievements.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(mockAchievements) { badge in
                        achievementBadge(badge)
                    }
                }
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
                Text("成就")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func achievementBadge(_ badge: Achievement) -> some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(badge.unlocked ? Theme.primaryLight : Color(hex: 0xF3F4F6))
                    .frame(width: 56, height: 56)
                Text(badge.icon)
                    .font(.system(size: 26))
                    .opacity(badge.unlocked ? 1 : 0.4)
            }

            Text(badge.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .opacity(badge.unlocked ? 1 : 0.4)

            Text(badge.description)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .opacity(badge.unlocked ? 1 : 0.4)
        }
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(badge.unlocked ? 0.06 : 0.02), radius: 4, y: 1)
    }
}

// MARK: - Data

private struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let description: String
    let unlocked: Bool
}

private let mockAchievements: [Achievement] = [
    Achievement(icon: "🏆", name: "新手上路", description: "完成第一場約球", unlocked: true),
    Achievement(icon: "⚡", name: "活躍球手", description: "累計完成 10 場約球", unlocked: true),
    Achievement(icon: "✨", name: "守時達人", description: "連續 5 場準時到達", unlocked: true),
    Achievement(icon: "🎯", name: "高手之路", description: "NTRP 達到 4.0", unlocked: false),
    Achievement(icon: "🤝", name: "社交達人", description: "與 20 位不同球友打球", unlocked: false),
    Achievement(icon: "🏅", name: "賽事冠軍", description: "贏得一場賽事冠軍", unlocked: true),
    Achievement(icon: "🔥", name: "連勝王", description: "比賽連勝 5 場", unlocked: false),
    Achievement(icon: "💪", name: "鐵人", description: "一週打球 5 次", unlocked: false),
    Achievement(icon: "⭐", name: "五星好評", description: "累計獲得 10 個五星評價", unlocked: true),
    Achievement(icon: "🎾", name: "百場老將", description: "累計完成 100 場約球", unlocked: false),
    Achievement(icon: "📍", name: "球場探索家", description: "在 10 個不同球場打過球", unlocked: true),
    Achievement(icon: "🌟", name: "人氣球友", description: "被 50 位球友關注", unlocked: false),
    Achievement(icon: "🎖️", name: "雙打王", description: "累計完成 30 場雙打", unlocked: false),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        AchievementsView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        AchievementsView()
    }
}
