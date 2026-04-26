//
//  PlayerModels.swift
//  TennisMatch
//
//  統一的球友資料模型 — 取代之前分散在 FollowingView / FollowerListView / MutualFollowListView 的三份重複定義
//

import Foundation

struct FollowPlayer: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let ntrp: String
    let latestActivity: String
}

// MARK: - Mock Data

/// 12 位互相關注的球友 — FollowingView / MutualFollowListView 共用。
/// 與 FollowStore.seedFollowing 對齊。
let mockMutualFollowPlayers: [FollowPlayer] = [
    FollowPlayer(name: "莎莎", gender: .female, ntrp: "3.5", latestActivity: "剛發布了一場單打約球"),
    FollowPlayer(name: "王強", gender: .male, ntrp: "4.0", latestActivity: "報名了春季公開賽"),
    FollowPlayer(name: "小美", gender: .female, ntrp: "3.0", latestActivity: "3 天前活躍"),
    FollowPlayer(name: "志明", gender: .male, ntrp: "4.5", latestActivity: "1 週前活躍"),
    FollowPlayer(name: "大衛", gender: .male, ntrp: "4.0", latestActivity: "剛完成了一場雙打"),
    FollowPlayer(name: "嘉欣", gender: .female, ntrp: "3.5", latestActivity: "發布了九龍區雙打約球"),
    FollowPlayer(name: "陳教練", gender: .male, ntrp: "5.5", latestActivity: "分享了一篇訓練心得"),
    FollowPlayer(name: "艾美", gender: .female, ntrp: "3.0", latestActivity: "報名了階梯挑戰賽"),
    FollowPlayer(name: "Michael", gender: .male, ntrp: "5.0", latestActivity: "2 天前活躍"),
    FollowPlayer(name: "思慧", gender: .female, ntrp: "4.0", latestActivity: "獲得了「守時達人」成就"),
    FollowPlayer(name: "俊傑", gender: .male, ntrp: "4.0", latestActivity: "5 天前活躍"),
    FollowPlayer(name: "曉彤", gender: .female, ntrp: "2.5", latestActivity: "剛加入了平台"),
]

/// 額外 6 位單向粉絲 — 僅 FollowerListView 使用。
let mockFollowerOnlyPlayers: [FollowPlayer] = [
    FollowPlayer(name: "阿豪", gender: .male, ntrp: "3.5", latestActivity: "報名了雙打約球"),
    FollowPlayer(name: "麗莎", gender: .female, ntrp: "3.0", latestActivity: "1 天前活躍"),
    FollowPlayer(name: "張偉", gender: .male, ntrp: "4.5", latestActivity: "3 天前活躍"),
    FollowPlayer(name: "小琳", gender: .female, ntrp: "3.0", latestActivity: "剛發布了一場約球"),
    FollowPlayer(name: "阿杰", gender: .male, ntrp: "3.5", latestActivity: "報名了九龍區友誼賽"),
    FollowPlayer(name: "雅婷", gender: .female, ntrp: "4.0", latestActivity: "2 天前活躍"),
]

/// 完整粉絲列表 = 互關 + 單向粉絲
let mockAllFollowers: [FollowPlayer] = mockMutualFollowPlayers + mockFollowerOnlyPlayers

extension FollowPlayer {
    static func from(invite: InviteStore.Invite) -> FollowPlayer {
        FollowPlayer(
            name: invite.inviteeName,
            gender: invite.inviteeGender,
            ntrp: invite.inviteeNTRP,
            latestActivity: ""
        )
    }
}
