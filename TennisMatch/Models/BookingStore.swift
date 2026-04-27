//
//  BookingStore.swift
//  TennisMatch
//
//  Phase 2c: applications 作为唯一来源,替代旧 accepted[]/signedUpMatchIDs。
//  保留 externalSlots(mock 阶段的"已占用但不在 applications 里"的时段)。
//

import Foundation
import Observation

struct BookedSlot: Identifiable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    let label: String
}

enum SignUpResult: Equatable {
    case ok
    case alreadySignedUp
    case conflict(label: String)
}

enum AcceptResult: Equatable {
    case ok
    case conflict(label: String)
}

struct ConflictHit: Equatable {
    let id: UUID
    let label: String
}

@Observable
@MainActor
final class BookingStore {
    private static let applicationsKey = "bookingStore.applications"
    private static let debounceInterval: TimeInterval = 2.0

    private let currentUserID: UUID

    /// 唯一来源。所有 view 派生消费。
    private(set) var applications: [MatchApplication] = []

    /// MockMatch 索引(运行时注入,不持久化 — match data 由 view 拥有)。
    private var matches: [UUID: MockMatch] = [:]

    /// mock 阶段的"外部占用时段"。
    private(set) var externalSlots: [BookedSlot] = []

    private var lastFallbackRunAt: Date = .distantPast

    init(currentUserID: UUID) {
        self.currentUserID = currentUserID
        loadApplications()
    }

    // MARK: - Match registry

    func registerMatch(_ match: MockMatch) {
        matches[match.id] = match
    }

    func unregisterMatch(_ matchID: UUID) {
        matches.removeValue(forKey: matchID)
    }

    // MARK: - Apply

    @discardableResult
    func apply(to match: MockMatch, now: Date = .now) -> MatchApplication {
        registerMatch(match)
        if let existing = myApplication(for: match.id) {
            return existing
        }
        let initial: BookingApprovalStatus = match.requiresApproval ? .pendingReview : .autoConfirmed
        let app = MatchApplication(
            matchID: match.id,
            applicantID: currentUserID,
            hostID: match.hostID,
            status: initial,
            appliedAt: now
        )
        applications.append(app)
        persist()
        return app
    }

    // MARK: - Host actions

    func approve(applicationID: UUID, now: Date = .now) {
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        guard applications[idx].status.canTransition(to: .approved) else { return }
        applications[idx].status = .approved
        applications[idx].resolvedAt = now
        applications[idx].resolvedBy = currentUserID
        persist()
    }

    func reject(applicationID: UUID, note: String? = nil, now: Date = .now) {
        guard let idx = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        guard applications[idx].status.canTransition(to: .rejected) else { return }
        applications[idx].status = .rejected
        applications[idx].resolvedAt = now
        applications[idx].resolvedBy = currentUserID
        applications[idx].note = note
        promoteWaitlist(now: now)
        persist()
    }

    // MARK: - Applicant actions

    func cancelApplication(_ id: UUID, now: Date = .now) {
        guard let idx = applications.firstIndex(where: { $0.id == id }) else { return }
        guard applications[idx].status.canTransition(to: .cancelledBySelf) else { return }
        applications[idx].status = .cancelledBySelf
        applications[idx].resolvedAt = now
        applications[idx].resolvedBy = currentUserID
        promoteWaitlist(now: now)
        persist()
    }

    // MARK: - Queries

    func myApplication(for matchID: UUID) -> MatchApplication? {
        applications.first(where: { $0.matchID == matchID && $0.applicantID == currentUserID })
    }

    func incomingApplications(for matchID: UUID) -> [MatchApplication] {
        applications
            .filter { $0.matchID == matchID && $0.applicantID != currentUserID }
            .sorted { $0.appliedAt < $1.appliedAt }
    }

    var myApprovedMatches: [UUID] {
        applications
            .filter { $0.applicantID == currentUserID && Self.occupiesSlot($0.status) }
            .map(\.matchID)
    }

    func isSignedUp(matchID: UUID) -> Bool {
        myApprovedMatches.contains(matchID) ||
            applications.contains(where: {
                $0.matchID == matchID && $0.applicantID == currentUserID && $0.status == .pendingReview
            })
    }

    // MARK: - External slots

    func registerExternal(_ slot: BookedSlot) {
        externalSlots.removeAll { $0.id == slot.id }
        externalSlots.append(slot)
    }

    func removeExternal(id: UUID) {
        externalSlots.removeAll { $0.id == id }
    }

    // MARK: - Conflict

    func conflict(start: Date, end: Date, excluding: UUID? = nil) -> ConflictHit? {
        for app in applications where app.applicantID == currentUserID && Self.occupiesSlot(app.status) {
            guard app.matchID != excluding,
                  let m = matches[app.matchID] else { continue }
            let mEnd = m.startDate.addingTimeInterval(2 * 3600)
            if m.startDate < end && start < mEnd {
                return ConflictHit(id: app.matchID, label: "\(m.name) \(m.dateTimeDisplay)")
            }
        }
        for s in externalSlots where s.id != excluding && s.start < end && start < s.end {
            return ConflictHit(id: s.id, label: s.label)
        }
        return nil
    }

    // MARK: - Fallback: deadline scan

    func runApprovalDeadlines(now: Date = .now) {
        let pendingSorted = applications
            .enumerated()
            .filter { $0.element.status == .pendingReview }
            .sorted { $0.element.appliedAt < $1.element.appliedAt }

        // 单 match 局部计数缓存(避免遍历过程中 approvedCount 抖动)
        var localApproved: [UUID: Int] = [:]

        for (idx, app) in pendingSorted {
            guard let match = matches[app.matchID] else { continue }
            guard let deadline = match.approvalDeadline, now >= deadline else { continue }

            if match.startDate < now {
                applications[idx].status = .expired
                applications[idx].resolvedAt = now
                applications[idx].resolvedBy = nil
                continue
            }

            let count = localApproved[match.id] ?? approvedCount(for: match.id)
            let cap = max(0, match.maxPlayers - 1)   // 减去 host 自己
            if count < cap {
                applications[idx].status = .autoApproved
                applications[idx].resolvedAt = now
                applications[idx].resolvedBy = nil
                localApproved[match.id] = count + 1
            } else {
                applications[idx].status = .waitlisted
                applications[idx].resolvedAt = now
                applications[idx].resolvedBy = nil
            }
        }
        persist()
    }

    // MARK: - Fallback: waitlist promotion

    func promoteWaitlist(now: Date = .now) {
        let matchIDs = Set(applications.compactMap {
            $0.status == .waitlisted ? $0.matchID : nil
        })
        for matchID in matchIDs {
            guard let match = matches[matchID], match.startDate >= now else { continue }
            let cap = max(0, match.maxPlayers - 1)
            let approvedNow = approvedCount(for: matchID)
            let slots = cap - approvedNow
            guard slots > 0 else { continue }

            let queueIdx = applications
                .enumerated()
                .filter { $0.element.matchID == matchID && $0.element.status == .waitlisted }
                .sorted { $0.element.appliedAt < $1.element.appliedAt }
                .prefix(slots)
                .map { $0.offset }

            for idx in queueIdx {
                applications[idx].status = .approved
                applications[idx].resolvedAt = now
                applications[idx].resolvedBy = nil
            }
        }
        persist()
    }

    // MARK: - Helpers

    static func occupiesSlot(_ status: BookingApprovalStatus) -> Bool {
        switch status {
        case .approved, .autoApproved, .autoConfirmed: return true
        default: return false
        }
    }

    /// 该 match 已占用名额数(不含 host 自己)。
    func approvedCount(for matchID: UUID) -> Int {
        applications.filter { $0.matchID == matchID && Self.occupiesSlot($0.status) }.count
    }

    // MARK: - Persistence

    private func loadApplications() {
        guard let data = UserDefaults.standard.data(forKey: Self.applicationsKey),
              let decoded = try? JSONDecoder().decode([MatchApplication].self, from: data) else {
            return
        }
        applications = decoded
    }

    fileprivate func persist() {
        guard let data = try? JSONEncoder().encode(applications) else { return }
        UserDefaults.standard.set(data, forKey: Self.applicationsKey)
    }

    /// 临时供旧 view 读取的「已加入」聚合视图。Phase D 完成后 view 改读 applications,该方法可删。
    func legacyAcceptedSnapshot() -> [MatchApplication] {
        applications.filter { $0.applicantID == currentUserID && Self.occupiesSlot($0.status) }
    }
}

// MARK: - Legacy compat (Phase D 内逐步移除)

extension BookingStore {
    /// Deprecated wrapper — Phase D 完成后删。仅供未迁移的 view 临时编译。
    @available(*, deprecated, message: "Use apply(to:) instead. Phase D 内迁移。")
    @discardableResult
    func signUp(matchID: UUID, info: AcceptedMatchInfo) -> SignUpResult {
        let host = matches[matchID]?.hostID ?? UUID()
        let initial: BookingApprovalStatus = matches[matchID]?.requiresApproval == true
            ? .pendingReview : .autoConfirmed
        if applications.contains(where: { $0.matchID == matchID && $0.applicantID == currentUserID }) {
            return .alreadySignedUp
        }
        if let hit = conflict(start: info.startDate, end: info.endDate, excluding: matchID) {
            return .conflict(label: hit.label)
        }
        applications.append(MatchApplication(
            matchID: matchID, applicantID: currentUserID, hostID: host,
            status: initial, appliedAt: .now
        ))
        persist()
        return .ok
    }

    @available(*, deprecated, message: "Use apply(to:) for invitations. Phase D 内迁移。")
    @discardableResult
    func acceptInvitation(_ info: AcceptedMatchInfo) -> AcceptResult {
        if let hit = conflict(start: info.startDate, end: info.endDate) {
            return .conflict(label: hit.label)
        }
        let mid = info.sourceMatchID ?? UUID()
        applications.append(MatchApplication(
            matchID: mid, applicantID: currentUserID, hostID: UUID(),
            status: .autoConfirmed, appliedAt: .now
        ))
        persist()
        return .ok
    }

    @available(*, deprecated, message: "Use cancelApplication(_:) instead. Phase D 内迁移。")
    @discardableResult
    func cancel(acceptedID: UUID) -> AcceptedMatchInfo? {
        guard let idx = applications.firstIndex(where: { $0.id == acceptedID }) else { return nil }
        let removed = applications.remove(at: idx)
        persist()
        guard let m = matches[removed.matchID] else { return nil }
        // NOTE: AcceptedMatchInfo has fixed `let id = UUID()` and required matchType.
        var info = AcceptedMatchInfo(
            organizerName: m.name,
            matchType: m.matchType,
            dateString: AppDateFormatter.monthDay.string(from: m.startDate),
            time: AppDateFormatter.hourMinute.string(from: m.startDate),
            location: m.location,
            startDate: m.startDate,
            endDate: m.startDate.addingTimeInterval(2*3600)
        )
        info.sourceMatchID = removed.matchID
        return info
    }

    /// Deprecated 派生:旧 view 仍读 `accepted` 数组。Phase D 完成后删。
    @available(*, deprecated, message: "派生自 applications。Phase D 内迁移到 applications 直读。")
    var accepted: [AcceptedMatchInfo] {
        legacyAcceptedSnapshot().compactMap { app in
            guard let m = matches[app.matchID] else { return nil }
            var info = AcceptedMatchInfo(
                organizerName: m.name,
                matchType: m.matchType,
                dateString: AppDateFormatter.monthDay.string(from: m.startDate),
                time: AppDateFormatter.hourMinute.string(from: m.startDate),
                location: m.location,
                startDate: m.startDate,
                endDate: m.startDate.addingTimeInterval(2*3600)
            )
            info.sourceMatchID = app.matchID
            return info
        }
    }

    @available(*, deprecated, message: "Use myApprovedMatches 或 isSignedUp(matchID:)")
    var signedUpMatchIDs: Set<UUID> { Set(myApprovedMatches) }
}

// MARK: - Test seams

#if DEBUG
extension BookingStore {
    /// 仅供单元测试插入 MatchApplication。生产代码勿用。
    func _testInsert(_ app: MatchApplication) {
        applications.append(app)
        persist()
    }
}
#endif
