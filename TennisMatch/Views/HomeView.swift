//
//  HomeView.swift
//  TennisMatch
//
//  首頁 — 統計、推薦、約球列表、底部 Tab
//

import SwiftUI

// MARK: - Main Tab Container

struct HomeView: View {
    @State private var selectedTab = 0
    @State private var selectedFilter = "全部"

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0: homeTab
                case 1: placeholderTab("我的約球")
                case 2: placeholderTab("一鍵約球")
                case 3: placeholderTab("消息")
                case 4: placeholderTab("我的")
                default: homeTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            customTabBar
        }
    }

    private func placeholderTab(_ title: String) -> some View {
        VStack {
            Spacer()
            Text(title)
                .font(Typography.title)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "🎯", label: "首頁", tag: 0)
            tabBarItem(icon: "🗓", label: "我的約球", tag: 1)
            centerTabButton
            tabBarItem(icon: "💬", label: "消息", tag: 3, badgeCount: 2)
            tabBarItem(icon: "👤", label: "我的", tag: 4)
        }
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xl)
        .background(
            Rectangle()
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabBarItem(icon: String, label: String, tag: Int, badgeCount: Int = 0) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Text(icon)
                        .font(.system(size: 20))
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 8, y: -4)
                    }
                }
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selectedTab == tag ? Theme.primary : Theme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var centerTabButton: some View {
        Button {
            selectedTab = 2
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Theme.primary)
                        .frame(width: 52, height: 52)
                        .shadow(color: Theme.primary.opacity(0.4), radius: 6, y: 2)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(y: -16)
                Text("一鍵約球")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedTab == 2 ? Theme.primary : Theme.textSecondary)
                    .offset(y: -16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        VStack(spacing: 0) {
            headerSection
            ScrollView {
                VStack(spacing: 0) {
                    recommendationSection
                    dividerLine
                    filterChips
                    sectionHeader
                    matchCardList
                }
                .padding(.bottom, 80)
            }
        }
        .background(Theme.inputBg)
    }
}

// MARK: - Header

private extension HomeView {
    var headerSection: some View {
        ZStack(alignment: .topLeading) {
            Theme.primary.ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                // Top row: hamburger + weather
                HStack {
                    Button {
                        // TODO: open menu
                    } label: {
                        VStack(spacing: 3.5) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(.white)
                                    .frame(width: 22, height: 2)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: 6)
                        }
                    }

                    Spacer()

                    Text("☀️ 24°C")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.md)

                // Avatar row
                HStack {
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text("👤")
                                .font(.system(size: 18))
                        }
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        }
                    Spacer()
                }
                .padding(.leading, Spacing.md)
                .padding(.top, 4)

                // Stats cards
                HStack(spacing: Spacing.xs) {
                    statCard(label: "信譽積分", value: "85")
                    statCard(label: "場次", value: "28")
                    statCard(label: "NTRP", value: "3.5")
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.md)
            }
        }
        .frame(height: 160)
        .background(Theme.primary)
    }

    func statCard(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Recommendations

private extension HomeView {
    var recommendationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("📈 推薦")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    recommendCard(
                        name: "莎拉",
                        gender: .female,
                        ntrp: "3.5"
                    )
                    recommendCard(
                        name: "王強",
                        gender: .male,
                        ntrp: "4.0"
                    )
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .padding(.vertical, Spacing.sm)
        .background(.white)
    }

    func recommendCard(name: String, gender: Gender, ntrp: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color(hex: 0xE0E0E0))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(gender == .female ? "♀" : "♂")
                        .font(.system(size: 13))
                        .foregroundColor(gender == .female ? Theme.genderFemale : Theme.genderMale)
                }

                Text("NTRP \(ntrp)")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textCaption)

                Button {
                    // TODO: follow
                } label: {
                    Text("關注")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 24)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
    }
}

// MARK: - Filters

private extension HomeView {
    var dividerLine: some View {
        Theme.inputBorder.frame(height: 1)
    }

    var filterChips: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(matchFilterOptions, id: \.self) { option in
                let isSelected = option == selectedFilter
                Button {
                    selectedFilter = option
                } label: {
                    Text(option)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white : Theme.textBody)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 30)
                        .background(isSelected ? Theme.primary : .white)
                        .clipShape(Capsule())
                        .overlay {
                            if !isSelected {
                                Capsule().stroke(Theme.inputBorder, lineWidth: 1)
                            }
                        }
                }
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(.white)
    }

    var sectionHeader: some View {
        HStack {
            Text("🔍 篩選")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.sm)
                .frame(height: 28)
                .background(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 6)
        .background(Theme.inputBg)
    }
}

// MARK: - Match Cards

private extension HomeView {
    var filteredMatches: [MockMatch] {
        if selectedFilter == "全部" { return mockMatches }
        return mockMatches.filter { $0.matchType == selectedFilter }
    }

    var matchCardList: some View {
        VStack(spacing: Spacing.md) {
            ForEach(filteredMatches) { match in
                matchCard(match)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.xl)
    }

    func matchCard(_ match: MockMatch) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: avatar + name + gender + type + weather
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color(hex: 0xE0E0E0))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(match.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text(match.gender == .female ? "♀" : "♂")
                            .font(.system(size: 14))
                            .foregroundColor(match.gender == .female ? Theme.genderFemale : Theme.genderMale)

                        Text(match.matchType)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textBody)
                            .padding(.horizontal, 6)
                            .frame(height: 18)
                            .background(Theme.chipUnselectedBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }

                Spacer()

                Text(match.weather)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textCaption)
            }

            // Detail rows
            detailRow(icon: "📅", text: match.dateTime)
            detailRow(icon: "📍", text: match.location)
            detailRow(icon: "👥", text: match.players)

            // Bottom: tags + sign up button
            HStack(spacing: Spacing.xs) {
                Text(match.fee)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textBody)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 22)
                    .background(Theme.chipUnselectedBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("招募中")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 22)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                Button {
                    // TODO: sign up for match
                } label: {
                    Text("報名")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 44)
                        .background(Theme.primaryDark)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }

    func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Theme.textBody)
        }
        .padding(.leading, 52)
    }
}

private let matchFilterOptions = ["全部", "單打", "雙打", "賽事"]

// MARK: - Mock Data

private struct MockMatch: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let matchType: String
    let weather: String
    let dateTime: String
    let location: String
    let players: String
    let fee: String
}

private let mockMatches: [MockMatch] = [
    MockMatch(
        name: "莎拉", gender: .female, matchType: "單打",
        weather: "☀️ 24°C", dateTime: "04/19 10:00",
        location: "維多利亞公園網球場",
        players: "1/2 • 3.0-4.0", fee: "AA ¥120"
    ),
    MockMatch(
        name: "王強", gender: .male, matchType: "雙打",
        weather: "⛅ 26°C", dateTime: "04/20 14:00",
        location: "跑馬地遊樂場",
        players: "2/4 • 3.5-4.5", fee: "AA ¥200"
    ),
    MockMatch(
        name: "美琪", gender: .female, matchType: "單打",
        weather: "☀️ 28°C", dateTime: "04/21 08:30",
        location: "九龍仔公園",
        players: "1/2 • 3.5-4.0", fee: "AA ¥100"
    ),
    MockMatch(
        name: "志明", gender: .male, matchType: "單打",
        weather: "🌤 25°C", dateTime: "04/21 16:00",
        location: "香港網球中心",
        players: "1/2 • 4.0-4.5", fee: "AA ¥150"
    ),
    MockMatch(
        name: "小美", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "04/22 10:00",
        location: "沙田公園",
        players: "3/4 • 3.0-3.5", fee: "AA ¥80"
    ),
    MockMatch(
        name: "大衛", gender: .male, matchType: "雙打",
        weather: "⛅ 23°C", dateTime: "04/22 18:30",
        location: "歌和老街公園",
        players: "2/4 • 4.0-5.0", fee: "AA ¥180"
    ),
    MockMatch(
        name: "嘉欣", gender: .female, matchType: "單打",
        weather: "🌤 26°C", dateTime: "04/23 09:00",
        location: "香港公園",
        players: "1/2 • 2.5-3.5", fee: "AA ¥100"
    ),
    MockMatch(
        name: "俊傑", gender: .male, matchType: "雙打",
        weather: "☀️ 29°C", dateTime: "04/23 15:00",
        location: "將軍澳運動場",
        players: "1/4 • 3.5-4.5", fee: "AA ¥160"
    ),
    MockMatch(
        name: "陳教練", gender: .male, matchType: "賽事",
        weather: "☀️ 30°C", dateTime: "04/26 09:00",
        location: "維多利亞公園網球場",
        players: "12/32 • 3.5+", fee: "報名 ¥300"
    ),
    MockMatch(
        name: "港島網協", gender: .female, matchType: "賽事",
        weather: "🌤 27°C", dateTime: "05/03 08:00",
        location: "香港網球中心",
        players: "8/16 • 4.0+", fee: "報名 ¥500"
    ),
]

// MARK: - Preview

#Preview("iPhone SE") {
    HomeView()
}

#Preview("iPhone 15 Pro") {
    HomeView()
}
