import XCTest
@testable import TennisMatch

@MainActor
final class BookingStoreApprovalTests: XCTestCase {

    var store: BookingStore!
    let userID = UUID()

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        store = BookingStore(currentUserID: userID)
    }

    func test_apply_autoConfirmsWhenApprovalNotRequired() {
        let match = MockBuilders.match(requiresApproval: false)
        store.registerMatch(match)

        let app = store.apply(to: match, now: MockBuilders.fixedNow)

        XCTAssertEqual(app.status, .autoConfirmed)
        XCTAssertEqual(store.applications.count, 1)
    }

    func test_apply_pendingReviewWhenApprovalRequired() {
        let match = MockBuilders.match(requiresApproval: true)
        store.registerMatch(match)

        let app = store.apply(to: match, now: MockBuilders.fixedNow)

        XCTAssertEqual(app.status, .pendingReview)
    }

    func test_apply_rejectsDuplicateApplication() {
        let match = MockBuilders.match(requiresApproval: true)
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)

        let dup = store.apply(to: match, now: MockBuilders.fixedNow)

        XCTAssertEqual(dup.status, .pendingReview, "重复申请应返回现有条目")
        XCTAssertEqual(store.applications.count, 1, "不应新增")
    }
}
