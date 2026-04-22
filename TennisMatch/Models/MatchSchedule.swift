//
//  MatchSchedule.swift
//  TennisMatch
//
//  约球时间解析与过期判断的最小可用工具。
//
//  当前数据模型仍以字符串为主(MockMatch.dateTime / MatchDetailData.date+timeRange /
//  MyMatchItem.dateLabel+timeRange),完整的 Date 重构属于 ux-test-findings.md 6.2,
//  在那之前先用这个 helper 让"过期校验"逻辑能在多处复用。
//

import Foundation

enum MatchSchedule {
    /// 从任意字符串中找出第一个 `YYYY/MM/dd` 或 `MM/dd`(可选 HH:mm),组合成 `Date`。
    /// `text` 可以是 `"04/19 10:00"`、`"2026/04/19 10:00 - 12:00"`、`"明天 · 04/19(六) 10:00"` 等。
    /// 找不到 YYYY 时使用 `now` 的年份;找不到 HH:mm 时使用 `hourFallback`(默认 0)。
    static func startDate(
        text: String,
        hourFallback: Int? = nil,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> Date? {
        let year: Int
        let month: Int
        let day: Int

        // 优先匹配 YYYY/MM/dd,避免 `\d{1,2}/\d{1,2}` 在 `2026/04/19` 上误抓到 "26/04"。
        if let ymdRange = text.range(of: #"(\d{4})/(\d{1,2})/(\d{1,2})"#, options: .regularExpression) {
            let parts = text[ymdRange].split(separator: "/")
            guard parts.count == 3,
                  let y = Int(parts[0]),
                  let m = Int(parts[1]),
                  let d = Int(parts[2])
            else { return nil }
            year = y; month = m; day = d
        } else if let mdRange = text.range(of: #"(\d{1,2})/(\d{1,2})"#, options: .regularExpression) {
            let parts = text[mdRange].split(separator: "/")
            guard parts.count == 2,
                  let m = Int(parts[0]),
                  let d = Int(parts[1])
            else { return nil }
            year = calendar.component(.year, from: now)
            month = m; day = d
        } else {
            return nil
        }

        var hour = hourFallback ?? 0
        var minute = 0
        if let timeRange = text.range(of: #"(\d{1,2}):(\d{2})"#, options: .regularExpression) {
            let timeParts = text[timeRange].split(separator: ":")
            if timeParts.count == 2,
               let h = Int(timeParts[0]),
               let m = Int(timeParts[1]) {
                hour = h
                minute = m
            }
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }

    /// 起始时间已过即视为过期。无法解析的字符串返回 `false`(保守:不要误把数据当成过期)。
    static func isExpired(
        text: String,
        hourFallback: Int? = nil,
        now: Date = .now
    ) -> Bool {
        guard let start = startDate(text: text, hourFallback: hourFallback, now: now) else {
            return false
        }
        return start < now
    }

    /// 解析 `text` 的起止时间窗口。规则:
    /// - `start` 由首个 `HH:mm` 定;若 `text` 不含 `HH:mm`,使用 `hourFallback`(默认 0)。
    /// - `end` 由第二个 `HH:mm` 定(如 `"10:00 - 12:00"` 中的 `"12:00"`);
    ///   若不存在,回退到 `start + defaultDurationHours` 小时。
    /// 解析失败返回 `nil`。
    static func dateRange(
        text: String,
        defaultDurationHours: Int = 2,
        hourFallback: Int? = nil,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> (start: Date, end: Date)? {
        guard let start = startDate(
            text: text,
            hourFallback: hourFallback,
            calendar: calendar,
            now: now
        ) else { return nil }

        // 收集所有 HH:mm 出现位置,取第二个作为 end。
        var times: [(hour: Int, minute: Int)] = []
        var cursor = text.startIndex
        while cursor < text.endIndex,
              let r = text.range(of: #"(\d{1,2}):(\d{2})"#, options: .regularExpression, range: cursor..<text.endIndex) {
            let parts = text[r].split(separator: ":")
            if parts.count == 2,
               let h = Int(parts[0]),
               let m = Int(parts[1]) {
                times.append((h, m))
            }
            cursor = r.upperBound
        }

        let fallback = start.addingTimeInterval(TimeInterval(defaultDurationHours) * 3600)
        guard times.count >= 2 else { return (start, fallback) }

        let endTime = times[1]
        var endComps = calendar.dateComponents([.year, .month, .day], from: start)
        endComps.hour = endTime.hour
        endComps.minute = endTime.minute
        let end = calendar.date(from: endComps) ?? fallback
        // 若 end <= start(罕见的解析异常),用 fallback 兜底,避免空区间被误判为不冲突。
        return (start, end > start ? end : fallback)
    }
}
