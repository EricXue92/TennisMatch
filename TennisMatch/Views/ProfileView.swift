//
//  ProfileView.swift
//  TennisMatch
//
//  個人檔案頁面
//

import SwiftUI

struct ProfileView: View {
    @Environment(FollowStore.self) private var followStore
    @Environment(UserStore.self) private var userStore
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showTournaments = false
    @State private var showAchievements = false
    @State private var showFollowing = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    recordCard
                    tournamentCard
                    achievementCard
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, 100)
            }
        }
        .background(Theme.background)
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showAchievements) {
            AchievementsView()
        }
        .navigationDestination(isPresented: $showFollowing) {
            FollowingView()
        }
        .fullScreenCover(isPresented: $showTournaments) {
            TournamentView()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Safe-area inset handles status-bar offset; keep a small
            // breathing pad so the avatar doesn't hug the status bar.
            Spacer().frame(height: 12)

            // Top row: avatar + info + settings
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                    Text(userStore.avatarInitial)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.primary)
                }

                // Name + tags + bio
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(userStore.displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text(userStore.genderSymbol)
                            .font(.system(size: 18))
                            .foregroundColor(userStore.gender == .male ? Theme.genderMale : Theme.genderFemale)
                    }

                    HStack(spacing: 6) {
                        headerPill(userStore.gender.displayName)
                        headerPill(userStore.region)
                        Text("理想球友")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.goldText)
                            .padding(.horizontal, Spacing.xs)
                            .frame(height: 20)
                            .background(Theme.goldBg)
                            .clipShape(Capsule())
                    }

                    Text(userStore.bio)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Settings button
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, Spacing.md)

            // Follow stats + edit button
            HStack {
                HStack(spacing: Spacing.md) {
                    Button { showFollowing = true } label: {
                        followStat(count: "\(followStore.followingCount)", label: "關注")
                    }
                    followStat(count: "\(followStore.followerCount)", label: "粉絲")
                    followStat(count: "\(followStore.mutualCount)", label: "互相關注")
                }

                Spacer()

                NavigationLink {
                    EditProfileView()
                } label: {
                    Text("編輯資料")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .frame(height: 32)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.white.opacity(0.6), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            // Stat cards
            HStack(spacing: Spacing.xs) {
                statCard(value: userStore.ntrpText, label: "NTRP")
                statCard(value: "85", label: "信譽積分")
                statCard(value: "92%", label: "出席率")
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
        }
        .background(
            // Only the header's green backing bleeds into the safe area,
            // so the status bar sits over brand color but the scroll
            // content stays within safe area.
            Theme.primary
                .ignoresSafeArea(edges: .top)
        )
    }

    private func headerPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xs)
            .frame(height: 20)
            .background(.white.opacity(0.2))
            .clipShape(Capsule())
    }

    private func followStat(count: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(count)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Record Card

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("🎾 記錄")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            recordRow(label: "總場次", value: "28")
            recordRow(label: "本月場次", value: "5")
            recordRow(label: "常去球場", value: "維多利亞公園")
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    private func recordRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.textCaption)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)
        }
    }

    // MARK: - Tournament Card

    private var tournamentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("🏆 賽事記錄")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showTournaments = true
                } label: {
                    Text("全部")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.primary)
                }
            }

            ForEach(mockTournamentRecords) { record in
                tournamentRow(record)
                if record.id != mockTournamentRecords.last?.id {
                    Theme.divider.frame(height: 1)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    private func tournamentRow(_ record: TournamentRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(record.round)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(record.isChampion ? Theme.goldText : Theme.primary)
                    .padding(.horizontal, Spacing.xs)
                    .frame(height: 22)
                    .background(record.isChampion ? Theme.goldBg : Theme.primaryLight)
                    .clipShape(Capsule())
            }

            HStack(spacing: Spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                    Text(record.date)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textCaption)
                }
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                    Text(record.draw)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textCaption)
                }
            }

            if !record.scores.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(record.scores, id: \.self) { score in
                        Text(score)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, Spacing.xs)
                            .frame(height: 24)
                            .background(Theme.inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    Spacer()
                    Text(record.result)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(record.isWin ? Theme.primary : Theme.requiredText)
                }
            }
        }
    }

    // MARK: - Achievement Card

    private var achievementCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("🏅 成就")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showAchievements = true
                } label: {
                    Text("全部")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.primary)
                }
            }

            HStack(spacing: 0) {
                achievementBadge(icon: "🏆", label: "新手上路", unlocked: true)
                achievementBadge(icon: "⚡", label: "活躍球手", unlocked: true)
                achievementBadge(icon: "✨", label: "守時達人", unlocked: true)
                achievementBadge(icon: "🎯", label: "高手之路", unlocked: false)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    private func achievementBadge(icon: String, label: String, unlocked: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(unlocked ? Theme.primaryLight : Theme.surfaceMuted)
                    .frame(width: 44, height: 44)
                Text(icon)
                    .font(.system(size: 20))
                    .opacity(unlocked ? 1 : 0.4)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.textBody)
                .opacity(unlocked ? 1 : 0.4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tournament Data

private struct TournamentRecord: Identifiable {
    let id = UUID()
    let name: String
    let date: String
    let draw: String      // e.g. "16 簽"
    let round: String     // e.g. "4 強", "冠軍"
    let scores: [String]  // e.g. ["6-4", "6-3"]
    let result: String    // "勝" or "負"
    let isWin: Bool
    let isChampion: Bool
}

private let mockTournamentRecords: [TournamentRecord] = [
    TournamentRecord(
        name: "維多利亞公園春季盃",
        date: "2026/03",
        draw: "16 簽",
        round: "冠軍",
        scores: ["6-4", "6-3"],
        result: "勝",
        isWin: true,
        isChampion: true
    ),
    TournamentRecord(
        name: "港島區業餘聯賽",
        date: "2026/02",
        draw: "32 簽",
        round: "8 強",
        scores: ["4-6", "6-7"],
        result: "負",
        isWin: false,
        isChampion: false
    ),
    TournamentRecord(
        name: "九龍城社區邀請賽",
        date: "2025/12",
        draw: "8 簽",
        round: "4 強",
        scores: ["6-2", "3-6", "6-4"],
        result: "勝",
        isWin: true,
        isChampion: false
    ),
    TournamentRecord(
        name: "沙田區秋季友誼賽",
        date: "2025/10",
        draw: "16 簽",
        round: "冠軍",
        scores: ["6-1", "6-4"],
        result: "勝",
        isWin: true,
        isChampion: true
    ),
    TournamentRecord(
        name: "香港業餘網球巡迴賽",
        date: "2025/08",
        draw: "32 簽",
        round: "16 強",
        scores: ["3-6", "6-4", "4-6"],
        result: "負",
        isWin: false,
        isChampion: false
    ),
    TournamentRecord(
        name: "將軍澳夏季公開賽",
        date: "2025/06",
        draw: "16 簽",
        round: "亞軍",
        scores: ["6-7", "6-3", "3-6"],
        result: "負",
        isWin: false,
        isChampion: false
    ),
]

// MARK: - Preview

#Preview("iPhone SE") {
    ProfileView()
        .environment(FollowStore())
        .environment(UserStore())
}

#Preview("iPhone 15 Pro") {
    ProfileView()
        .environment(FollowStore())
        .environment(UserStore())
}
