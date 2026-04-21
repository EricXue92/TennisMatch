//
//  UserStore.swift
//  TennisMatch
//
//  当前登录用户的基本档案。
//
//  用途:昵称 / 性别 / NTRP / 简介 / 地区 等跨页面共享,
//  EditProfileView 写入,Profile / Chat / HomeView 等读取。
//  Mock 阶段常驻内存即可;接后端时换成仓储层。
//

import Foundation
import Observation

@Observable
final class UserStore {
    /// 显示名(如 "小李")。
    var displayName: String

    /// 性别。
    var gender: Gender

    /// 个人简介(一句话)。
    var bio: String

    /// NTRP 等级(0.5 步进,范围 1.0-7.0)。
    var ntrpLevel: Double

    /// 所在地区。
    var region: String

    init(
        displayName: String = "小李",
        gender: Gender = .male,
        bio: String = "熱愛網球，週末經常打球",
        ntrpLevel: Double = 3.5,
        region: String = "香港"
    ) {
        self.displayName = displayName
        self.gender = gender
        self.bio = bio
        self.ntrpLevel = ntrpLevel
        self.region = region
    }

    /// 头像显示用的单字缩写,取 displayName 末位字符。
    /// 对 "小李" → "李";"Michael" → "l"(英文用户可进一步定制)。
    var avatarInitial: String {
        String(displayName.suffix(1))
    }

    /// NTRP 的字符串显示形式(如 "3.5")。
    var ntrpText: String {
        String(format: "%.1f", ntrpLevel)
    }

    /// 性别符号:用于 Profile / 卡片上的 ♂ / ♀ 展示。
    var genderSymbol: String {
        switch gender {
        case .male:   return "♂"
        case .female: return "♀"
        }
    }
}
