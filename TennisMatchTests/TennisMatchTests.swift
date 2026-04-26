import XCTest
@testable import TennisMatch

final class TennisMatchTests: XCTestCase {
    func test_smoke_targetCompiles() {
        XCTAssertTrue(true)
    }
}

extension TennisMatchTests {
    @MainActor
    func test_userStore_hasStableID() {
        let key = "userStore.id"
        UserDefaults.standard.removeObject(forKey: key)

        let s1 = UserStore()
        let id1 = s1.id

        let s2 = UserStore()
        let id2 = s2.id

        XCTAssertEqual(id1, id2, "id 应在 init 间稳定(从 UserDefaults 读)")
    }
}
