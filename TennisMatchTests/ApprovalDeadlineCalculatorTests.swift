import XCTest
@testable import TennisMatch

final class ApprovalDeadlineCalculatorTests: XCTestCase {

    /// 固定 UTC 日历 — 避免 CI / 本地 TZ 差异导致 quiet-hours 判断飘移。
    private let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d; comps.hour = h; comps.minute = min
        return utc.date(from: comps)!
    }

    // MARK: - 基础窗口

    func test_normalLeadTime_clampsTo12h() {
        // 3 天 lead,start 选在 20:00 让 -12h 落到 08:00 daytime 边界(不被 quiet 改)
        let publishedAt = date(2026, 4, 24, 20)
        let start = date(2026, 4, 27, 20)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: publishedAt, startDate: start, calendar: utc
        )
        XCTAssertEqual(deadline, date(2026, 4, 27, 8, 0))
    }

    func test_shortLeadTime_clampsToLeadMinus30min() {
        // 5h lead → window = 4.5h,start 18:00 → candidate 13:30(daytime,quiet 不动)
        let publishedAt = date(2026, 4, 27, 13)
        let start = date(2026, 4, 27, 18)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: publishedAt, startDate: start, calendar: utc
        )
        XCTAssertEqual(deadline, date(2026, 4, 27, 13, 30))
    }

    func test_underHalfHour_returnsNil() {
        let publishedAt = date(2026, 4, 27, 12)
        let start = publishedAt.addingTimeInterval(20 * 60)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: publishedAt, startDate: start, calendar: utc
        )
        XCTAssertNil(deadline)
    }

    func test_requiresApprovalFalse_returnsNil() {
        let publishedAt = date(2026, 4, 24, 20)
        let start = date(2026, 4, 27, 20)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: false, publishedAt: publishedAt, startDate: start, calendar: utc
        )
        XCTAssertNil(deadline)
    }

    // MARK: - Quiet hours

    func test_quietHourCandidate_snapsTo8AM() {
        // 用户那个真实 case:start 4/28 13:00,publish 4/27 15:00 → lead 22h
        // window = min(12h, 21.5h) = 12h,candidate 4/28 01:00 落在 quiet → 推到 4/28 08:00
        let publishedAt = date(2026, 4, 27, 15)
        let start = date(2026, 4, 28, 13)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: publishedAt, startDate: start, calendar: utc
        )
        XCTAssertEqual(deadline, date(2026, 4, 28, 8, 0))
    }

    func test_quietHourCandidate_22OClock_snapsToNextDay8AM() {
        // candidate 恰好 22:00(quiet 起点)→ 推到次日 08:00
        // start 次日 10:00,3 天 lead → window 12h → candidate = 前一天 22:00
        let publishedAt = date(2026, 4, 24, 10)
        let start = date(2026, 4, 27, 10)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: publishedAt, startDate: start, calendar: utc
        )
        XCTAssertEqual(deadline, date(2026, 4, 27, 8, 0))
    }

    func test_quietHourCandidate_keepsOriginalIfSnapWouldExceedStart() {
        // 凌晨开赛:start 4:00,4h lead → candidate 00:30(quiet)
        // 推到 08:00 比 start − 30min = 03:30 还晚 → 不推,保留 00:30
        let publishedAt = date(2026, 4, 27, 0)
        let start = date(2026, 4, 27, 4)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: publishedAt, startDate: start, calendar: utc
        )
        XCTAssertEqual(deadline, date(2026, 4, 27, 0, 30))
    }

    // MARK: - canEnableApproval

    func test_canEnableApproval_underHalfHourFalse() {
        let publishedAt = date(2026, 4, 27, 12)
        let start = publishedAt.addingTimeInterval(20 * 60)
        XCTAssertFalse(ApprovalDeadlineCalculator.canEnableApproval(
            publishedAt: publishedAt, startDate: start
        ))
    }

    func test_canEnableApproval_atHalfHourTrue() {
        let publishedAt = date(2026, 4, 27, 12)
        let start = publishedAt.addingTimeInterval(31 * 60)
        XCTAssertTrue(ApprovalDeadlineCalculator.canEnableApproval(
            publishedAt: publishedAt, startDate: start
        ))
    }
}
