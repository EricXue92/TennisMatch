import Foundation

/// 计算「审核截止时间」的纯函数。无状态、可独立测试。
enum ApprovalDeadlineCalculator {

    /// 短局阈值:总时长 < 此值时不允许开审核。
    static let minLeadTimeForApproval: TimeInterval = 30 * 60   // 30 min

    /// 自动审核窗口上限。
    static let maxApprovalWindow: TimeInterval = 12 * 3600      // 12h

    /// 安静时段:候选时刻落在 [22:00, 08:00) 时推到次日 08:00,
    /// 避免「凌晨 1:59 自动处理」这种 host 看不到的兜底。
    static let quietHoursStart: Int = 22
    static let quietHoursEnd: Int = 8

    /// 计算自动接受触发时间。`requiresApproval == false` 或 lead time 太短 → nil。
    ///
    /// 规则:
    /// 1. `window = min(12h, leadTime − 30min)`(永远给候补留 30min 缓冲)
    /// 2. `candidate = startDate − window`
    /// 3. 若 candidate 落在 22:00–08:00,推到次日 08:00 —— 但必须仍 ≤ `start − 30min`,
    ///    否则保留原 candidate(短赛或凌晨开赛时无路可推)。
    static func deadline(
        requiresApproval: Bool,
        publishedAt: Date,
        startDate: Date,
        calendar: Calendar = .current
    ) -> Date? {
        guard requiresApproval else { return nil }
        let leadTime = startDate.timeIntervalSince(publishedAt)
        guard leadTime >= minLeadTimeForApproval else { return nil }
        let window = min(maxApprovalWindow, leadTime - minLeadTimeForApproval)
        let candidate = startDate.addingTimeInterval(-window)
        return clampOutOfQuietHours(candidate, startDate: startDate, calendar: calendar)
    }

    /// 当前发布参数下能否启用审核(用于 UI 锁开关)。
    static func canEnableApproval(publishedAt: Date, startDate: Date) -> Bool {
        startDate.timeIntervalSince(publishedAt) >= minLeadTimeForApproval
    }

    private static func clampOutOfQuietHours(
        _ candidate: Date,
        startDate: Date,
        calendar: Calendar
    ) -> Date {
        let hour = calendar.component(.hour, from: candidate)
        let inQuiet = hour >= quietHoursStart || hour < quietHoursEnd
        guard inQuiet else { return candidate }

        let snapped: Date?
        if hour < quietHoursEnd {
            snapped = calendar.date(
                bySettingHour: quietHoursEnd, minute: 0, second: 0, of: candidate
            )
        } else {
            snapped = calendar
                .date(byAdding: .day, value: 1, to: candidate)
                .flatMap {
                    calendar.date(bySettingHour: quietHoursEnd, minute: 0, second: 0, of: $0)
                }
        }
        guard let snapped,
              snapped <= startDate.addingTimeInterval(-minLeadTimeForApproval)
        else { return candidate }
        return snapped
    }
}
