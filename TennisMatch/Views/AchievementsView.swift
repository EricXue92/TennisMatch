//
//  AchievementsView.swift
//  TennisMatch
//
//  成就徽章
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBadge: Achievement?

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
                            .onTapGesture { selectedBadge = badge }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Theme.background)
        .sheet(item: $selectedBadge) { badge in
            badgeDetailSheet(badge)
                .presentationDetents([.medium])
        }
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
                    .fill(badge.unlocked ? Theme.primaryLight : Theme.surfaceMuted)
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

    // MARK: - Badge Detail Sheet

    private func badgeDetailSheet(_ badge: Achievement) -> some View {
        VStack(spacing: Spacing.md) {
            Spacer().frame(height: Spacing.md)

            // 大圖示
            ZStack {
                Circle()
                    .fill(badge.unlocked ? Theme.primaryLight : Theme.surfaceMuted)
                    .frame(width: 96, height: 96)
                Text(badge.icon)
                    .font(.system(size: 48))
                    .opacity(badge.unlocked ? 1 : 0.4)
            }

            // 名稱
            Text(badge.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            // 說明
            Text(badge.description)
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            // 狀態標籤
            Text(badge.unlocked ? "已解鎖" : "未解鎖")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(badge.unlocked ? Theme.primary : Theme.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(badge.unlocked ? Theme.primaryLight : Theme.surfaceMuted)
                )

            Spacer()

            // 關閉按鈕
            Button {
                selectedBadge = nil
            } label: {
                Text("關閉")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }
}

// MARK: - Data

private struct Achievement: Identifiable, Hashable {
    let id = UUID()

    // Hashable 基於內容而非 UUID，確保同一 badge 可正確比對
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.icon == rhs.icon && lhs.name == rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(icon)
        hasher.combine(name)
    }
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
