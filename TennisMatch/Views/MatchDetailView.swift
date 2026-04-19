//
//  MatchDetailView.swift
//  TennisMatch
//
//  約球詳情頁
//

import SwiftUI

struct MatchDetailView: View {
    let match: MatchDetailData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    creatorCard
                    weatherCard
                    participantsCard
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, 100)
            }
            .background(Theme.inputBg)

            bottomBar
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("←")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("約球詳情")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }
}

// MARK: - Creator & Info Card

private extension MatchDetailView {
    var creatorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Creator info
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xE0E0E0))
                        .frame(width: 56, height: 56)
                    Text(String(match.name.prefix(1)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(match.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text(match.gender == .female ? "♀" : "♂")
                            .font(.system(size: 17))
                            .foregroundColor(match.gender == .female ? Theme.genderFemale : Theme.genderMale)
                    }
                    Text("NTRP \(match.ntrp) · 信譽分 \(match.reputation)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x666666))
                }

                Spacer()

                Button {
                    // TODO: follow
                } label: {
                    Text("關注")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: 0x333333))
                        .frame(width: 60, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(hex: 0xCCCCCC), lineWidth: 1)
                        }
                }
            }
            .padding(Spacing.md)

            // Divider
            Rectangle()
                .fill(Color(hex: 0xEBEBEB))
                .frame(height: 1)
                .padding(.horizontal, Spacing.md)

            // Tags
            HStack(spacing: Spacing.xs) {
                Text(match.matchType)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 24)
                    .background(Color(hex: 0x218C21))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("招募中")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0x4D4D4D))
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 24)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: 0xCCCCCC), lineWidth: 1)
                    }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            // Detail rows
            VStack(alignment: .leading, spacing: Spacing.md) {
                detailRow(icon: "📅", title: match.date, subtitle: match.timeRange)
                detailRow(icon: "📍", title: match.location, subtitle: match.district)
                detailRow(icon: "👥", title: match.players, subtitle: "水平範圍: \(match.ntrpRange)")
                detailRow(icon: "💰", title: match.fee, subtitle: nil)
            }
            .padding(Spacing.md)

            // Divider
            Rectangle()
                .fill(Color(hex: 0xEBEBEB))
                .frame(height: 1)
                .padding(.horizontal, Spacing.md)

            // Notes
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("備註")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text(match.notes)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0x666666))
            }
            .padding(Spacing.md)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func detailRow(icon: String, title: String, subtitle: String?) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(icon)
                .font(.system(size: 16))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x666666))
                }
            }
        }
    }
}

// MARK: - Weather Card

private extension MatchDetailView {
    var weatherCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("⛅ 天氣")
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 0) {
                weatherItem(value: match.weather.temp, label: nil)
                weatherItem(value: "💧 \(match.weather.humidity)", label: nil)
                weatherItem(value: "☀️ \(match.weather.uv)", label: "UV")
                weatherItem(value: "💨 \(match.weather.wind)", label: "km/h")
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func weatherItem(value: String, label: String?) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            if let label {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x808080))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Participants Card

private extension MatchDetailView {
    var participantsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("參加者")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            ForEach(match.participantList, id: \.name) { p in
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0xE0E0E0))
                            .frame(width: 36, height: 36)
                        Text(String(p.name.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(p.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                            Text(p.gender == .female ? "♀" : "♂")
                                .font(.system(size: 14))
                                .foregroundColor(p.gender == .female ? Theme.genderFemale : Theme.genderMale)
                        }
                        Text("NTRP \(p.ntrp)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x808080))
                    }

                    Spacer()

                    if p.isOrganizer {
                        Text("發起人")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: 0x666666))
                            .padding(.horizontal, Spacing.sm)
                            .frame(height: 22)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color(hex: 0xCCCCCC), lineWidth: 1)
                            }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Bottom Bar

private extension MatchDetailView {
    var bottomBar: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                // TODO: chat
            } label: {
                Text("💬 私信")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: 0x218C21))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(hex: 0x218C21), lineWidth: 1.5)
                    }
            }

            Button {
                // TODO: sign up
            } label: {
                Text("報名")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: 0x218C21))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xl)
        .background(
            Rectangle()
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 4, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Data Model

struct MatchDetailData: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let gender: Gender
    let ntrp: String
    let reputation: Int
    let matchType: String
    let date: String
    let timeRange: String
    let location: String
    let district: String
    let players: String
    let ntrpRange: String
    let fee: String
    let notes: String
    let weather: MatchWeather
    let participantList: [MatchParticipant]
}

struct MatchWeather: Hashable {
    let temp: String
    let humidity: String
    let uv: String
    let wind: String
}

struct MatchParticipant: Hashable {
    let name: String
    let gender: Gender
    let ntrp: String
    let isOrganizer: Bool
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        MatchDetailView(match: previewMatchDetail)
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        MatchDetailView(match: previewMatchDetail)
    }
}

private let previewMatchDetail = MatchDetailData(
    name: "莎拉", gender: .female, ntrp: "3.5", reputation: 90,
    matchType: "單打", date: "2026/04/19", timeRange: "10:00 - 12:00",
    location: "維多利亞公園網球場", district: "香港銅鑼灣",
    players: "1/2 人", ntrpRange: "3.0-4.0", fee: "AA ¥120",
    notes: "自帶球拍和球",
    weather: MatchWeather(temp: "24°C", humidity: "10%", uv: "7", wind: "12"),
    participantList: [
        MatchParticipant(name: "莎拉", gender: .female, ntrp: "3.5", isOrganizer: true)
    ]
)
