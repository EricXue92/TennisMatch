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
@MainActor
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

    /// 年齡範圍(自選的桶,值域與 `MockMatch.ageRange` 對齊)。
    /// 編輯資料時跟著名字、性別等個人身份字段一起寫回;發起的約球渲染卡片時會
    /// 從這裡實時讀取(via `MockMatch.isOwnMatch` fallback)。
    var ageRange: String

    /// 偏好球場（多選，最多 3 個，按 `allCourts` 顺序保存以便稳定显示）。
    var selectedCourts: [TennisCourt]

    /// 球友水平偏好範圍。
    var partnerLevelLow: Double

    /// 球友水平偏好範圍上限。
    var partnerLevelHigh: Double

    /// 偏好時段。
    var preferredSlots: [PreferredTimeSlot]

    init(
        displayName: String = "小李",
        gender: Gender = .male,
        bio: String = "熱愛網球，週末經常打球",
        ntrpLevel: Double = 3.5,
        region: String = "香港",
        ageRange: String = "26-35",
        selectedCourts: [TennisCourt] = [],
        partnerLevelLow: Double = 3.0,
        partnerLevelHigh: Double = 4.5,
        preferredSlots: [PreferredTimeSlot] = []
    ) {
        self.displayName = displayName
        self.gender = gender
        self.bio = bio
        self.ntrpLevel = ntrpLevel
        self.region = region
        self.ageRange = ageRange
        self.selectedCourts = selectedCourts
        self.partnerLevelLow = partnerLevelLow
        self.partnerLevelHigh = partnerLevelHigh
        self.preferredSlots = preferredSlots
    }

    // MARK: - 年齡範圍選項

    /// 年齡範圍可選桶 — 與 `MockMatch.ageRange` 對齊,確保發布的約球能命中首頁
    /// 「年齡」篩選器。改變桶時要同步調整 `MatchFilterPanelView` 的選項。
    static let ageRangeOptions: [String] = [
        "14-17", "18-25", "26-35", "36-45", "46-55", "55+",
    ]

    // MARK: - 名称唯一性检查

    /// Mock 阶段已被其他用户占用的名称。接后端时改为查询 API。
    static let reservedNames: Set<String> = [
        "莎拉", "王強", "美琪", "志明", "小美", "大衛", "嘉欣", "俊傑",
        "阿杰", "麗莎", "老張", "小玲", "林叔", "Kelly", "Peter",
        "陳教練", "雅婷", "阿豪", "思慧", "張偉", "詠琪", "Michael",
        "艾美", "家明", "曉彤", "國輝", "Tommy",
    ]

    /// 检查名称是否已被其他用户占用。
    /// `excludingCurrent` 为 true 时排除当前用户自己的名称(编辑场景)。
    func isNameTaken(_ name: String, excludingCurrent: Bool = false) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if excludingCurrent && trimmed == displayName { return false }
        return UserStore.reservedNames.contains(trimmed)
    }

    // MARK: - 显示用属性

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
