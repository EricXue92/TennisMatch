//
//  FollowingView.swift
//  TennisMatch
//
//  關注 — 已關注球友列表
//

import SwiftUI

struct FollowingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var followedPlayers: [FollowedPlayer] = mockFollowedPlayers
    @State private var playerToUnfollow: FollowedPlayer?
    @State private var showUnfollowAlert = false
    @State private var selectedPlayer: PublicPlayerData?

    var body: some View {
        VStack(spacing: 0) {
            if followedPlayers.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Spacer()
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textSecondary)
                    Text("還沒有關注的球友")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("關注")
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
                        followedPlayers.removeAll { $0.id == p.id }
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

    private func playerRow(_ player: FollowedPlayer) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xE0E0E0))
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
                    Text(player.gender == .female ? "♀" : "♂")
                        .font(.system(size: 15))
                        .foregroundColor(player.gender == .female ? Theme.genderFemale : Theme.genderMale)
                }
                Text("NTRP \(player.ntrp) · \(player.latestActivity)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button {
                playerToUnfollow = player
                showUnfollowAlert = true
            } label: {
                Text("已關注")
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

private struct FollowedPlayer: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let ntrp: String
    let latestActivity: String
}

private let mockFollowedPlayers: [FollowedPlayer] = [
    FollowedPlayer(name: "莎莎", gender: .female, ntrp: "3.5", latestActivity: "剛發布了一場單打約球"),
    FollowedPlayer(name: "王強", gender: .male, ntrp: "4.0", latestActivity: "報名了春季公開賽"),
    FollowedPlayer(name: "小美", gender: .female, ntrp: "3.0", latestActivity: "3 天前活躍"),
    FollowedPlayer(name: "志明", gender: .male, ntrp: "4.5", latestActivity: "1 週前活躍"),
]

// MARK: - Preview

#Preview("iPhone SE") {
    NavigationStack {
        FollowingView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        FollowingView()
    }
}
