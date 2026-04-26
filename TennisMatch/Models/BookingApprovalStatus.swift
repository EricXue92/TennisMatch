import Foundation

/// 报名条目的审核状态。独立于 `MyMatchStatus`(后者是球局自身的满员状态)。
enum BookingApprovalStatus: String, Codable, CaseIterable {
    case autoConfirmed     // 球局未开审核,直接确认(默认行为)
    case pendingReview     // 已申请,等发起人审核
    case approved          // 审核通过,占名额
    case rejected          // 被拒(host 主动 / 满员转拒)
    case waitlisted        // 满员被挤到候补
    case cancelledBySelf   // 报名者主动撤回
    case autoApproved      // 超时兜底自动接受
    case expired           // 球局已过期,从未审核

    /// 该状态是否允许迁出。
    var isTerminal: Bool {
        switch self {
        case .approved, .rejected, .cancelledBySelf, .expired, .autoApproved, .autoConfirmed:
            return true
        case .pendingReview, .waitlisted:
            return false
        }
    }

    /// 是否合法转换到 `to`。
    func canTransition(to: BookingApprovalStatus) -> Bool {
        guard !isTerminal else { return false }
        switch (self, to) {
        case (.pendingReview, .approved),
             (.pendingReview, .rejected),
             (.pendingReview, .waitlisted),
             (.pendingReview, .autoApproved),
             (.pendingReview, .cancelledBySelf),
             (.pendingReview, .expired):
            return true
        case (.waitlisted, .approved),
             (.waitlisted, .cancelledBySelf),
             (.waitlisted, .expired):
            return true
        default:
            return false
        }
    }
}
