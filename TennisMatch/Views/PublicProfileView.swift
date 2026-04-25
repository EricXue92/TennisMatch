//
//  PublicProfileView.swift
//  TennisMatch
//
//  球友公開主頁 — 只讀版個人資料
//

import SwiftUI

struct PublicProfileView: View {
    let player: PublicPlayerData
    @Environment(\.dismiss) private var dismiss
    @Environment(FollowStore.self) private var followStore
    @State private var showBlockAlert = false
    @State private var selectedChat: MockChat?

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    statsCard
                    playerInfoCard
                    matchHistoryCard
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, 100)
            }

            bottomBar
        }
        .background(Theme.background)
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.buttonMedium)
                        .foregroundColor(.white)
                }
            }
        }
        .alert("封鎖用戶", isPresented: $showBlockAlert) {
            Button("取消", role: .cancel) {}
            Button("確認封鎖", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("封鎖「\(player.name)」後，對方將無法查看你的資料和約球，也無法向你發送私信。")
        }
        // 點擊「私信」按鈕後，導航到私信聊天頁面
        .navigationDestination(item: $selectedChat) { chat in
            ChatDetailView(chat: chat)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 80)

            HStack(alignment: .top, spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                    Text(String(player.name.prefix(1)))
                        .font(Typography.title)
                        .foregroundColor(Theme.primary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(player.name)
                            .font(Typography.largeStat)
                            .foregroundColor(.white)
                        Text(player.gender.symbol)
                            .font(.system(size: 18))
                            .foregroundColor(player.gender == .female ? Theme.genderFemale : Theme.genderMale)
                    }

                    Text("NTRP \(player.ntrp) · 信譽分 \(player.reputation)")
                        .font(Typography.caption)
                        .foregroundColor(.white.opacity(0.85))

                    Text(player.bio)
                        .font(Typography.caption)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)

            // Follow + block row
            HStack {
                Button {
                    withAnimation { followStore.toggle(player.name) }
                } label: {
                    let following = followStore.isFollowing(player.name)
                    Text(following ? "已關注" : "關注")
                        .font(Typography.captionMedium)
                        .foregroundColor(following ? Theme.textBody : .white)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 32)
                        .background(following ? .white : .white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.white.opacity(0.6), lineWidth: 1)
                        )
                }

                Button {
                    showBlockAlert = true
                } label: {
                    Image(systemName: "nosign")
                        .font(Typography.bodyMedium)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
        }
        .background(Theme.primary)
    }

    // MARK: - Stats

    private var statsCard: some View {
        HStack(spacing: Spacing.xs) {
            statItem(value: player.ntrp, label: "NTRP")
            statItem(value: "\(player.reputation)", label: "信譽積分")
            statItem(value: "\(player.matchCount)", label: "場次")
        }
        .padding(.vertical, Spacing.sm)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Typography.largeStat)
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(Typography.micro)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    // MARK: - Player Info

    private var playerInfoCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("📋 球友資料")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)

            if !player.matchTypes.isEmpty {
                infoRow(icon: "figure.tennis", label: "比賽類型", value: player.matchTypes.joined(separator: " / "))
            }

            if !player.ageRange.isEmpty {
                infoRow(icon: "person.fill", label: "年齡段", value: player.ageRange)
            }

            if !player.preferredCourts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(Typography.small)
                            .foregroundColor(Theme.primary)
                            .frame(width: 18)
                        Text("常去球場")
                            .font(Typography.captionMedium)
                            .foregroundColor(Theme.textSecondary)
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(player.preferredCourts, id: \.self) { court in
                            Text("📍 \(court)")
                                .font(Typography.small)
                                .foregroundColor(Theme.textBody)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.chipUnselectedBg)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                    .padding(.leading, 24)
                }
            }

            if !player.preferredTimes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(Typography.small)
                            .foregroundColor(Theme.primary)
                            .frame(width: 18)
                        Text("偏好時間")
                            .font(Typography.captionMedium)
                            .foregroundColor(Theme.textSecondary)
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(player.preferredTimes, id: \.self) { time in
                            Text(time)
                                .font(Typography.small)
                                .foregroundColor(Theme.textBody)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.chipUnselectedBg)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                    .padding(.leading, 24)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(Typography.small)
                .foregroundColor(Theme.primary)
                .frame(width: 18)
            Text(label)
                .font(Typography.captionMedium)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(Typography.caption)
                .foregroundColor(Theme.textBody)
        }
    }

    // MARK: - Match History

    private var matchHistoryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("🎾 約球記錄")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)

            ForEach(player.recentMatches, id: \.self) { match in
                HStack(spacing: Spacing.sm) {
                    Text("📅")
                        .font(Typography.small)
                    Text(match)
                        .font(Typography.caption)
                        .foregroundColor(Theme.textBody)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        Button {
            selectedChat = MockChat(
                type: .personal(name: player.name, symbol: player.gender.symbol, symbolColor: player.gender == .female ? Theme.genderFemale : Theme.genderMale),
                lastMessage: "點擊開始聊天",
                time: "now",
                unreadCount: 0
            )
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "bubble.left.fill")
                    .font(Typography.bodyMedium)
                Text("私信")
                    .font(Typography.button)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xl)
        .background(
            Rectangle()
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.06), radius: 4, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Data

struct PublicPlayerData: Hashable {
    let name: String
    let gender: Gender
    let ntrp: String
    let reputation: Int
    let matchCount: Int
    let bio: String
    let recentMatches: [String]
    var preferredCourts: [String] = []
    var preferredTimes: [String] = []
    var matchTypes: [String] = []
    var ageRange: String = ""
}

// MARK: - Mock Data Helper

/// 根據名稱查找 Mock 球友資料，確保同一球友在不同頁面資料一致。
func mockPublicPlayerData(name: String, gender: Gender, ntrp: String) -> PublicPlayerData {
    // 用名字的 hashValue 生成穩定但看起來不同的數值
    let nameHash = abs(name.hashValue)
    let reputation = 75 + (nameHash % 20)  // 75-94
    let matchCount = 10 + (nameHash % 25)   // 10-34

    let bios: [String] = [
        "熱愛網球，週末經常打球",
        "喜歡打網球，歡迎切磋",
        "網球愛好者，球齡3年",
        "享受比賽的樂趣",
        "業餘選手，持續進步中",
    ]
    let bio = bios[nameHash % bios.count]

    let courtSets: [[String]] = [
        ["維多利亞公園", "跑馬地"],
        ["九龍仔公園", "歌和老街公園"],
        ["沙田公園", "將軍澳運動場"],
        ["維多利亞公園", "香港網球中心"],
    ]
    let courts = courtSets[nameHash % courtSets.count]

    let timeSets: [[String]] = [
        ["週末上午", "工作日晚間"],
        ["週末下午", "工作日傍晚"],
        ["週末全天", "平日晚間"],
    ]
    let times = timeSets[nameHash % timeSets.count]

    return PublicPlayerData(
        name: name,
        gender: gender,
        ntrp: ntrp,
        reputation: reputation,
        matchCount: matchCount,
        bio: bio,
        recentMatches: [
            "04/23 10:00 - 12:00 單打 · \(courts[0])",
            "04/26 15:00 - 17:00 雙打 · \(courts.count > 1 ? courts[1] : courts[0])",
        ],
        preferredCourts: courts,
        preferredTimes: times,
        matchTypes: ["單打", "雙打"],
        ageRange: "26-35"
    )
}

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        PublicProfileView(player: previewPlayer)
    }
    .environment(FollowStore())
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        PublicProfileView(player: previewPlayer)
    }
    .environment(FollowStore())
}

private let previewPlayer = PublicPlayerData(
    name: "莎拉", gender: .female, ntrp: "3.5", reputation: 90, matchCount: 28,
    bio: "週末固定在維多利亞公園打球",
    recentMatches: [
        "04/23 10:00 - 12:00 單打 · 維多利亞公園",
        "04/15 14:00 - 16:00 雙打 · 跑馬地",
        "04/10 09:00 - 11:00 單打 · 九龍仔公園",
    ],
    preferredCourts: ["維多利亞公園", "九龍仔公園"],
    preferredTimes: ["週末上午", "工作日晚間"],
    matchTypes: ["單打", "雙打"],
    ageRange: "26-35"
)
