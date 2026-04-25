//
//  CreditScoreStore.swift
//  TennisMatch
//
//  用户信誉积分(0-100)及变动历史。
//
//  规则(与 CreditScoreHistoryView 内的 rulesCard 对齐):
//    +1  完成一场约球
//    +1  获得球友好评
//    -1  临时取消(距开场 2-24 小时)
//    -2  临时取消(距开场不足 2 小时)
//    -10 爽约未到场
//
//  账号处罚:
//    信誉分低于 70 → 冻结账号 1 个月
//    信誉分低于 60 → 永久封号
//
//  Mock 阶段不持久化:重启 app 即恢复初始 score / entries。
//  接后端时:每次启动从 /credit-score 接口拉取,本地变动通过 mutation 回写。
//
//  CLAUDE.md 边界 case #3:连续爽约 → 降低信用分。爽约的检测目前需要服务端
//  在比赛结束后做考勤对账(参与者互评是否到场),前端只暴露"临时取消"
//  这一可在客户端判定的扣分入口,以及一个开发期可调用的 recordNoShow API,
//  供后续接入举报/对账流程时调用。
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
    /// 信誉分低于此值 → 冻结账号 1 个月。
    static let freezeThreshold = 70
    /// 信誉分低于此值 → 永久封号。
    static let banThreshold = 60

    init(
        score: Int = 80,
        entries: [CreditScoreEntry] = CreditScoreHistoryView.mockEntries
    ) {
        self.score = max(0, min(100, score))
        self.entries = entries
    }

    var isLowScore: Bool { score < CreditScoreStore.lowScoreThreshold }

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

    /// 爽约未到场 — 扣 10 分。目前仅供后续 "举报未到场 / 对账" 流程接入。
    func recordNoShow(detail: String) {
        apply(delta: -10, reason: "爽約未到場", detail: detail)
    }

    /// 完成一场约球 — 加 1 分。当后端的赛后考勤上报回来时调用。
    func recordCompletion(detail: String) {
        apply(delta: 1, reason: "完成約球", detail: detail)
    }

    private static var todayLabel: String {
        return AppDateFormatter.monthDay.string(from: .now)
    }
}
