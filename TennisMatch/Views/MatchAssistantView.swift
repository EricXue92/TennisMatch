//
//  MatchAssistantView.swift
//  TennisMatch
//
//  約球助理 — 智能推薦匹配的約球
//

import SwiftUI

struct MatchAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore
    @State private var selectedDetail: MatchDetailData?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Intro card
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Theme.primaryLight)
                            .frame(width: 44, height: 44)
                        Text("🤖")
                            .font(.system(size: 22))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("約球助理")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("根據你的 NTRP \(userStore.ntrpText)、常去球場和空閒時間為你推薦")
                            .font(Typography.small)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("為你推薦")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                ForEach(mockRecommendations) { rec in
                    recommendedCard(rec)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Theme.background)
        .navigationDestination(item: $selectedDetail) { detail in
            MatchDetailView(
                match: detail,
                acceptedMatches: .constant([]),
                signedUpMatchIDs: .constant([])
            )
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
                Text("約球助理")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func recommendedCard(_ rec: RecommendedMatch) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Theme.avatarPlaceholder)
                        .frame(width: 40, height: 40)
                    Text(String(rec.name.prefix(1)))
                        .font(Typography.button)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(rec.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text(rec.gender.symbol)
                            .font(.system(size: 14))
                            .foregroundColor(rec.gender == .female ? Theme.genderFemale : Theme.genderMale)
                        Text(rec.matchType)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textBody)
                            .padding(.horizontal, 6)
                            .frame(height: 18)
                            .background(Theme.chipUnselectedBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    Text("NTRP \(rec.ntrp)")
                        .font(Typography.fieldLabel)
                        .foregroundColor(Theme.textCaption)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("匹配度")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(rec.matchScore)%")
                        .font(Typography.button)
                        .foregroundColor(Theme.primary)
                }
            }

            HStack(spacing: Spacing.xs) {
                Text("📅 \(rec.dateTimeDisplay)")
                Text("📍 \(rec.location)")
            }
            .font(Typography.small)
            .foregroundColor(Theme.textBody)
            .padding(.leading, 52)

            HStack(spacing: Spacing.xs) {
                Text(rec.reason)
                    .font(Typography.fieldLabel)
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 22)
                    .background(Theme.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                Button {
                    selectedDetail = rec.toMatchDetailData()
                } label: {
                    Text("查看")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 30)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.leading, 52)
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }
}

// MARK: - Data

private struct RecommendedMatch: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let ntrp: String
    let matchType: String
    let dateTime: String
    let location: String
    let matchScore: Int
    let reason: String

    /// 显示用的完整时段字符串,如 "04/19 10:00 - 12:00"。
    var dateTimeDisplay: String {
        let parts = dateTime.components(separatedBy: " ")
        guard parts.count >= 2 else { return dateTime }
        let dateStr = parts[0]
        let startTime = parts[1]
        let startHour = Int(startTime.prefix(2)) ?? 10
        // 防止結束時間超過 24:00（隔天 00:00）
        let endHour = min(startHour + 2, 24)
        let endTime = endHour == 24 ? "00:00(隔天)" : String(format: "%02d:00", endHour)
        return "\(dateStr) \(startTime) - \(endTime)"
    }

    /// 转换为 MatchDetailData 以导航到详情页
    func toMatchDetailData() -> MatchDetailData {
        let parts = dateTime.components(separatedBy: " ")
        let dateStr = parts.first ?? dateTime
        let timeStr = parts.count > 1 ? parts[1] : "10:00"
        // 防止結束時間超過 24:00（隔天 00:00）
        let endHour = min((Int(timeStr.prefix(2)) ?? 10) + 2, 24)
        let timeRange = endHour == 24 ? "\(timeStr) - 00:00(隔天)" : "\(timeStr) - \(String(format: "%02d:00", endHour))"
        return MatchDetailData(
            name: name,
            gender: gender,
            ntrp: ntrp,
            reputation: 85,
            matchType: matchType,
            date: "2026/\(dateStr)",
            timeRange: timeRange,
            location: "\(location)網球場",
            district: "香港",
            players: "1/2 人",
            ntrpRange: "\(ntrp)",
            fee: "AA",
            notes: "",
            weather: MatchWeather(temp: "--°C", humidity: "--%", uv: "--", wind: "--"),
            participantList: [
                MatchParticipant(name: name, gender: gender, ntrp: ntrp, isOrganizer: true)
            ]
        )
    }
}

private let mockRecommendations: [RecommendedMatch] = [
    RecommendedMatch(name: "莎拉", gender: .female, ntrp: "3.5", matchType: "單打", dateTime: "04/23 10:00", location: "維多利亞公園", matchScore: 95, reason: "NTRP 完全匹配"),
    RecommendedMatch(name: "美琪", gender: .female, ntrp: "3.5", matchType: "單打", dateTime: "04/25 08:30", location: "九龍仔公園", matchScore: 88, reason: "常去球場"),
    RecommendedMatch(name: "小美", gender: .female, ntrp: "3.0", matchType: "雙打", dateTime: "04/26 10:00", location: "沙田公園", matchScore: 82, reason: "時間吻合"),
    RecommendedMatch(name: "俊傑", gender: .male, ntrp: "4.0", matchType: "雙打", dateTime: "04/28 15:00", location: "將軍澳運動場", matchScore: 75, reason: "水平接近"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        MatchAssistantView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        MatchAssistantView()
    }
}
