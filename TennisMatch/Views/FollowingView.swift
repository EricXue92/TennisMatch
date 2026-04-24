//
//  FollowingView.swift
//  TennisMatch
//
//  關注 — 已關注球友列表
//

import SwiftUI

struct FollowingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FollowStore.self) private var followStore
    @State private var playerToUnfollow: FollowPlayer?
    @State private var showUnfollowAlert = false
    @State private var selectedPlayer: PublicPlayerData?

    private var followedPlayers: [FollowPlayer] {
        followStore.mutualFollows
    }

    var body: some View {
        VStack(spacing: 0) {
            if followedPlayers.isEmpty {
                ContentUnavailableView(
                    "還沒有關注的球友",
                    systemImage: "person.2.slash",
                    description: Text("關注喜歡的球友後，會顯示在這裡")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.sm) {
                        ForEach(followedPlayers) { player in
                            playerRow(player)
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
                Text("關注")
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
                Text("確定要取消關注「\(p.name)」嗎？")
            }
        }
    }

    private func playerRow(_ player: FollowPlayer) -> some View {
        FollowPlayerRow(
            player: player,
            buttonLabel: "已關注",
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
        FollowingView()
    }
    .environment(FollowStore())
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        FollowingView()
    }
    .environment(FollowStore())
}
