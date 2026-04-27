import XCTest
@testable import TennisMatch

final class BookingApprovalStatusTests: XCTestCase {

    func test_legalTransition_pendingReviewToApproved() {
        XCTAssertTrue(BookingApprovalStatus.pendingReview.canTransition(to: .approved))
    }

    func test_legalTransition_pendingReviewToAutoApproved() {
        XCTAssertTrue(BookingApprovalStatus.pendingReview.canTransition(to: .autoApproved))
    }

    func test_legalTransition_waitlistedToApproved() {
        XCTAssertTrue(BookingApprovalStatus.waitlisted.canTransition(to: .approved))
    }

    func test_illegalTransition_approvedToPendingReview() {
        XCTAssertFalse(BookingApprovalStatus.approved.canTransition(to: .pendingReview))
    }

    func test_illegalTransition_anyToAutoApproved_exceptPending() {
        for from in BookingApprovalStatus.allCases where from != .pendingReview {
            XCTAssertFalse(from.canTransition(to: .autoApproved),
                          "\(from) → autoApproved should be illegal")
        }
    }

    func test_terminalStates_cannotTransitionOut() {
        let terminals: [BookingApprovalStatus] = [
            .approved, .rejected, .cancelledBySelf, .expired, .autoApproved, .autoConfirmed
        ]
        for from in terminals {
            for to in BookingApprovalStatus.allCases where from != to {
                XCTAssertFalse(from.canTransition(to: to),
                              "\(from) is terminal, cannot go to \(to)")
            }
        }
    }
}
