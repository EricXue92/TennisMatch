//
//  CreditScoreStore.swift
//  TennisMatch
//
//  用户信誉积分(0-100)及变动历史。
//
//  规则(与 CreditScoreHistoryView 内的 rulesCard 对齐):
//    +1  完成一场约球
//    +1  获得球友好评
//    -1  pending 撤回(距开场 2-24 小时)
//    -2  pending 撤回(距开场不足 2 小时)
//    -4  已确认报名取消(距开场不足 4 小时)
//    -5  爽约未到场
//
//  账号处罚:
//    < 70  禁止发起约球(仍可报名他人发起的局)
//    < 60  封号 3 个月
//
//  Mock 阶段不持久化:重启 app 即恢复初始 score / entries。
//

import Foundation
import Observation

@Observable
@MainActor
final class CreditScoreStore {
    /// 当前积分,范围 0…100。
    private(set) var score: Int
    /// 变动记录,按时间倒序(新的在前)。
    private(set) var entries: [CreditScoreEntry]

    /// `score < lowScoreThreshold` 时,UI 应展示提醒条幅。
    static let lowScoreThreshold = 60
    /// 信誉分低于此值 → 禁止发起约球。
    static let publishGateThreshold = 70
    /// 信誉分低于此值 → 封号 3 个月。
    static let banThreshold = 60
    /// 已弃用别名 — 老代码在迁移期内仍引用 `freezeThreshold`,实际语义已改为「禁止发起约球」。
    @available(*, deprecated, renamed: "publishGateThreshold")
    static let freezeThreshold = publishGateThreshold

    init(
        score: Int = 80,
        entries: [CreditScoreEntry] = CreditScoreHistoryView.mockEntries
    ) {
        self.score = max(0, min(100, score))
        self.entries = entries
    }

    var isLowScore: Bool { score < CreditScoreStore.lowScoreThreshold }

    /// 是否仍允许发起约球(< 70 → false)。
    var canPublishMatch: Bool { score >= CreditScoreStore.publishGateThreshold }

    /// 是否已封号(< 60 → true,三个月内禁所有写操作)。
    var isBanned: Bool { score < CreditScoreStore.banThreshold }

    /// 应用一次变动 — 自动夹紧到 0…100,并把记录插入到最前面。
    func apply(delta: Int, reason: String, detail: String, dateLabel: String? = nil) {
        let date = dateLabel ?? CreditScoreStore.todayLabel
        let entry = CreditScoreEntry(date: date, delta: delta, reason: reason, detail: detail)
        entries.insert(entry, at: 0)
        score = max(0, min(100, score + delta))
    }

    /// 临时取消 — 根据距开场时间阶梯扣分:
    ///   ≥24h: 0分(不扣)
    ///   2-24h: -1分
    ///   <2h: -2分
    /// 返回实际扣除的分数(绝对值),0 表示不扣分。
    @discardableResult
    func recordCancellation(hoursBeforeStart: Double, detail: String) -> Int {
        let deduction: Int
        if hoursBeforeStart >= 24 {
            return 0
        } else if hoursBeforeStart >= 2 {
            deduction = 1
        } else {
            deduction = 2
        }
        let hours = max(0, Int(hoursBeforeStart.rounded(.down)))
        apply(
            delta: -deduction,
            reason: "臨時取消",
            detail: "\(detail) · 距開場 \(hours) 小時"
        )
        return deduction
    }

    /// 已确认报名取消 — 仅当距开场不足 4 小时时扣 4 分;≥4h 不扣分。
    /// 与 `recordCancellation(hoursBeforeStart:)` 区分:后者用于 pending 撤回(tiered -1/-2)。
    /// 返回实际扣除的分数(绝对值),0 表示不扣分。
    @discardableResult
    func recordConfirmedCancellation(hoursBeforeStart: Double, detail: String) -> Int {
        guard hoursBeforeStart < 4 else { return 0 }
        let hours = max(0, Int(hoursBeforeStart.rounded(.down)))
        apply(
            delta: -4,
            reason: "確認後取消",
            detail: "\(detail) · 距開場 \(hours) 小時"
        )
        return 4
    }

    /// 爽约未到场 — 扣 5 分。供后端考勤上报回来时调用。
    func recordNoShow(detail: String) {
        apply(delta: -5, reason: "爽約未到場", detail: detail)
    }

    /// 完成一场约球 — 加 1 分。当后端的赛后考勤上报回来时调用。
    func recordCompletion(detail: String) {
        apply(delta: 1, reason: "完成約球", detail: detail)
    }

    private static var todayLabel: String {
        return AppDateFormatter.monthDay.string(from: .now)
    }
}
