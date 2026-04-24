//
//  InvitePickerSheet.swift
//  TennisMatch
//
//  邀請球友加入約球 / 賽事 — 從互關好友中挑選對象。
//  管理約球 / 管理賽事 兩個入口共用。
//

import SwiftUI

/// 邀請目標 — 約球或賽事。Identifiable 讓 .sheet(item:) 能驅動呈現。
enum InviteTarget: Identifiable {
    case match(id: UUID, title: String, dateLabel: String, timeRange: String, location: String, players: String)
    case tournament(id: UUID, name: String, dateRange: String, location: String, matchType: String, format: String)

    var id: UUID {
        switch self {
        case .match(let id, _, _, _, _, _): return id
        case .tournament(let id, _, _, _, _, _): return id
        }
    }

    /// 用於 ChatDetailView 的 matchContext 字串 — 渲染邀請卡片。
    var chatContext: String {
        switch self {
        case .match(_, let title, let dateLabel, let timeRange, let location, let players):
            return "🎾 邀請你加入我的約球\n\(title)\n\(dateLabel) \(timeRange)\n📍 \(location)\n👥 \(players)"
        case .tournament(_, let name, let dateRange, let location, let matchType, let format):
            return "🏆 邀請你參加我的賽事\n\(name)\n📅 \(dateRange)\n📍 \(location)\n🎾 \(matchType) · \(format)"
        }
    }

    var titleText: String {
        switch self {
        case .match: return "邀請球友加入約球"
        case .tournament: return "邀請球友加入賽事"
        }
    }
}

struct InvitePickerSheet: View {
    let target: InviteTarget
    let onPick: (FollowPlayer) -> Void

    @Environment(FollowStore.self) private var followStore
    @Environment(\.dismiss) private var dismiss

    private var mutualFollows: [FollowPlayer] {
        mockMutualFollowPlayers.filter { followStore.isFollowing($0.name) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if mutualFollows.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(mutualFollows) { player in
                            Button {
                                onPick(player)
                                dismiss()
                            } label: {
                                playerRow(player)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(target.titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暫無互關好友",
            systemImage: "person.2",
            description: Text("互相關注後才能邀請對方")
        )
    }

    private func playerRow(_ player: FollowPlayer) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.avatarPlaceholder)
                    .frame(width: 40, height: 40)
                Text(String(player.name.suffix(1)))
                    .font(Typography.labelSemibold)
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(player.name)
                        .font(Typography.bodyMedium)
                        .foregroundColor(Theme.textPrimary)
                    Text(player.gender.symbol)
                        .font(Typography.small)
                        .foregroundColor(player.gender == .female ? Theme.genderFemale : Theme.genderMale)
                }
                Text("NTRP \(player.ntrp) · \(player.latestActivity)")
                    .font(Typography.small)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "paperplane.fill")
                .foregroundColor(Theme.primary)
        }
        .padding(.vertical, Spacing.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}
