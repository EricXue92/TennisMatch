import XCTest
@testable import TennisMatch

final class ApprovalDeadlineCalculatorTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - 基础规则:deadline = start − 12h

    func test_deadline_isExactly12hBeforeStart_for3DayLead() {
        let start = now.addingTimeInterval(3 * 24 * 3600)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertEqual(deadline, start.addingTimeInterval(-12 * 3600))
    }

    func test_deadline_isExactly12hBeforeStart_for18hLead() {
        // 用户实拍场景:14h-22h 之间任意 lead 都该是 start − 12h
        let start = now.addingTimeInterval(18 * 3600)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertEqual(deadline, start.addingTimeInterval(-12 * 3600))
    }

    func test_deadline_atMinLeadTime_returnsExactly12hBefore() {
        // 13h lead 边界:host 拿到 1h,player 12h
        let start = now.addingTimeInterval(13 * 3600)
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertEqual(deadline, start.addingTimeInterval(-12 * 3600))
    }

    // MARK: - 不允许开审核

    func test_leadTimeUnder13h_returnsNil() {
        let start = now.addingTimeInterval(12 * 3600)   // 12h < 13h
        let deadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: true, publishedAt: now, startDate: start
        )
        XCTAssertNil(deadline)
    }

    func test_leadTime12h59min_returnsNil() {
        let start = now.addingTimeInterval(12 * 3600 + 59 * 60)
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

    // MARK: - canEnableApproval

    func test_canEnableApproval_under13hFalse() {
        let start = now.addingTimeInterval(12 * 3600 + 30 * 60)
        XCTAssertFalse(ApprovalDeadlineCalculator.canEnableApproval(
            publishedAt: now, startDate: start
        ))
    }

    func test_canEnableApproval_at13hTrue() {
        let start = now.addingTimeInterval(13 * 3600)
        XCTAssertTrue(ApprovalDeadlineCalculator.canEnableApproval(
            publishedAt: now, startDate: start
        ))
    }
}
