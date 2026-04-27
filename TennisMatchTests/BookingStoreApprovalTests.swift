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

    func test_approve_transitionsToApproved() {
        let match = MockBuilders.match(hostID: userID)
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: userID)
        store._testInsert(app)

        store.approve(applicationID: app.id, now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first?.status, .approved)
        XCTAssertEqual(store.applications.first?.resolvedBy, userID)
        XCTAssertNotNil(store.applications.first?.resolvedAt)
    }

    func test_reject_transitionsToRejectedWithNote() {
        let match = MockBuilders.match(hostID: userID)
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: userID)
        store._testInsert(app)

        store.reject(applicationID: app.id, note: "水平不匹配", now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first?.status, .rejected)
        XCTAssertEqual(store.applications.first?.note, "水平不匹配")
    }

    func test_cancelApplication_pendingNoCreditPenalty() {
        let match = MockBuilders.match()
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)
        let app = store.myApplication(for: match.id)!

        store.cancelApplication(app.id, now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first?.status, .cancelledBySelf)
        XCTAssertEqual(store.applications.first?.resolvedBy, userID)
    }

    func test_approve_illegalFromTerminal_noop() {
        let match = MockBuilders.match(hostID: userID)
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: userID, status: .approved)
        store._testInsert(app)

        store.approve(applicationID: app.id, now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first?.status, .approved)
    }

    func test_runApprovalDeadlines_autoApprovesPendingWithSlot() {
        let match = MockBuilders.match(maxPlayers: 4, currentPlayers: 1)
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: match.hostID)
        store._testInsert(app)

        let afterDeadline = match.approvalDeadline!.addingTimeInterval(60)
        store.runApprovalDeadlines(now: afterDeadline)

        XCTAssertEqual(store.applications.first?.status, .autoApproved)
    }

    func test_runApprovalDeadlines_waitlistsWhenFull() {
        let match = MockBuilders.match(maxPlayers: 4, currentPlayers: 1)
        store.registerMatch(match)
        for _ in 0..<4 {
            store._testInsert(MockBuilders.application(matchID: match.id, hostID: match.hostID))
        }

        let afterDeadline = match.approvalDeadline!.addingTimeInterval(60)
        store.runApprovalDeadlines(now: afterDeadline)

        let auto = store.applications.filter { $0.status == .autoApproved }
        let wait = store.applications.filter { $0.status == .waitlisted }
        XCTAssertEqual(auto.count, 3)
        XCTAssertEqual(wait.count, 1)
    }

    func test_runApprovalDeadlines_FIFOOrder() {
        let match = MockBuilders.match(maxPlayers: 3, currentPlayers: 1)
        store.registerMatch(match)
        let early = MockBuilders.application(
            matchID: match.id, hostID: match.hostID,
            appliedAt: MockBuilders.fixedNow
        )
        let middle = MockBuilders.application(
            matchID: match.id, hostID: match.hostID,
            appliedAt: MockBuilders.fixedNow.addingTimeInterval(10)
        )
        let late = MockBuilders.application(
            matchID: match.id, hostID: match.hostID,
            appliedAt: MockBuilders.fixedNow.addingTimeInterval(20)
        )
        // Insert in deliberately scrambled order
        store._testInsert(late)
        store._testInsert(early)
        store._testInsert(middle)

        let afterDeadline = match.approvalDeadline!.addingTimeInterval(60)
        store.runApprovalDeadlines(now: afterDeadline)

        XCTAssertEqual(store.applications.first(where: { $0.id == early.id })?.status, .autoApproved)
        XCTAssertEqual(store.applications.first(where: { $0.id == middle.id })?.status, .autoApproved)
        XCTAssertEqual(store.applications.first(where: { $0.id == late.id })?.status, .waitlisted)
    }

    func test_runApprovalDeadlines_expiresWhenMatchPassed() {
        let match = MockBuilders.match()
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: match.hostID)
        store._testInsert(app)

        store.runApprovalDeadlines(now: match.startDate.addingTimeInterval(60))

        XCTAssertEqual(store.applications.first?.status, .expired)
    }

    func test_runApprovalDeadlines_skipsBeforeDeadline() {
        let match = MockBuilders.match()
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: match.hostID)
        store._testInsert(app)

        let beforeDeadline = match.approvalDeadline!.addingTimeInterval(-60)
        store.runApprovalDeadlines(now: beforeDeadline)

        XCTAssertEqual(store.applications.first?.status, .pendingReview)
    }

    func test_runFallbackChecks_debounceWithin2s_skips() {
        let match = MockBuilders.match()
        store.registerMatch(match)
        let app = MockBuilders.application(matchID: match.id, hostID: match.hostID)
        store._testInsert(app)

        let afterDeadline = match.approvalDeadline!.addingTimeInterval(60)
        store.runFallbackChecks(now: afterDeadline)
        // 第一次应通过
        XCTAssertEqual(store.applications.first?.status, .autoApproved)

        // 重置回 pendingReview 模拟新一轮 — 1s 后再调
        store._testSetStatus(.pendingReview, forApplicationID: app.id)
        store.runFallbackChecks(now: afterDeadline.addingTimeInterval(1))
        // 第二次应被去抖跳过 — 状态不动
        XCTAssertEqual(store.applications.first?.status, .pendingReview)

        // 3s 后应放行
        store.runFallbackChecks(now: afterDeadline.addingTimeInterval(3))
        XCTAssertEqual(store.applications.first?.status, .autoApproved)
    }
}
