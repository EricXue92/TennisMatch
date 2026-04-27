import Foundation

/// 计算「审核截止时间」的纯函数。无状态、可独立测试。
///
/// 规则:
/// 1. 自动通过时刻 = `start − 12h`,固定。报名者永远拿到 ≥ 12h 通知。
/// 2. 发布时刻必须比 deadline 至少早 1h(host 缓冲),即 lead time ≥ 13h 才能开审核。
/// 3. lead time 不足 13h → 不允许开审核(UI 锁开关)。
enum ApprovalDeadlineCalculator {

    /// 报名者最少通知时长(deadline = start − 此值)。
    static let playerNoticeWindow: TimeInterval = 12 * 3600     // 12h

    /// host 在 publish 与 deadline 之间至少要拥有的时间窗口。
    static let minHostBuffer: TimeInterval = 1 * 3600           // 1h

    /// 启用审核所需的最小 lead time = 报名者通知 + host 缓冲。
    static let minLeadTimeForApproval: TimeInterval = playerNoticeWindow + minHostBuffer

    /// 计算自动接受触发时间。
    /// - `requiresApproval == false` → nil
    /// - lead time 不足(< 13h) → nil
    static func deadline(
        requiresApproval: Bool,
        publishedAt: Date,
        startDate: Date
    ) -> Date? {
        guard requiresApproval else { return nil }
        let leadTime = startDate.timeIntervalSince(publishedAt)
        guard leadTime >= minLeadTimeForApproval else { return nil }
        return startDate.addingTimeInterval(-playerNoticeWindow)
    }

    /// 当前发布参数下能否启用审核(用于 UI 锁开关)。
    static func canEnableApproval(publishedAt: Date, startDate: Date) -> Bool {
        startDate.timeIntervalSince(publishedAt) >= minLeadTimeForApproval
    }
}
