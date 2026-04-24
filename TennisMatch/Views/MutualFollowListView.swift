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
    @State private var playerToUnfollow: FollowPlayer?
    @State private var showUnfollowAlert = false
    @State private var selectedPlayer: PublicPlayerData?

    /// 只顯示仍在 followStore.following 中的互關球友。
    private var activeMutuals: [FollowPlayer] {
        followStore.mutualFollows
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
                        .font(Typography.buttonMedium)
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("互相關注")
                    .font(Typography.sectionTitle)
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

    private func mutualRow(_ player: FollowPlayer) -> some View {
        FollowPlayerRow(
            player: player,
            buttonLabel: "互相關注",
            isOutlineStyle: true,
            onButtonTap: {
                playerToUnfollow = player
                showUnfollowAlert = true
            },
            onRowTap: {
                selectedPlayer = mockPublicPlayerData(name: player.name, gender: player.gender, ntrp: player.ntrp)
            }
        )
    }
}

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
