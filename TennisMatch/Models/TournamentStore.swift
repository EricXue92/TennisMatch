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

    init(initial: [MockTournament] = mockTournaments) {
        self.tournaments = initial
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
