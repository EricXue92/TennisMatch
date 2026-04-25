//
//  SignUpMatchInfo.swift
//  TennisMatch
//
//  報名約球資訊模型 — 由 HomeView 和 MatchDetailView 共用的報名資料結構
//

import Foundation

struct SignUpMatchInfo: Identifiable {
    let id = UUID()
    let organizerName: String
    let organizerGender: Gender
    let dateTime: String
    let location: String
    let matchType: String
    let ntrpRange: String
    let fee: String
    let notes: String
    let players: String
    let isFull: Bool
    /// 独立的日期字段（来自 MatchDetailData），用于日历解析
    var date: String? = nil
    /// 独立的时间范围字段（来自 MatchDetailData），用于日历解析
    var timeRange: String? = nil
    /// Phase 2a: 起止绝对时间(全部场景必填,用于"加入日历"等)。
    let startDate: Date
    let endDate: Date

    /// 从 MatchDetailData 构造，便于 MatchDetailView 复用共享报名组件
    init(from detail: MatchDetailData) {
        self.organizerName = detail.name
        self.organizerGender = detail.gender
        self.dateTime = "\(detail.date) \(detail.timeRange)"
        self.location = detail.location
        self.matchType = detail.matchType
        self.ntrpRange = detail.ntrpRange
        self.fee = detail.fee
        self.notes = detail.notes
        self.players = detail.players
        self.isFull = detail.isFull
        self.date = detail.date
        self.timeRange = detail.timeRange
        self.startDate = detail.startDate
        self.endDate = detail.endDate
    }

    init(organizerName: String, organizerGender: Gender, dateTime: String,
         location: String, matchType: String, ntrpRange: String,
         fee: String, notes: String, players: String, isFull: Bool,
         startDate: Date, endDate: Date) {
        self.organizerName = organizerName
        self.organizerGender = organizerGender
        self.dateTime = dateTime
        self.location = location
        self.matchType = matchType
        self.ntrpRange = ntrpRange
        self.fee = fee
        self.notes = notes
        self.players = players
        self.isFull = isFull
        self.startDate = startDate
        self.endDate = endDate
    }
}
