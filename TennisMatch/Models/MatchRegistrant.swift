import Foundation

/// 球局中的报名/参与者。后端友好建模:`id: UUID` 用于 `MatchApplication.applicantID` 引用。
struct MatchRegistrant: Identifiable, Hashable {
    let id: UUID
    let name: String
    let gender: Gender
    let ntrp: String
    let isOrganizer: Bool

    init(
        id: UUID = UUID(),
        name: String,
        gender: Gender,
        ntrp: String,
        isOrganizer: Bool
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.ntrp = ntrp
        self.isOrganizer = isOrganizer
    }
}
