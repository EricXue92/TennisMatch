import XCTest
@testable import TennisMatch

final class ApprovalDeadlineCalculatorTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func test_normalLeadTime_clampsTo12h() {
        // 提前 3 天发布
        let start = now.addingTimeInterval(3 * 24 * 3600)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertEqual(deadline, start.addingTimeInterval(-12 * 3600))
    }

    func test_shortLeadTime_clampsToHalf() {
        // 提前 5h 发布 → deadline = start - 2.5h
        let start = now.addingTimeInterval(5 * 3600)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertEqual(deadline, start.addingTimeInterval(-2.5 * 3600))
    }

    func test_underHalfHour_returnsNil() {
        // 提前 20min,不允许开审核
        let start = now.addingTimeInterval(20 * 60)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertNil(deadline)
    }

    func test_requiresApprovalFalse_returnsNil() {
        let start = now.addingTimeInterval(3 * 24 * 3600)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: false, publishedAt: now, startDate: start
        )
        XCTAssertNil(deadline)
    }

    func test_canEnableApproval_underHalfHourFalse() {
        let start = now.addingTimeInterval(20 * 60)
        XCTAssertFalse(ApprovalDeadlineCalculator.canEnableApproval(
            publishedAt: now, startDate: start
        ))
    }

    func test_canEnableApproval_atHalfHourTrue() {
        let start = now.addingTimeInterval(31 * 60)
        XCTAssertTrue(ApprovalDeadlineCalculator.canEnableApproval(
            publishedAt: now, startDate: start
        ))
    }
}
