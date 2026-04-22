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
    @State private var showCalibrationSheet = false

    /// 用戶上次 dismiss / 接受 校準提示時的 peerAverage 快照。下一次提示
    /// 只在 peerAverage 漂移 ≥ 0.1 後才會再彈,避免頻繁打擾。
    /// `Double.nan` 作為 "尚未 dismiss 過" 的哨兵(AppStorage 不接 Optional<Double>)。
    @AppStorage("calibrationDismissedAvg") private var calibrationDismissedAvg: Double = .nan

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    if let suggestion = visibleCalibrationSuggestion {
                        calibrationBanner(suggestion)
                    }
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
        .sheet(isPresented: $showCalibrationSheet) {
            if let suggestion = ratingFeedbackStore.calibrationSuggestion(selfNTRP: userStore.ntrpLevel) {
                CalibrationSheet(
                    suggestion: suggestion,
                    selfNTRP: userStore.ntrpLevel,
                    onCalibrate: {
                        userStore.ntrpLevel = suggestion.suggested
                        calibrationDismissedAvg = suggestion.peerAverage
                        showCalibrationSheet = false
                    },
                    onKeep: {
                        calibrationDismissedAvg = suggestion.peerAverage
                        showCalibrationSheet = false
                    },
                    onLater: {
                        showCalibrationSheet = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Calibration

    /// 當前需要展示的校準建議。已被用戶 dismiss 過的(且球友均值無顯著漂移)會被過濾。
    private var visibleCalibrationSuggestion: CalibrationSuggestion? {
        guard let suggestion = ratingFeedbackStore.calibrationSuggestion(selfNTRP: userStore.ntrpLevel) else {
            return nil
        }
        // 沒 dismiss 過 → 直接顯示。
        if calibrationDismissedAvg.isNaN { return suggestion }
        // dismiss 過後,球友均值漂移 ≥ 0.1 才再次提示。
        if abs(suggestion.peerAverage - calibrationDismissedAvg) >= 0.1 {
            return suggestion
        }
        return nil
    }

    private func calibrationBanner(_ suggestion: CalibrationSuggestion) -> some View {
        Button {
            showCalibrationSheet = true
        } label: {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "scope")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.primary)
                    .frame(width: 32, height: 32)
                    .background(Theme.primaryLight)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("水平校準建議")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    Text(suggestion.bannerSubtitle(selfNTRP: userStore.ntrpLevel))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textBody)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Spacing.xs)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.primary.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
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
                Button {
                    showCreditHistory = true
                } label: {
                    statCard(value: "\(creditScoreStore.score)", label: "信譽積分")
                }
                .buttonStyle(.plain)
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

// MARK: - Calibration Sheet

private extension CalibrationSuggestion {
    /// 銀行式短描述,給 Profile 入口卡片用,字數壓在兩行內。
    func bannerSubtitle(selfNTRP: Double) -> String {
        let selfText = String(format: "%.1f", selfNTRP)
        let avgText = String(format: "%.1f", peerAverage)
        switch direction {
        case .selfUnderrated:
            return "\(sampleSize) 位球友平均評你 \(avgText)，比自評 \(selfText) 高，建議上調。"
        case .selfOverrated:
            return "\(sampleSize) 位球友平均評你 \(avgText)，比自評 \(selfText) 低，建議下調。"
        }
    }

    var directionHeadline: String {
        switch direction {
        case .selfUnderrated: return "你可能低估了自己的水平"
        case .selfOverrated:  return "你可能高估了自己的水平"
        }
    }
}

private struct CalibrationSheet: View {
    let suggestion: CalibrationSuggestion
    let selfNTRP: Double
    let onCalibrate: () -> Void
    let onKeep: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("水平校準")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(suggestion.directionHeadline)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textBody)
            }

            // 對比卡:自評 vs 球友均值
            HStack(spacing: Spacing.sm) {
                comparisonCard(
                    title: "你的自評",
                    value: String(format: "%.1f", selfNTRP),
                    accent: Theme.textBody
                )
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                comparisonCard(
                    title: "球友均值",
                    value: String(format: "%.1f", suggestion.peerAverage),
                    accent: Theme.primary
                )
            }
            .frame(maxWidth: .infinity)

            Text("基於 \(suggestion.sampleSize) 位球友賽後評估,差距已超過 \(String(format: "%.1f", RatingFeedbackStore.deviationThreshold)) 級。建議將 NTRP 調整至 \(String(format: "%.1f", suggestion.suggested)),匹配更精準。")
                .font(.system(size: 12))
                .foregroundColor(Theme.textCaption)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            VStack(spacing: Spacing.xs) {
                Button(action: onCalibrate) {
                    Text("校準到 \(String(format: "%.1f", suggestion.suggested))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                HStack(spacing: Spacing.sm) {
                    Button(action: onKeep) {
                        Text("保留 \(String(format: "%.1f", selfNTRP))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textBody)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Theme.inputBorder, lineWidth: 1)
                            )
                    }
                    Button(action: onLater) {
                        Text("稍後再說")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textBody)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Theme.inputBorder, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(Spacing.lg)
    }

    private func comparisonCard(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Theme.textCaption)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .background(Theme.inputBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

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
