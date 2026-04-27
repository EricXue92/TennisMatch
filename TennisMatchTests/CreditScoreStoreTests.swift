import XCTest
@testable import TennisMatch

@MainActor
final class CreditScoreStoreTests: XCTestCase {

    var store: CreditScoreStore!

    override func setUp() async throws {
        store = CreditScoreStore(score: 80, entries: [])
    }

    func test_recordCancellation_pendingTiers_unchanged() {
        XCTAssertEqual(store.recordCancellation(hoursBeforeStart: 30, detail: "x"), 0)
        XCTAssertEqual(store.score, 80)

        XCTAssertEqual(store.recordCancellation(hoursBeforeStart: 10, detail: "x"), 1)
        XCTAssertEqual(store.score, 79)

        XCTAssertEqual(store.recordCancellation(hoursBeforeStart: 1, detail: "x"), 2)
        XCTAssertEqual(store.score, 77)
    }

    func test_recordConfirmedCancellation_under4h_minus4() {
        let deduction = store.recordConfirmedCancellation(hoursBeforeStart: 3, detail: "x")
        XCTAssertEqual(deduction, 4)
        XCTAssertEqual(store.score, 76)
        XCTAssertEqual(store.entries.first?.reason, "確認後取消")
    }

    func test_recordConfirmedCancellation_4hOrMore_noPenalty() {
        let deduction = store.recordConfirmedCancellation(hoursBeforeStart: 4, detail: "x")
        XCTAssertEqual(deduction, 0)
        XCTAssertEqual(store.score, 80)
    }

    func test_recordNoShow_minus5() {
        store.recordNoShow(detail: "x")
        XCTAssertEqual(store.score, 75)
        XCTAssertEqual(store.entries.first?.delta, -5)
    }

    func test_canPublishMatch_thresholds() {
        let s70 = CreditScoreStore(score: 70, entries: [])
        XCTAssertTrue(s70.canPublishMatch, "= 70 仍可发起")

        let s69 = CreditScoreStore(score: 69, entries: [])
        XCTAssertFalse(s69.canPublishMatch, "< 70 不能发起")
    }

    func test_isBanned_below60() {
        let s60 = CreditScoreStore(score: 60, entries: [])
        XCTAssertFalse(s60.isBanned)

        let s59 = CreditScoreStore(score: 59, entries: [])
        XCTAssertTrue(s59.isBanned)
    }
}
