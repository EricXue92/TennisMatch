//
//  FollowerListView.swift
//  TennisMatch
//
//  粉絲 — 關注我的球友列表
//

import SwiftUI

struct FollowerListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FollowStore.self) private var followStore
    @State private var selectedPlayer: PublicPlayerData?

    var body: some View {
        VStack(spacing: 0) {
            if mockFollowers.isEmpty {
                ContentUnavailableView(
                    "還沒有粉絲",
                    systemImage: "person.2.slash",
                    description: Text("關注你的球友會顯示在這裡")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.sm) {
                        ForEach(mockFollowers) { follower in
                            followerRow(follower)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                }
            }
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
                Text("粉絲")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .navigationDestination(item: $selectedPlayer) { player in
            PublicProfileView(player: player)
        }
    }

    private func followerRow(_ follower: FollowerPlayer) -> some View {
        let isMutual = followStore.isFollowing(follower.name)

        return HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 48, height: 48)
                Text(String(follower.name.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(follower.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(follower.gender.symbol)
                        .font(Typography.fieldValue)
                        .foregroundColor(follower.gender == .female ? Theme.genderFemale : Theme.genderMale)
                }
                Text("NTRP \(follower.ntrp) · \(follower.latestActivity)")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button {
                withAnimation { followStore.toggle(follower.name) }
            } label: {
                Text(isMutual ? "互相關注" : "關注")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isMutual ? Theme.textBody : .white)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 30)
                    .background(isMutual ? .clear : Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        if isMutual {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.inputBorder, lineWidth: 1)
                        }
                    }
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(Spacing.md)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPlayer = PublicPlayerData(
                name: follower.name,
                gender: follower.gender,
                ntrp: follower.ntrp,
                reputation: 85,
                matchCount: 15,
                bio: "熱愛網球",
                recentMatches: [
                    "04/23 10:00 - 12:00 單打 · 維多利亞公園",
                    "04/26 14:00 - 16:00 雙打 · 跑馬地",
                ],
                preferredCourts: ["維多利亞公園", "跑馬地"],
                preferredTimes: ["週末上午", "工作日晚間"],
                matchTypes: ["單打", "雙打"],
                ageRange: "26-35"
            )
        }
    }
}

// MARK: - Data

private struct FollowerPlayer: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let ntrp: String
    let latestActivity: String
}

/// 18 位粉絲:前 12 位同時出現在 seedFollowing(互相關注),後 6 位為單向粉絲。
private let mockFollowers: [FollowerPlayer] = [
    FollowerPlayer(name: "莎莎", gender: .female, ntrp: "3.5", latestActivity: "剛發布了一場單打約球"),
    FollowerPlayer(name: "王強", gender: .male, ntrp: "4.0", latestActivity: "報名了春季公開賽"),
    FollowerPlayer(name: "小美", gender: .female, ntrp: "3.0", latestActivity: "3 天前活躍"),
    FollowerPlayer(name: "志明", gender: .male, ntrp: "4.5", latestActivity: "1 週前活躍"),
    FollowerPlayer(name: "大衛", gender: .male, ntrp: "4.0", latestActivity: "剛完成了一場雙打"),
    FollowerPlayer(name: "嘉欣", gender: .female, ntrp: "3.5", latestActivity: "發布了九龍區雙打約球"),
    FollowerPlayer(name: "陳教練", gender: .male, ntrp: "5.5", latestActivity: "分享了一篇訓練心得"),
    FollowerPlayer(name: "艾美", gender: .female, ntrp: "3.0", latestActivity: "報名了階梯挑戰賽"),
    FollowerPlayer(name: "Michael", gender: .male, ntrp: "5.0", latestActivity: "2 天前活躍"),
    FollowerPlayer(name: "思慧", gender: .female, ntrp: "4.0", latestActivity: "獲得了「守時達人」成就"),
    FollowerPlayer(name: "俊傑", gender: .male, ntrp: "4.0", latestActivity: "5 天前活躍"),
    FollowerPlayer(name: "曉彤", gender: .female, ntrp: "2.5", latestActivity: "剛加入了平台"),
    FollowerPlayer(name: "阿豪", gender: .male, ntrp: "3.5", latestActivity: "報名了雙打約球"),
    FollowerPlayer(name: "麗莎", gender: .female, ntrp: "3.0", latestActivity: "1 天前活躍"),
    FollowerPlayer(name: "張偉", gender: .male, ntrp: "4.5", latestActivity: "3 天前活躍"),
    FollowerPlayer(name: "小琳", gender: .female, ntrp: "3.0", latestActivity: "剛發布了一場約球"),
    FollowerPlayer(name: "阿杰", gender: .male, ntrp: "3.5", latestActivity: "報名了九龍區友誼賽"),
    FollowerPlayer(name: "雅婷", gender: .female, ntrp: "4.0", latestActivity: "2 天前活躍"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        FollowerListView()
    }
    .environment(FollowStore())
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        FollowerListView()
    }
    .environment(FollowStore())
}
