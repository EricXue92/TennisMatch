import Foundation

/// 计算「审核截止时间」的纯函数。无状态、可独立测试。
enum ApprovalDeadlineCalculator {

    /// 短局阈值:总时长 < 此值时不允许开审核。
    static let minLeadTimeForApproval: TimeInterval = 30 * 60   // 30 min

    /// 自动审核窗口上限。
    static let maxApprovalWindow: TimeInterval = 12 * 3600      // 12h

    /// 计算自动接受触发时间。`requiresApproval == false` 或 lead time 太短 → nil。
    static func deadline(
        requiresApproval: Bool,
        publishedAt: Date,
        startDate: Date
    ) -> Date? {
        guard requiresApproval else { return nil }
        let leadTime = startDate.timeIntervalSince(publishedAt)
        guard leadTime >= minLeadTimeForApproval else { return nil }
        let window = min(maxApprovalWindow, leadTime / 2)
        return startDate.addingTimeInterval(-window)
    }

    /// 当前发布参数下能否启用审核(用于 UI 锁开关)。
    static func canEnableApproval(publishedAt: Date, startDate: Date) -> Bool {
        startDate.timeIntervalSince(publishedAt) >= minLeadTimeForApproval
    }
}
