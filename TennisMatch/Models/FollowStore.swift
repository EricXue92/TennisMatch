//
//  FollowStore.swift
//  TennisMatch
//
//  全局 关注 / 粉丝 / 互相关注 状态
//
//  Mock 阶段用球员名字(String)作 key;接真实后端时换成 UUID。
//

import Foundation
import UIKit
import Observation

@Observable
@MainActor
final class FollowStore {
    /// 当前用户关注的球员名字集合。
    var following: Set<String>

    /// 粉絲數 = mockAllFollowers 中的人數（mock 階段固定）
    var followerCount: Int { mockAllFollowers.count }

    /// 互關數 = 同時在 following 和 mockAllFollowers 名單中的人
    var mutualCount: Int {
        mockAllFollowers.filter { following.contains($0.name) }.count
    }

    var followingCount: Int { following.count }

    init(following: Set<String> = FollowStore.seedFollowing) {
        self.following = following
    }

    func isFollowing(_ name: String) -> Bool {
        following.contains(name)
    }

    /// 當前用戶的互關球友（mockMutualFollowPlayers 與已關注集合的交集）。
    var mutualFollows: [FollowPlayer] {
        mockMutualFollowPlayers.filter { isFollowing($0.name) }
    }

    func toggle(_ name: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if following.contains(name) {
            following.remove(name)
        } else {
            following.insert(name)
        }
    }

    func unfollow(_ name: String) {
        following.remove(name)
    }

    /// 种子数据与 FollowingView 的 mock 列表对齐,确保首次打开看到 12 位已关注球友。
    /// `nonisolated` 让它能用作 init 的 default argument(default-arg 表达式
    /// 在 caller context 计算,而 FollowStore 是 `@MainActor`)。
    nonisolated private static let seedFollowing: Set<String> = [
        "莎莎", "王強", "小美", "志明", "大衛", "嘉欣",
        "陳教練", "艾美", "Michael", "思慧", "俊傑", "曉彤",
    ]
}
