//
//  TournamentStore.swift
//  TennisMatch
//
//  共享的賽事狀態 — 取代之前 TournamentView 中的 local @State,
//  讓 MyMatchesView 與 TournamentView 能共用同一份資料。
//

import Foundation

@Observable
@MainActor
final class TournamentStore {
    var tournaments: [MockTournament]
    /// 我已報名的「別人發起」賽事 ID。自己發起的看 `MockTournament.isOwnTournament`。
    private(set) var joinedIDs: Set<UUID> = []

    init(initial: [MockTournament] = mockTournaments) {
        self.tournaments = initial
    }

    // MARK: - 報名 / 取消

    func signUp(id: UUID) {
        joinedIDs.insert(id)
    }

    func cancelSignUp(id: UUID) {
        joinedIDs.remove(id)
    }

    func isJoined(id: UUID) -> Bool {
        joinedIDs.contains(id)
    }

    /// 我有「參與關係」的賽事 — 自己發起 + 我已報名。冲突检测的扫描源。
    var myTournaments: [MockTournament] {
        tournaments.filter { $0.isOwnTournament || joinedIDs.contains($0.id) }
    }

    // MARK: - 衝突檢測

    struct ConflictHit {
        let id: UUID
        let label: String
    }

    /// 區間 `[start, end)` 是否與我參與的賽事日程重疊。
    /// 重疊判定:`s1 < e2 && s2 < e1`(與 BookingStore 一致)。
    /// `excluding`:重新登記同一賽事時排除自身。
    func conflict(start: Date, end: Date, excluding: UUID? = nil) -> ConflictHit? {
        for t in myTournaments where t.id != excluding {
            guard let range = CalendarService.parseTournamentRange(t.dateRange) else { continue }
            if range.start < end && start < range.end {
                return ConflictHit(id: t.id, label: t.name)
            }
        }
        return nil
    }

    /// 加入一場新發布的賽事 — 當前用戶為發起人。
    func addPublished(
        info: PublishedTournamentInfo,
        organizerName: String,
        organizerGender: Gender
    ) {
        let dateRange = "\(AppDateFormatter.yearMonthDay.string(from: info.startDate)) - \(AppDateFormatter.yearMonthDay.string(from: info.endDate))"

        let tournament = MockTournament(
            name: info.name.isEmpty ? "我的賽事" : info.name,
            format: info.format,
            matchType: info.matchType,
            ntrpRange: info.level,
            status: "報名中",
            dateRange: dateRange,
            location: info.courtName.isEmpty ? "待定" : info.courtName,
            participants: "0/\(info.participantCount.isEmpty ? "16" : info.participantCount)",
            fee: info.fee.isEmpty ? "免費" : "\(info.fee) 港幣",
            organizer: organizerName,
            organizerGender: organizerGender,
            gradientColors: [Theme.gradGreenLight, Theme.primary],
            rules: info.rules.isEmpty ? [] : [info.rules],
            playerList: [],
            isOwnTournament: true
        )
        tournaments.insert(tournament, at: 0)
    }

    /// 取消賽事 — 從列表中移除。副作用(通知 / toast)由呼叫方處理。
    func cancel(id: UUID) {
        tournaments.removeAll { $0.id == id }
    }
}
