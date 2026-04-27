import XCTest
@testable import TennisMatch

@MainActor
final class BookingStoreSoftConflictTests: XCTestCase {

    var store: BookingStore!
    let userID = UUID()

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        store = BookingStore(currentUserID: userID)
    }

    func test_pendingApplication_triggersSoftConflict_notHard() {
        let match = MockBuilders.match(requiresApproval: true)
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)

        let start = match.startDate.addingTimeInterval(60 * 30)   // 与原局重叠
        let end = start.addingTimeInterval(3600)

        XCTAssertNil(store.conflict(start: start, end: end), "pending 不应触发硬冲突")
        XCTAssertNotNil(store.softConflict(start: start, end: end), "pending 应触发软冲突")
    }

    func test_confirmedApplication_triggersHard_notSoft() {
        let match = MockBuilders.match(requiresApproval: false)
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)
        // autoConfirmed 直接占位

        let start = match.startDate.addingTimeInterval(60 * 30)
        let end = start.addingTimeInterval(3600)

        XCTAssertNotNil(store.conflict(start: start, end: end))
        XCTAssertNil(store.softConflict(start: start, end: end))
    }

    func test_softConflict_excludingSelfMatch() {
        let match = MockBuilders.match(requiresApproval: true)
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)

        let start = match.startDate
        let end = start.addingTimeInterval(2 * 3600)

        XCTAssertNil(
            store.softConflict(start: start, end: end, excluding: match.id),
            "查自身 match 不应命中"
        )
    }
}
