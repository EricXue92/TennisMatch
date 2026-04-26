import Foundation
@testable import TennisMatch

enum MockBuilders {
    static let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)

    static func match(
        startsIn seconds: TimeInterval = 3 * 24 * 3600,
        maxPlayers: Int = 4,
        currentPlayers: Int = 1,
        requiresApproval: Bool = true,
        publishedAt: Date = fixedNow,
        hostID: UUID = UUID()
    ) -> MockMatch {
        let start = publishedAt.addingTimeInterval(seconds)
        var m = MockMatch(
            name: "Host",
            gender: .male,
            matchType: "單打",
            weather: "☀️",
            dateTime: "test",
            startDate: start,
            location: "Court 1",
            fee: "AA",
            ntrpLow: 3.0,
            ntrpHigh: 4.0,
            ageRange: "26-35",
            genderLabel: "不限",
            hour: 10,
            dayOfWeek: "一",
            currentPlayers: currentPlayers,
            maxPlayers: maxPlayers
        )
        m.hostID = hostID
        m.requiresApproval = requiresApproval
        m.approvalDeadline = ApprovalDeadlineCalculator.deadline(
            requiresApproval: requiresApproval,
            publishedAt: publishedAt,
            startDate: start
        )
        return m
    }

    static func application(
        matchID: UUID,
        applicantID: UUID = UUID(),
        hostID: UUID,
        status: BookingApprovalStatus = .pendingReview,
        appliedAt: Date = fixedNow
    ) -> MatchApplication {
        MatchApplication(
            matchID: matchID,
            applicantID: applicantID,
            hostID: hostID,
            status: status,
            appliedAt: appliedAt
        )
    }
}
