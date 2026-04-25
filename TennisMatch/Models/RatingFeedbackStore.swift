//
//  RatingFeedbackStore.swift
//  TennisMatch
//
//  球友對當前用戶的 NTRP 評估 — 用於做 "自評 vs 實測" 偏差校準。
//
//  CLAUDE.md 邊界 case #5:評級偏差 → 觸發校準提示。
//
//  數據流:
//    - 賽後球友提交評價時,可選輸入對手 NTRP 估計 → 寫入對方的 store。
//    - Mock 階段:單用戶上下文,直接以種子數據模擬 "我已經被 5 個球友評過"。
//    - 接後端時:每次啟動拉 /me/peer-ratings,新評價通過 recordPeerRating 推入。
//
//  觸發條件(同時滿足):
//    1. 已有 ≥ minSampleSize (預設 3) 條球友評價(統計顯著)
//    2. 自評 NTRP 與球友均值差距 ≥ deviationThreshold (預設 0.5)
//
//  ProfileView 通過 calibrationSuggestion(selfNTRP:) 拿到展示用結構;
//  用戶點 "校準" → UserStore.ntrpLevel 寫入建議值;
//  用戶點 "保留" / "稍後" → 記住當前 peerAvg,下次 peerAvg 變化才會重新提示。
//

import Foundation
import Observation

struct PeerRatingEntry: Identifiable, Hashable {
    let id = UUID()
    let reviewer: String
    let ntrpEstimate: Double
    let date: String
}

/// 校準提示展示用結構。
struct CalibrationSuggestion: Equatable {
    /// 球友均值(原始,未取整)。
    let peerAverage: Double
    /// 建議用戶調整到的 NTRP(已對齊到 0.5 步進)。
    let suggested: Double
    /// 樣本數。
    let sampleSize: Int
    /// 偏差方向 — 用戶自評偏高還是偏低。
    let direction: Direction

    enum Direction {
        /// 球友覺得用戶水平比自評高 → 建議上調。
        case selfUnderrated
        /// 球友覺得用戶水平比自評低 → 建議下調。
        case selfOverrated
    }
}

@Observable
final class RatingFeedbackStore {
    private(set) var entries: [PeerRatingEntry]

    /// 樣本數至少達到此值,才會觸發校準提示。
    static let minSampleSize = 3
    /// |自評 - 球友均值| ≥ 此值,才會觸發校準提示。
    static let deviationThreshold = 0.5

    init(entries: [PeerRatingEntry] = RatingFeedbackStore.mockEntries) {
        self.entries = entries
    }

    var sampleSize: Int { entries.count }

    /// 球友 NTRP 估計的算術均值;沒有評價時返回 nil。
    var averageNTRP: Double? {
        guard !entries.isEmpty else { return nil }
        let sum = entries.reduce(0.0) { $0 + $1.ntrpEstimate }
        return sum / Double(entries.count)
    }

    /// 賽後評價提交時調用 — 把對手對自己的 NTRP 估計記下來。
    /// 接後端時這會在收到對方提交的評價後從推送/拉取流程觸發。
    func recordPeerRating(reviewer: String, ntrpEstimate: Double, date: String? = nil) {
        let dateLabel = date ?? RatingFeedbackStore.todayLabel
        let entry = PeerRatingEntry(
            reviewer: reviewer,
            ntrpEstimate: ntrpEstimate,
            date: dateLabel
        )
        entries.insert(entry, at: 0)
    }

    /// 算出當前是否需要顯示校準提示。返回 nil = 不顯示。
    /// - Parameter selfNTRP: 用戶在 UserStore 中的自評 NTRP。
    func calibrationSuggestion(selfNTRP: Double) -> CalibrationSuggestion? {
        guard sampleSize >= RatingFeedbackStore.minSampleSize,
              let avg = averageNTRP else { return nil }
        let deviation = avg - selfNTRP
        guard abs(deviation) >= RatingFeedbackStore.deviationThreshold else {
            return nil
        }
        // 對齊到 0.5 步進(NTRP 標準刻度)。
        let snapped = (avg * 2).rounded() / 2
        let clamped = min(max(snapped, 1.0), 7.0)
        return CalibrationSuggestion(
            peerAverage: avg,
            suggested: clamped,
            sampleSize: sampleSize,
            direction: deviation > 0 ? .selfUnderrated : .selfOverrated
        )
    }

    private static var todayLabel: String {
        return AppDateFormatter.monthDay.string(from: .now)
    }

    /// Mock seed:5 條球友評價,平均約 2.9 — 對應預設自評 3.5,
    /// 偏差 0.6 > 0.5 閾值,首次打開 Profile 即可看到校準提示。
    static let mockEntries: [PeerRatingEntry] = [
        PeerRatingEntry(reviewer: "莎拉", ntrpEstimate: 3.0, date: "04/19"),
        PeerRatingEntry(reviewer: "王強", ntrpEstimate: 2.5, date: "04/15"),
        PeerRatingEntry(reviewer: "小美", ntrpEstimate: 3.0, date: "04/10"),
        PeerRatingEntry(reviewer: "大衛", ntrpEstimate: 3.0, date: "04/06"),
        PeerRatingEntry(reviewer: "嘉欣", ntrpEstimate: 3.0, date: "03/29"),
    ]
}
