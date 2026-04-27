import XCTest
@testable import TennisMatch

@MainActor
final class BookingStoreWaitlistTests: XCTestCase {

    var store: BookingStore!
    let userID = UUID()

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        store = BookingStore(currentUserID: userID)
    }

    func test_promoteWaitlist_promotesOnReject() {
        let match = MockBuilders.match(maxPlayers: 3, currentPlayers: 1, hostID: userID)
        store.registerMatch(match)
        let approved = MockBuilders.application(matchID: match.id, hostID: userID, status: .approved)
        let waiter = MockBuilders.application(matchID: match.id, hostID: userID, status: .waitlisted)
        store._testInsert(approved)
        store._testInsert(waiter)

        store.reject(applicationID: approved.id, note: nil, now: MockBuilders.fixedNow)
        store.promoteWaitlist(now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first { $0.id == waiter.id }?.status, .approved)
    }

    func test_promoteWaitlist_promotesOnCancel() {
        let match = MockBuilders.match(maxPlayers: 3, currentPlayers: 1)
        store.registerMatch(match)
        let mine = MatchApplication(
            matchID: match.id, applicantID: userID, hostID: match.hostID,
            status: .approved, appliedAt: MockBuilders.fixedNow
        )
        let waiter = MockBuilders.application(matchID: match.id, hostID: match.hostID, status: .waitlisted)
        store._testInsert(mine)
        store._testInsert(waiter)

        store.cancelApplication(mine.id, now: MockBuilders.fixedNow)
        store.promoteWaitlist(now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first { $0.id == waiter.id }?.status, .approved)
    }

    func test_promoteWaitlist_promotesByFIFO() {
        let match = MockBuilders.match(maxPlayers: 4, currentPlayers: 1, hostID: userID)
        store.registerMatch(match)
        let earlyWait = MockBuilders.application(
            matchID: match.id, hostID: userID, status: .waitlisted,
            appliedAt: MockBuilders.fixedNow
        )
        let lateWait = MockBuilders.application(
            matchID: match.id, hostID: userID, status: .waitlisted,
            appliedAt: MockBuilders.fixedNow.addingTimeInterval(10)
        )
        store._testInsert(lateWait)
        store._testInsert(earlyWait)

        store.promoteWaitlist(now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first { $0.id == earlyWait.id }?.status, .approved)
        XCTAssertEqual(store.applications.first { $0.id == lateWait.id }?.status, .approved)
    }

    func test_promoteWaitlist_doesNotPromoteWhenFull() {
        let match = MockBuilders.match(maxPlayers: 3, currentPlayers: 1, hostID: userID)
        store.registerMatch(match)
        let a1 = MockBuilders.application(matchID: match.id, hostID: userID, status: .approved)
        let a2 = MockBuilders.application(matchID: match.id, hostID: userID, status: .approved)
        let waiter = MockBuilders.application(matchID: match.id, hostID: userID, status: .waitlisted)
        store._testInsert(a1)
        store._testInsert(a2)
        store._testInsert(waiter)

        store.promoteWaitlist(now: MockBuilders.fixedNow)

        XCTAssertEqual(store.applications.first { $0.id == waiter.id }?.status, .waitlisted)
    }
}
