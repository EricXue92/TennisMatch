//
//  MockMatchData.swift
//  TennisMatch
//
//  Mock 約球數據 — 從 HomeView 抽取，供首頁列表使用

import Foundation

// MARK: - Filter Options

let matchFilterOptions = ["全部", "單打", "雙打", "拉球"]

// MARK: - Mock Data Model

struct MockMatch: Identifiable {
    let id = UUID()
    let name: String
    let gender: Gender
    let matchType: String
    let weather: String
    let dateTime: String
    let location: String
    let fee: String
    // Structured filter fields
    let ntrpLow: Double
    let ntrpHigh: Double
    let ageRange: String    // e.g. "18-25"
    let genderLabel: String // "男" or "女"
    let hour: Int           // 7-23
    let dayOfWeek: String   // "一"-"日"
    // Player count
    var currentPlayers: Int
    var maxPlayers: Int
    var isOwnMatch: Bool = false

    var players: String {
        "\(currentPlayers)/\(maxPlayers) • \(String(format: "%.1f-%.1f", ntrpLow, ntrpHigh))"
    }

    var isFull: Bool { currentPlayers >= maxPlayers }

    /// 起始时间已过(根据 `dateTime` 中的 MM/dd HH:mm,与当前年组合)。
    /// 解析失败时返回 `false`,避免误把数据当成过期。
    var isExpired: Bool { MatchSchedule.isExpired(text: dateTime, hourFallback: hour) }

    /// 起始时间已过且未满员 — 视为"人员不足,自动取消"(CLAUDE.md 边界 case #2)。
    /// 即使用户已报名,该约球实际未进行,UI 应优先展示"已自動取消"覆盖"已報名"。
    var isAutoCancelled: Bool { isExpired && !isFull }

    /// 用于首页按时间排序 — 最近的时间在最上面。
    var sortDate: Date {
        MatchSchedule.startDate(text: dateTime, hourFallback: hour) ?? .distantFuture
    }

    /// 显示用的完整时段字符串,如 "04/23 09:00 - 11:00"。
    var dateTimeDisplay: String {
        let parts = dateTime.split(separator: " ")
        guard parts.count >= 2 else { return dateTime }
        let dateStr = String(parts[0])
        let startTime = String(parts[1])
        let startHour = Int(startTime.prefix(2)) ?? hour
        let endHour = startHour + 2
        let endTime = String(format: "%02d:00", endHour)
        return "\(dateStr) \(startTime) - \(endTime)"
    }
}

// MARK: - Mock Match Data

let initialMockMatches: [MockMatch] = [
    MockMatch(
        name: "莎拉", gender: .female, matchType: "單打",
        weather: "☀️ 24°C", dateTime: "04/23 10:00",
        location: "維多利亞公園網球場", fee: "AA ¥120",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "王強", gender: .male, matchType: "雙打",
        weather: "⛅ 26°C", dateTime: "04/24 14:00",
        location: "跑馬地遊樂場", fee: "AA ¥200",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 14, dayOfWeek: "四",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "小李", gender: .male, matchType: "雙打",
        weather: "⛅ 26°C", dateTime: "04/25 14:00",
        location: "跑馬地遊樂場", fee: "AA ¥200",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 14, dayOfWeek: "五",
        currentPlayers: 2, maxPlayers: 4,
        isOwnMatch: true
    ),
    MockMatch(
        name: "美琪", gender: .female, matchType: "單打",
        weather: "☀️ 28°C", dateTime: "04/25 08:30",
        location: "九龍仔公園", fee: "AA ¥100",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "18-25",
        genderLabel: "女", hour: 8, dayOfWeek: "五",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "志明", gender: .male, matchType: "單打",
        weather: "🌤 25°C", dateTime: "04/25 16:00",
        location: "香港網球中心", fee: "AA ¥150",
        ntrpLow: 4.0, ntrpHigh: 4.5, ageRange: "36-45",
        genderLabel: "男", hour: 16, dayOfWeek: "五",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "小美", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "04/22 10:00",
        location: "沙田公園", fee: "AA ¥80",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "18-25",
        genderLabel: "女", hour: 10, dayOfWeek: "二",
        currentPlayers: 3, maxPlayers: 4
    ),
    MockMatch(
        name: "大衛", gender: .male, matchType: "雙打",
        weather: "⛅ 23°C", dateTime: "04/22 18:30",
        location: "歌和老街公園", fee: "AA ¥180",
        ntrpLow: 4.0, ntrpHigh: 5.0, ageRange: "26-35",
        genderLabel: "男", hour: 18, dayOfWeek: "二",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "嘉欣", gender: .female, matchType: "單打",
        weather: "🌤 26°C", dateTime: "04/23 09:00",
        location: "香港公園", fee: "AA ¥100",
        ntrpLow: 2.5, ntrpHigh: 3.5, ageRange: "18-25",
        genderLabel: "女", hour: 9, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "俊傑", gender: .male, matchType: "雙打",
        weather: "☀️ 29°C", dateTime: "04/23 15:00",
        location: "將軍澳運動場", fee: "AA ¥160",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 15, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 4
    ),
    MockMatch(
        name: "阿杰", gender: .male, matchType: "單打",
        weather: "☀️ 25°C", dateTime: "04/23 07:00",
        location: "沙田公園", fee: "AA ¥60",
        ntrpLow: 2.0, ntrpHigh: 3.0, ageRange: "18-25",
        genderLabel: "男", hour: 7, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "麗莎", gender: .female, matchType: "雙打",
        weather: "⛅ 26°C", dateTime: "04/24 19:00",
        location: "香港網球中心", fee: "AA ¥250",
        ntrpLow: 4.5, ntrpHigh: 5.5, ageRange: "26-35",
        genderLabel: "女", hour: 19, dayOfWeek: "四",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "老張", gender: .male, matchType: "單打",
        weather: "🌤 22°C", dateTime: "04/24 07:00",
        location: "九龍仔公園", fee: "AA ¥200",
        ntrpLow: 5.0, ntrpHigh: 6.0, ageRange: "46-55",
        genderLabel: "男", hour: 7, dayOfWeek: "四",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "小玲", gender: .female, matchType: "單打",
        weather: "☀️ 28°C", dateTime: "04/25 17:30",
        location: "將軍澳運動場", fee: "AA ¥70",
        ntrpLow: 2.0, ntrpHigh: 2.5, ageRange: "18-25",
        genderLabel: "女", hour: 17, dayOfWeek: "五",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "林叔", gender: .male, matchType: "雙打",
        weather: "⛅ 24°C", dateTime: "04/26 15:00",
        location: "維多利亞公園網球場", fee: "AA ¥120",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "55+",
        genderLabel: "男", hour: 15, dayOfWeek: "六",
        currentPlayers: 3, maxPlayers: 4
    ),
    MockMatch(
        name: "Kelly", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "04/27 10:30",
        location: "沙田公園", fee: "AA ¥100",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: "日",
        currentPlayers: 1, maxPlayers: 4
    ),
    MockMatch(
        name: "Peter", gender: .male, matchType: "單打",
        weather: "☀️ 30°C", dateTime: "04/28 20:00",
        location: "跑馬地遊樂場", fee: "AA ¥180",
        ntrpLow: 4.5, ntrpHigh: 5.0, ageRange: "36-45",
        genderLabel: "男", hour: 20, dayOfWeek: "一",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "陳教練", gender: .male, matchType: "單打",
        weather: "🌤 23°C", dateTime: "04/29 07:30",
        location: "香港網球中心", fee: "AA ¥300",
        ntrpLow: 5.0, ntrpHigh: 6.0, ageRange: "36-45",
        genderLabel: "男", hour: 7, dayOfWeek: "二",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "雅婷", gender: .female, matchType: "雙打",
        weather: "☀️ 26°C", dateTime: "04/29 17:00",
        location: "九龍公園", fee: "AA ¥90",
        ntrpLow: 2.5, ntrpHigh: 3.0, ageRange: "18-25",
        genderLabel: "女", hour: 17, dayOfWeek: "二",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "阿豪", gender: .male, matchType: "雙打",
        weather: "⛅ 25°C", dateTime: "04/30 19:30",
        location: "歌和老街公園", fee: "AA ¥150",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "男", hour: 19, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 4
    ),
    MockMatch(
        name: "思慧", gender: .female, matchType: "單打",
        weather: "☀️ 29°C", dateTime: "04/30 09:00",
        location: "將軍澳運動場", fee: "AA ¥80",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "26-35",
        genderLabel: "女", hour: 9, dayOfWeek: "三",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "張偉", gender: .male, matchType: "單打",
        weather: "🌤 24°C", dateTime: "05/01 08:00",
        location: "維多利亞公園網球場", fee: "AA ¥120",
        ntrpLow: 4.0, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 8, dayOfWeek: "四",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "詠琪", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "05/01 15:30",
        location: "沙田公園", fee: "AA ¥100",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "18-25",
        genderLabel: "女", hour: 15, dayOfWeek: "四",
        currentPlayers: 3, maxPlayers: 4
    ),
    MockMatch(
        name: "Michael", gender: .male, matchType: "單打",
        weather: "⛅ 22°C", dateTime: "05/02 18:00",
        location: "跑馬地遊樂場", fee: "AA ¥200",
        ntrpLow: 4.5, ntrpHigh: 5.5, ageRange: "36-45",
        genderLabel: "男", hour: 18, dayOfWeek: "五",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "艾美", gender: .female, matchType: "雙打",
        weather: "☀️ 28°C", dateTime: "05/03 10:00",
        location: "京士柏運動場", fee: "AA ¥130",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: "六",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "家明", gender: .male, matchType: "雙打",
        weather: "🌤 25°C", dateTime: "05/03 16:00",
        location: "九龍仔公園", fee: "AA ¥160",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 16, dayOfWeek: "六",
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "曉彤", gender: .female, matchType: "單打",
        weather: "☀️ 30°C", dateTime: "05/04 11:00",
        location: "香港公園", fee: "AA ¥70",
        ntrpLow: 2.0, ntrpHigh: 3.0, ageRange: "14-17",
        genderLabel: "女", hour: 11, dayOfWeek: "日",
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "國輝", gender: .male, matchType: "單打",
        weather: "⛅ 24°C", dateTime: "05/04 07:00",
        location: "沙田公園", fee: "AA ¥100",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "55+",
        genderLabel: "男", hour: 7, dayOfWeek: "日",
        currentPlayers: 1, maxPlayers: 2
    ),
]
