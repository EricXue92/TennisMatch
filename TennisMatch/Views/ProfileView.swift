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
    @Environment(CreditScoreStore.self) private var creditScoreStore
    @Environment(RatingFeedbackStore.self) private var ratingFeedbackStore
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showTournaments = false
    @State private var showAchievements = false
    @State private var showFollowing = false
    @State private var showFollowers = false
    @State private var showMutual = false
    @State private var showCreditHistory = false
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
        .navigationDestination(isPresented: $showFollowers) {
            FollowerListView()
        }
        .navigationDestination(isPresented: $showMutual) {
            MutualFollowListView()
        }
        .fullScreenCover(isPresented: $showTournaments) {
            TournamentView()
        }
        .sheet(isPresented: $showCreditHistory) {
            CreditScoreHistoryView(
                currentScore: creditScoreStore.score,
                entries: creditScoreStore.entries
            )
        }
    }

    // MARK: - 統計計算（mock 階段用信譽記錄推算，接後端後替換）

    /// 總場次：從信譽記錄中統計「完成約球」條目數
    private var totalMatches: Int {
        creditScoreStore.entries.filter { $0.reason == "完成約球" }.count
    }

    /// 本月場次：統計當月的「完成約球」條目數
    private var monthlyMatches: Int {
        let calendar = Calendar.current
        let now = Date()
        return creditScoreStore.entries.filter { entry in
            guard entry.reason == "完成約球" else { return false }
            // 從 "MM/dd" 格式解析月份
            guard let entryDate = AppDateFormatter.monthDay.date(from: entry.date) else { return false }
            let entryMonth = calendar.component(.month, from: entryDate)
            let currentMonth = calendar.component(.month, from: now)
            return entryMonth == currentMonth
        }.count
    }

    /// 出席率：以信譽積分推算（爽約會扣分，積分高則出席率高）
    /// 公式：min(100, score) / 100，轉換為百分比字串
    private var attendanceRate: String {
        let rate = min(100, max(0, creditScoreStore.score))
        return "\(rate)%"
    }

    /// 是否顯示「理想球友」金色標籤：信譽積分 ≥ 85 且至少完成 5 場約球
    private var showIdealBadge: Bool {
        creditScoreStore.score >= 85 && totalMatches >= 5
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
                    if let data = userStore.avatarImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    } else {
                        Text(userStore.avatarInitial)
                            .font(Typography.title)
                            .foregroundColor(Theme.primary)
                    }
                }

                // Name + tags + bio
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(userStore.displayName)
                            .font(Typography.largeStat)
                            .foregroundColor(.white)
                        Text(userStore.genderSymbol)
                            .font(.system(size: 18))
                            .foregroundColor(userStore.gender == .male ? Theme.genderMale : Theme.genderFemale)
                    }

                    HStack(spacing: 6) {
                        headerPill(userStore.gender.displayName)
                        headerPill(userStore.region)
                        // 只有信譽積分 ≥ 85 且完成場次 ≥ 5 才顯示金色勳章
                        if showIdealBadge {
                            Text("理想球友")
                                .font(Typography.micro)
                                .foregroundColor(Theme.goldText)
                                .padding(.horizontal, Spacing.xs)
                                .frame(height: 20)
                                .background(Theme.goldBg)
                                .clipShape(Capsule())
                        }
                    }

                    Text(userStore.bio)
                        .font(Typography.caption)
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
                        followStat(count: "\(followStore.followingCount)", label: "關注中")
                    }
                    Button { showFollowers = true } label: {
                        followStat(count: "\(followStore.followerCount)", label: "粉絲")
                    }
                    Button { showMutual = true } label: {
                        followStat(count: "\(followStore.mutualCount)", label: "互相關注")
                    }
                }

                Spacer()

                NavigationLink {
                    EditProfileView()
                } label: {
                    Text("編輯資料")
                        .font(Typography.micro)
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
                Button {
                    showCreditHistory = true
                } label: {
                    statCard(value: "\(creditScoreStore.score)", label: "信譽積分")
                }
                .buttonStyle(.plain)
                statCard(value: attendanceRate, label: "出席率")
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
            .font(Typography.micro)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xs)
            .frame(height: 20)
            .background(.white.opacity(0.2))
            .clipShape(Capsule())
    }

    private func followStat(count: String, label: LocalizedStringKey) -> some View {
        HStack(spacing: 3) {
            Text(count)
                .font(Typography.labelSemibold)
                .foregroundColor(.white)
            Text(label)
                .font(Typography.small)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private func statCard(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Typography.largeStat)
                .foregroundColor(.white)
            Text(label)
                .font(Typography.micro)
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
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)

            recordRow(label: "總場次", value: "\(totalMatches)")
            recordRow(label: "本月場次", value: "\(monthlyMatches)")
            recordRow(
                label: "偏好球場",
                value: userStore.selectedCourts.isEmpty
                    ? "未設定"
                    : userStore.selectedCourts.map(\.name).joined(separator: "、")
            )
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    private func recordRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.small)
                .foregroundColor(Theme.textCaption)
            Spacer()
            Text(LocalizedStringKey(value))
                .font(Typography.smallMedium)
                .foregroundColor(Theme.textPrimary)
        }
    }

    // MARK: - Tournament Card

    private var tournamentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("🏆 賽事記錄")
                    .font(Typography.labelSemibold)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showTournaments = true
                } label: {
                    Text("全部")
                        .font(Typography.small)
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
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    private func tournamentRow(_ record: TournamentRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.name)
                    .font(Typography.captionMedium)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(LocalizedStringKey(record.round))
                    .font(Typography.micro)
                    .foregroundColor(record.isChampion ? Theme.goldText : Theme.primary)
                    .padding(.horizontal, Spacing.xs)
                    .frame(height: 22)
                    .background(record.isChampion ? Theme.goldBg : Theme.primaryLight)
                    .clipShape(Capsule())
            }

            HStack(spacing: Spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(Typography.micro)
                        .foregroundColor(Theme.textSecondary)
                    Text(record.date)
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textCaption)
                }
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(Typography.micro)
                        .foregroundColor(Theme.textSecondary)
                    Text(record.draw)
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textCaption)
                }
            }

            if !record.scores.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(record.scores, id: \.self) { score in
                        Text(score)
                            .font(Typography.smallMedium)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, Spacing.xs)
                            .frame(height: 24)
                            .background(Theme.inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    Spacer()
                    Text(LocalizedStringKey(record.result))
                        .font(Typography.micro)
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
                    .font(Typography.labelSemibold)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showAchievements = true
                } label: {
                    Text("全部")
                        .font(Typography.small)
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
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    private func achievementBadge(icon: String, label: LocalizedStringKey, unlocked: Bool) -> some View {
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
                .font(Typography.micro)
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
        .environment(CreditScoreStore())
        .environment(RatingFeedbackStore())
}

#Preview("iPhone 15 Pro") {
    ProfileView()
        .environment(FollowStore())
        .environment(UserStore())
        .environment(CreditScoreStore())
        .environment(RatingFeedbackStore())
}
