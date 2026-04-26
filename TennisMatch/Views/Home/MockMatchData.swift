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
    /// Phase 2a: 起始绝对时间。后续 sortDate/isExpired 改为基于此字段;
    /// `dateTime` 字符串过渡期保留,Phase 2a 末尾会删除。
    let startDate: Date
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
    /// 球局发起人 ID(对应 UserStore.id)。mock seed 写死;真后端从 host 关系拉。
    var hostID: UUID = UUID()
    /// 发起人是否要求审核报名者。默认关 — 兼容现有「自动通过」体验。
    var requiresApproval: Bool = false
    /// 自动接受触发时间。发布时一次算定,nil 表示不需要审核或 lead time 太短。
    var approvalDeadline: Date? = nil

    var players: String {
        "\(currentPlayers)/\(maxPlayers) • \(String(format: "%.1f-%.1f", ntrpLow, ntrpHigh))"
    }

    var isFull: Bool { currentPlayers >= maxPlayers }

    /// 起始时间已过 — 直接基于 `startDate` 比较。
    var isExpired: Bool { startDate < .now }

    /// 起始时间已过且未满员 — 视为"人员不足,自动取消"(CLAUDE.md 边界 case #2)。
    /// 即使用户已报名,该约球实际未进行,UI 应优先展示"已自動取消"覆盖"已報名"。
    var isAutoCancelled: Bool { isExpired && !isFull }

    /// 用于首页按时间排序 — 最近的时间在最上面。
    var sortDate: Date { startDate }

    /// 显示用的完整时段字符串,如 "04/23 09:00 - 11:00"。
    /// Phase 2a:直接用 startDate + 2h 算 endDate,避免字符串截取丢失开始时间的分钟。
    /// 旧实现 `(startHour + 2):00` 会把 08:30 的结束时间错算成 10:00(实际 10:30),
    /// 导致首页显示与冲突检测(用真实 Date 算)对不上,用户看到「不重叠」却被拒。
    var dateTimeDisplay: String {
        let endDate = startDate.addingTimeInterval(2 * 3600)
        let dateStr = AppDateFormatter.monthDay.string(from: startDate)
        let startTime = AppDateFormatter.hourMinute.string(from: startDate)
        let endTime = AppDateFormatter.hourMinute.string(from: endDate)
        return "\(dateStr) \(startTime) - \(endTime)"
    }
}

// MARK: - Cancellation Payload (MyMatchesView → HomeView)

/// 取消約球時 MyMatchesView 傳給 HomeView 的資料,讓首頁能正確處理三種情境:
/// 1. `sourceMatchID` 對應到首頁已存在的 MockMatch → 遞減 currentPlayers,該球賽重新可見。
/// 2. 沒有源 MockMatch(種子假資料 / 邀請接受 / 聊天接受)且當前用戶非發起人 →
///    在首頁新建一個 MockMatch,模擬「空出名額讓其他人看到」。
/// 3. 當前用戶是發起人(isOrganizer=true) → 視為發起人取消整場,不重新出現在首頁。
struct CancelledMatchPayload {
    /// 對應的首頁 MockMatch.id,若不存在則為 nil。
    let sourceMatchID: UUID?
    /// 當前用戶是否為該約球發起人。發起人取消 = 整場取消,不應在首頁重生。
    let isOrganizer: Bool
    /// 形如 "莎拉 發起的單打" 或 "我發起的雙打"。用來解析發起人姓名。
    let title: String
    let location: String
    let weather: String
    let matchType: String
    let startDate: Date
    /// 形如 "2/2 · NTRP 3.0-4.0",取消後 currentPlayers 自動 -1。
    let players: String
}

// MARK: - Mock Date Helpers

/// 生成相對於今天的日期字串（MM/dd 格式），確保 mock 數據永不過期
private let _mockCalendar = Calendar.current
private let _mockToday = Date()
private let _weekdayNames = ["日", "一", "二", "三", "四", "五", "六"]

private func mockDate(_ daysFromNow: Int) -> String {
    guard let date = _mockCalendar.date(byAdding: .day, value: daysFromNow, to: _mockToday) else { return "01/01" }
    return AppDateFormatter.monthDay.string(from: date)
}

private func mockDayOfWeek(_ daysFromNow: Int) -> String {
    guard let date = _mockCalendar.date(byAdding: .day, value: daysFromNow, to: _mockToday) else { return "一" }
    let weekday = _mockCalendar.component(.weekday, from: date)
    return _weekdayNames[weekday - 1]
}

/// 生成相对今天 `daysFromNow` 天后的指定 `hour:minute` 起始时间。
/// 与 `mockDate(_:)` 共享 `_mockToday` / `_mockCalendar`,确保两者派生一致。
private func mockStartDate(_ daysFromNow: Int, hour: Int, minute: Int = 0) -> Date {
    guard let day = _mockCalendar.date(byAdding: .day, value: daysFromNow, to: _mockToday) else {
        return _mockToday
    }
    var comps = _mockCalendar.dateComponents([.year, .month, .day], from: day)
    comps.hour = hour
    comps.minute = minute
    return _mockCalendar.date(from: comps) ?? day
}

// MARK: - Mock Match Data

let initialMockMatches: [MockMatch] = [
    // day -2: 已過期，用於測試 isExpired / isAutoCancelled
    MockMatch(
        name: "小美", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "\(mockDate(-2)) 10:00",
        startDate: mockStartDate(-2, hour: 10),
        location: "沙田公園", fee: "AA ¥80",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "18-25",
        genderLabel: "女", hour: 10, dayOfWeek: mockDayOfWeek(-2),
        currentPlayers: 3, maxPlayers: 4
    ),
    MockMatch(
        name: "大衛", gender: .male, matchType: "雙打",
        weather: "⛅ 23°C", dateTime: "\(mockDate(-2)) 18:30",
        startDate: mockStartDate(-2, hour: 18, minute: 30),
        location: "歌和老街公園", fee: "AA ¥180",
        ntrpLow: 4.0, ntrpHigh: 5.0, ageRange: "26-35",
        genderLabel: "男", hour: 18, dayOfWeek: mockDayOfWeek(-2),
        currentPlayers: 2, maxPlayers: 4
    ),
    // day -1: 昨天，部分已過期
    MockMatch(
        name: "莎拉", gender: .female, matchType: "單打",
        weather: "☀️ 24°C", dateTime: "\(mockDate(-1)) 10:00",
        startDate: mockStartDate(-1, hour: 10),
        location: "維多利亞公園網球場", fee: "AA ¥120",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: mockDayOfWeek(-1),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "嘉欣", gender: .female, matchType: "單打",
        weather: "🌤 26°C", dateTime: "\(mockDate(-1)) 09:00",
        startDate: mockStartDate(-1, hour: 9),
        location: "香港公園", fee: "AA ¥100",
        ntrpLow: 2.5, ntrpHigh: 3.5, ageRange: "18-25",
        genderLabel: "女", hour: 9, dayOfWeek: mockDayOfWeek(-1),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "俊傑", gender: .male, matchType: "雙打",
        weather: "☀️ 29°C", dateTime: "\(mockDate(-1)) 15:00",
        startDate: mockStartDate(-1, hour: 15),
        location: "將軍澳運動場", fee: "AA ¥160",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 15, dayOfWeek: mockDayOfWeek(-1),
        currentPlayers: 1, maxPlayers: 4
    ),
    MockMatch(
        name: "阿杰", gender: .male, matchType: "單打",
        weather: "☀️ 25°C", dateTime: "\(mockDate(-1)) 07:00",
        startDate: mockStartDate(-1, hour: 7),
        location: "沙田公園", fee: "AA ¥60",
        ntrpLow: 2.0, ntrpHigh: 3.0, ageRange: "18-25",
        genderLabel: "男", hour: 7, dayOfWeek: mockDayOfWeek(-1),
        currentPlayers: 1, maxPlayers: 2
    ),
    // day 0: 今天
    MockMatch(
        name: "王強", gender: .male, matchType: "雙打",
        weather: "⛅ 26°C", dateTime: "\(mockDate(0)) 14:00",
        startDate: mockStartDate(0, hour: 14),
        location: "跑馬地遊樂場", fee: "AA ¥200",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 14, dayOfWeek: mockDayOfWeek(0),
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "麗莎", gender: .female, matchType: "雙打",
        weather: "⛅ 26°C", dateTime: "\(mockDate(0)) 19:00",
        startDate: mockStartDate(0, hour: 19),
        location: "香港網球中心", fee: "AA ¥250",
        ntrpLow: 4.5, ntrpHigh: 5.5, ageRange: "26-35",
        genderLabel: "女", hour: 19, dayOfWeek: mockDayOfWeek(0),
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "老張", gender: .male, matchType: "單打",
        weather: "🌤 22°C", dateTime: "\(mockDate(0)) 07:00",
        startDate: mockStartDate(0, hour: 7),
        location: "九龍仔公園", fee: "AA ¥200",
        ntrpLow: 5.0, ntrpHigh: 6.0, ageRange: "46-55",
        genderLabel: "男", hour: 7, dayOfWeek: mockDayOfWeek(0),
        currentPlayers: 1, maxPlayers: 2
    ),
    // day 1: 明天
    MockMatch(
        name: "小李", gender: .male, matchType: "雙打",
        weather: "⛅ 26°C", dateTime: "\(mockDate(1)) 14:00",
        startDate: mockStartDate(1, hour: 14),
        location: "跑馬地遊樂場", fee: "AA ¥200",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 14, dayOfWeek: mockDayOfWeek(1),
        currentPlayers: 2, maxPlayers: 4,
        isOwnMatch: true
    ),
    MockMatch(
        name: "美琪", gender: .female, matchType: "單打",
        weather: "☀️ 28°C", dateTime: "\(mockDate(1)) 08:30",
        startDate: mockStartDate(1, hour: 8, minute: 30),
        location: "九龍仔公園", fee: "AA ¥100",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "18-25",
        genderLabel: "女", hour: 8, dayOfWeek: mockDayOfWeek(1),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "志明", gender: .male, matchType: "單打",
        weather: "🌤 25°C", dateTime: "\(mockDate(1)) 16:00",
        startDate: mockStartDate(1, hour: 16),
        location: "香港網球中心", fee: "AA ¥150",
        ntrpLow: 4.0, ntrpHigh: 4.5, ageRange: "36-45",
        genderLabel: "男", hour: 16, dayOfWeek: mockDayOfWeek(1),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "小玲", gender: .female, matchType: "單打",
        weather: "☀️ 28°C", dateTime: "\(mockDate(1)) 17:30",
        startDate: mockStartDate(1, hour: 17, minute: 30),
        location: "將軍澳運動場", fee: "AA ¥70",
        ntrpLow: 2.0, ntrpHigh: 2.5, ageRange: "18-25",
        genderLabel: "女", hour: 17, dayOfWeek: mockDayOfWeek(1),
        currentPlayers: 1, maxPlayers: 2
    ),
    // day 2+: 未來
    MockMatch(
        name: "林叔", gender: .male, matchType: "雙打",
        weather: "⛅ 24°C", dateTime: "\(mockDate(2)) 15:00",
        startDate: mockStartDate(2, hour: 15),
        location: "維多利亞公園網球場", fee: "AA ¥120",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "55+",
        genderLabel: "男", hour: 15, dayOfWeek: mockDayOfWeek(2),
        currentPlayers: 3, maxPlayers: 4
    ),
    MockMatch(
        name: "Kelly", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "\(mockDate(3)) 10:30",
        startDate: mockStartDate(3, hour: 10, minute: 30),
        location: "沙田公園", fee: "AA ¥100",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: mockDayOfWeek(3),
        currentPlayers: 1, maxPlayers: 4
    ),
    MockMatch(
        name: "Peter", gender: .male, matchType: "單打",
        weather: "☀️ 30°C", dateTime: "\(mockDate(4)) 20:00",
        startDate: mockStartDate(4, hour: 20),
        location: "跑馬地遊樂場", fee: "AA ¥180",
        ntrpLow: 4.5, ntrpHigh: 5.0, ageRange: "36-45",
        genderLabel: "男", hour: 20, dayOfWeek: mockDayOfWeek(4),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "陳教練", gender: .male, matchType: "單打",
        weather: "🌤 23°C", dateTime: "\(mockDate(5)) 07:30",
        startDate: mockStartDate(5, hour: 7, minute: 30),
        location: "香港網球中心", fee: "AA ¥300",
        ntrpLow: 5.0, ntrpHigh: 6.0, ageRange: "36-45",
        genderLabel: "男", hour: 7, dayOfWeek: mockDayOfWeek(5),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "雅婷", gender: .female, matchType: "雙打",
        weather: "☀️ 26°C", dateTime: "\(mockDate(5)) 17:00",
        startDate: mockStartDate(5, hour: 17),
        location: "九龍公園", fee: "AA ¥90",
        ntrpLow: 2.5, ntrpHigh: 3.0, ageRange: "18-25",
        genderLabel: "女", hour: 17, dayOfWeek: mockDayOfWeek(5),
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "阿豪", gender: .male, matchType: "雙打",
        weather: "⛅ 25°C", dateTime: "\(mockDate(6)) 19:30",
        startDate: mockStartDate(6, hour: 19, minute: 30),
        location: "歌和老街公園", fee: "AA ¥150",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "男", hour: 19, dayOfWeek: mockDayOfWeek(6),
        currentPlayers: 1, maxPlayers: 4
    ),
    MockMatch(
        name: "思慧", gender: .female, matchType: "單打",
        weather: "☀️ 29°C", dateTime: "\(mockDate(6)) 09:00",
        startDate: mockStartDate(6, hour: 9),
        location: "將軍澳運動場", fee: "AA ¥80",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "26-35",
        genderLabel: "女", hour: 9, dayOfWeek: mockDayOfWeek(6),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "張偉", gender: .male, matchType: "單打",
        weather: "🌤 24°C", dateTime: "\(mockDate(7)) 08:00",
        startDate: mockStartDate(7, hour: 8),
        location: "維多利亞公園網球場", fee: "AA ¥120",
        ntrpLow: 4.0, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 8, dayOfWeek: mockDayOfWeek(7),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "詠琪", gender: .female, matchType: "雙打",
        weather: "☀️ 27°C", dateTime: "\(mockDate(7)) 15:30",
        startDate: mockStartDate(7, hour: 15, minute: 30),
        location: "沙田公園", fee: "AA ¥100",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "18-25",
        genderLabel: "女", hour: 15, dayOfWeek: mockDayOfWeek(7),
        currentPlayers: 3, maxPlayers: 4
    ),
    MockMatch(
        name: "Michael", gender: .male, matchType: "單打",
        weather: "⛅ 22°C", dateTime: "\(mockDate(8)) 18:00",
        startDate: mockStartDate(8, hour: 18),
        location: "跑馬地遊樂場", fee: "AA ¥200",
        ntrpLow: 4.5, ntrpHigh: 5.5, ageRange: "36-45",
        genderLabel: "男", hour: 18, dayOfWeek: mockDayOfWeek(8),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "艾美", gender: .female, matchType: "雙打",
        weather: "☀️ 28°C", dateTime: "\(mockDate(9)) 10:00",
        startDate: mockStartDate(9, hour: 10),
        location: "京士柏運動場", fee: "AA ¥130",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: mockDayOfWeek(9),
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "家明", gender: .male, matchType: "雙打",
        weather: "🌤 25°C", dateTime: "\(mockDate(9)) 16:00",
        startDate: mockStartDate(9, hour: 16),
        location: "九龍仔公園", fee: "AA ¥160",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 16, dayOfWeek: mockDayOfWeek(9),
        currentPlayers: 2, maxPlayers: 4
    ),
    MockMatch(
        name: "曉彤", gender: .female, matchType: "單打",
        weather: "☀️ 30°C", dateTime: "\(mockDate(10)) 11:00",
        startDate: mockStartDate(10, hour: 11),
        location: "香港公園", fee: "AA ¥70",
        ntrpLow: 2.0, ntrpHigh: 3.0, ageRange: "14-17",
        genderLabel: "女", hour: 11, dayOfWeek: mockDayOfWeek(10),
        currentPlayers: 1, maxPlayers: 2
    ),
    MockMatch(
        name: "國輝", gender: .male, matchType: "單打",
        weather: "⛅ 24°C", dateTime: "\(mockDate(10)) 07:00",
        startDate: mockStartDate(10, hour: 7),
        location: "沙田公園", fee: "AA ¥100",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "55+",
        genderLabel: "男", hour: 7, dayOfWeek: mockDayOfWeek(10),
        currentPlayers: 1, maxPlayers: 2
    ),
    // MARK: 拉球 (rally / hitting practice)
    // day -1 19:00:已過期未滿 → isAutoCancelled,驗證自動取消顯示
    MockMatch(
        name: "Tony", gender: .male, matchType: "拉球",
        weather: "🌙 22°C", dateTime: "\(mockDate(-1)) 19:00",
        startDate: mockStartDate(-1, hour: 19),
        location: "九龍公園", fee: "AA ¥80",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "男", hour: 19, dayOfWeek: mockDayOfWeek(-1),
        currentPlayers: 1, maxPlayers: 2
    ),
    // day +1 10:30:與「莎拉 單打 10:00-12:00」時間衝突,驗證報名衝突攔截
    MockMatch(
        name: "嘉俐", gender: .female, matchType: "拉球",
        weather: "☀️ 25°C", dateTime: "\(mockDate(1)) 10:30",
        startDate: mockStartDate(1, hour: 10, minute: 30),
        location: "京士柏運動場", fee: "AA ¥90",
        ntrpLow: 3.0, ntrpHigh: 3.5, ageRange: "26-35",
        genderLabel: "女", hour: 10, dayOfWeek: mockDayOfWeek(1),
        currentPlayers: 1, maxPlayers: 2
    ),
    // day +2 07:00:已滿員(2/2),驗證 isFull 視覺;與 #拉球-Kelly(我已報名)時間吻合
    MockMatch(
        name: "Kelly", gender: .female, matchType: "拉球",
        weather: "🌤 24°C", dateTime: "\(mockDate(2)) 07:00",
        startDate: mockStartDate(2, hour: 7),
        location: "維多利亞公園網球場", fee: "AA ¥70",
        ntrpLow: 3.5, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "女", hour: 7, dayOfWeek: mockDayOfWeek(2),
        currentPlayers: 2, maxPlayers: 2
    ),
    // day +3 14:00:與「我發起的雙打 14:00-16:00」完全重疊,驗證 own-match 衝突
    MockMatch(
        name: "宏達", gender: .male, matchType: "拉球",
        weather: "⛅ 26°C", dateTime: "\(mockDate(3)) 14:00",
        startDate: mockStartDate(3, hour: 14),
        location: "歌和老街公園", fee: "AA ¥100",
        ntrpLow: 3.5, ntrpHigh: 4.5, ageRange: "26-35",
        genderLabel: "男", hour: 14, dayOfWeek: mockDayOfWeek(3),
        currentPlayers: 1, maxPlayers: 2
    ),
    // day +4 09:00:招募中(1/4),拉球的雙邊輪換玩法;NTRP 跨度大,測寬鬆條件
    MockMatch(
        name: "陳叔", gender: .male, matchType: "拉球",
        weather: "☀️ 28°C", dateTime: "\(mockDate(4)) 09:00",
        startDate: mockStartDate(4, hour: 9),
        location: "沙田公園", fee: "AA ¥60",
        ntrpLow: 2.5, ntrpHigh: 5.0, ageRange: "36-45",
        genderLabel: "男", hour: 9, dayOfWeek: mockDayOfWeek(4),
        currentPlayers: 1, maxPlayers: 4
    ),
    // day +5 16:00:isOwnMatch — 我發起的拉球(對應 MyMatchesView 同時段那筆)
    MockMatch(
        name: "小李", gender: .male, matchType: "拉球",
        weather: "☀️ 27°C", dateTime: "\(mockDate(5)) 16:00",
        startDate: mockStartDate(5, hour: 16),
        location: "香港公園", fee: "AA ¥80",
        ntrpLow: 3.0, ntrpHigh: 4.0, ageRange: "26-35",
        genderLabel: "男", hour: 16, dayOfWeek: mockDayOfWeek(5),
        currentPlayers: 1, maxPlayers: 2,
        isOwnMatch: true
    ),
]
