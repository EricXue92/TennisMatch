//
//  MutualFollowListView.swift
//  TennisMatch
//
//  互相關注 — 互相關注的球友列表
//

import SwiftUI

struct MutualFollowListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FollowStore.self) private var followStore
    @State private var playerToUnfollow: MutualPlayer?
    @State private var showUnfollowAlert = false
    @State private var selectedPlayer: PublicPlayerData?

    /// 只顯示仍在 followStore.following 中的互關球友。
    private var activeMutuals: [MutualPlayer] {
        mockMutualPlayers.filter { followStore.isFollowing($0.name) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if activeMutuals.isEmpty {
                ContentUnavailableView(
                    "還沒有互相關注的球友",
                    systemImage: "person.2.slash",
                    description: Text("互相關注的球友會顯示在這裡")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.sm) {
                        ForEach(activeMutuals) { player in
                            mutualRow(player)
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
                Text("互相關注")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .navigationDestination(item: $selectedPlayer) { player in
            PublicProfileView(player: player)
        }
        .alert("取消關注", isPresented: $showUnfollowAlert) {
            Button("取消", role: .cancel) { playerToUnfollow = nil }
            Button("確認", role: .destructive) {
                if let p = playerToUnfollow {
                    withAnimation {
                        followStore.unfollow(p.name)
                    }
                }
                playerToUnfollow = nil
            }
        } message: {
            if let p = playerToUnfollow {
                Text("確定要取消關注「\(p.name)」嗎？取消後將從互相關注中移除。")
            }
        }
    }

    private func mutualRow(_ player: MutualPlayer) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 48, height: 48)
                Text(String(player.name.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(player.gender.symbol)
                        .font(Typography.fieldValue)
                        .foregroundColor(player.gender == .female ? Theme.genderFemale : Theme.genderMale)
                }
                Text("NTRP \(player.ntrp) · \(player.latestActivity)")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button {
                playerToUnfollow = player
                showUnfollowAlert = true
            } label: {
                Text("互相關注")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textBody)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 30)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.inputBorder, lineWidth: 1)
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
                name: player.name,
                gender: player.gender,
                ntrp: player.ntrp,
                reputation: 88,
                matchCount: 20,
                bio: "熱愛網球",
                recentMatches: ["04/19 單打 · 維多利亞公園"]
            )
        }
    }
}

// MARK: - Data

private struct MutualPlayer: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let ntrp: String
    let latestActivity: String
}

/// 12 位互相關注球友,與 FollowStore.seedFollowing 對齊。
private let mockMutualPlayers: [MutualPlayer] = [
    MutualPlayer(name: "莎莎", gender: .female, ntrp: "3.5", latestActivity: "剛發布了一場單打約球"),
    MutualPlayer(name: "王強", gender: .male, ntrp: "4.0", latestActivity: "報名了春季公開賽"),
    MutualPlayer(name: "小美", gender: .female, ntrp: "3.0", latestActivity: "3 天前活躍"),
    MutualPlayer(name: "志明", gender: .male, ntrp: "4.5", latestActivity: "1 週前活躍"),
    MutualPlayer(name: "大衛", gender: .male, ntrp: "4.0", latestActivity: "剛完成了一場雙打"),
    MutualPlayer(name: "嘉欣", gender: .female, ntrp: "3.5", latestActivity: "發布了九龍區雙打約球"),
    MutualPlayer(name: "陳教練", gender: .male, ntrp: "5.5", latestActivity: "分享了一篇訓練心得"),
    MutualPlayer(name: "艾美", gender: .female, ntrp: "3.0", latestActivity: "報名了階梯挑戰賽"),
    MutualPlayer(name: "Michael", gender: .male, ntrp: "5.0", latestActivity: "2 天前活躍"),
    MutualPlayer(name: "思慧", gender: .female, ntrp: "4.0", latestActivity: "獲得了「守時達人」成就"),
    MutualPlayer(name: "俊傑", gender: .male, ntrp: "4.0", latestActivity: "5 天前活躍"),
    MutualPlayer(name: "曉彤", gender: .female, ntrp: "2.5", latestActivity: "剛加入了平台"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        MutualFollowListView()
    }
    .environment(FollowStore())
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        MutualFollowListView()
    }
    .environment(FollowStore())
}
