import Foundation

/// 报名申请条目。后端友好建模 — 字段命名直接对齐 REST schema。
/// `POST /api/applications` 的 body 就是这个结构。
struct MatchApplication: Identifiable, Codable, Hashable {
    let id: UUID
    let matchID: UUID
    let applicantID: UUID
    let hostID: UUID            // 冗余,便于查询
    var status: BookingApprovalStatus
    let appliedAt: Date
    var resolvedAt: Date?
    var resolvedBy: UUID?       // host 接受 = hostID;系统兜底 = nil;自撤 = applicantID
    var note: String?           // host 拒绝时的可选理由

    init(
        id: UUID = UUID(),
        matchID: UUID,
        applicantID: UUID,
        hostID: UUID,
        status: BookingApprovalStatus,
        appliedAt: Date = .now,
        resolvedAt: Date? = nil,
        resolvedBy: UUID? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.matchID = matchID
        self.applicantID = applicantID
        self.hostID = hostID
        self.status = status
        self.appliedAt = appliedAt
        self.resolvedAt = resolvedAt
        self.resolvedBy = resolvedBy
        self.note = note
    }
}
