//
//  AppDateFormatter.swift
//  TennisMatch
//
//  集中缓存的 DateFormatter 实例。
//
//  ⚠️ 不要在调用方 `let formatter = DateFormatter()`。
//  DateFormatter 构造昂贵 + locale/timezone 可能漂移,统一从这里取。
//
//  规则:
//  - 业务展示用格式(如 "MM/dd")—— 用 currentLocale,跟随用户系统语言
//  - 解析/序列化用格式 —— 锁 en_US_POSIX,避免阿拉伯/中文数字漂移
//

import Foundation

enum AppDateFormatter {
    /// 业务最常用 — "MM/dd" 月日,跟随当前 locale。
    static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd"
        return f
    }()

    /// "yyyy/MM/dd" 完整日期,跟随当前 locale。
    static let yearMonthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    /// "HH:mm" 24 小时时刻,跟随当前 locale。
    static let hourMinute: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// "yyyy-MM-dd HH:mm" — 用于解析/序列化,锁 POSIX 防漂移。
    static let posixDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
