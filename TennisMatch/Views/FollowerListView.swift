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
    @State private var playerToUnfollow: FollowPlayer?
    @State private var showUnfollowAlert = false

    var body: some View {
        VStack(spacing: 0) {
            if mockAllFollowers.isEmpty {
                ContentUnavailableView(
                    "還沒有粉絲",
                    systemImage: "person.2.slash",
                    description: Text("關注你的球友會顯示在這裡")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.sm) {
                        ForEach(mockAllFollowers) { follower in
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
                        .font(Typography.buttonMedium)
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("粉絲")
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
                    withAnimation { followStore.unfollow(p.name) }
                }
                playerToUnfollow = nil
            }
        } message: {
            if let p = playerToUnfollow {
                Text("確定要取消關注「\(p.name)」嗎？")
            }
        }
    }

    private func followerRow(_ follower: FollowPlayer) -> some View {
        let isMutual = followStore.isFollowing(follower.name)

        return FollowPlayerRow(
            player: follower,
            buttonLabel: isMutual ? "互相關注" : "關注",
            isOutlineStyle: isMutual,
            onButtonTap: {
                if isMutual {
                    playerToUnfollow = follower
                    showUnfollowAlert = true
                } else {
                    withAnimation { followStore.toggle(follower.name) }
                }
            },
            onRowTap: {
                selectedPlayer = mockPublicPlayerData(name: follower.name, gender: follower.gender, ntrp: follower.ntrp)
            }
        )
    }
}

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
