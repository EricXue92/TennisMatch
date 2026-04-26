//
//  InviteStore.swift
//  TennisMatch
//
//  全局 DM 邀請存儲(in-memory,跨 chat 共享)。每張邀請卡渲染時從這裡拉狀態,
//  接受/拒絕/反悔通過呼叫 setStatus(...) + 對應的 InviteMatchActions closure。
//

import Foundation
import SwiftUI

@Observable
final class InviteStore {
    enum Status: String { case pending, accepted, declined }

    struct Invite: Identifiable, Equatable {
        let id: UUID
        let matchID: UUID
        let inviteeName: String
        let inviteeGender: Gender
        let inviteeNTRP: String
        let payload: OutgoingInvitationPayload
        let startDate: Date
        let endDate: Date
        var status: Status
        var decidedAt: Date?
        let createdAt: Date
    }

    private(set) var invites: [Invite] = []

    /// 加入新邀請。若同一 (matchID, inviteeName) 已有 active(pending/accepted)邀請,
    /// 先把舊的去掉再 append — InvitePickerSheet 已禁用「已報名」,這是兜底防重。
    func add(_ invite: Invite) {
        invites.removeAll { $0.matchID == invite.matchID
                            && $0.inviteeName == invite.inviteeName
                            && $0.status != .declined }
        invites.append(invite)
    }

    func setStatus(_ status: Status, for id: UUID) {
        guard let idx = invites.firstIndex(where: { $0.id == id }) else { return }
        invites[idx].status = status
        invites[idx].decidedAt = (status == .pending) ? nil : Date()
    }

    func invitesForChat(_ name: String) -> [Invite] {
        invites
            .filter { $0.inviteeName == name }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// 整個約球被取消時:把所有 active(pending/accepted)邀請改 declined。
    /// 不在 store 內處理 match 數據回滾,呼叫方自己管 acceptedInvite 的副作用。
    func expireAll(matchID: UUID) {
        for i in invites.indices where invites[i].matchID == matchID
                                    && invites[i].status != .declined {
            invites[i].status = .declined
            invites[i].decidedAt = Date()
        }
    }
}

// MARK: - Display State

enum InviteCardDisplay: Equatable {
    case actionable(hasConflict: Bool, conflictLabel: String?)
    case accepted(at: Date)
    case declined(at: Date)
    case expired(reason: ExpireReason)

    enum ExpireReason: Equatable {
        case full(current: Int, max: Int)
        case cancelled
        case timePassed
    }

    var isDecided: Bool {
        switch self {
        case .accepted, .declined: return true
        default: return false
        }
    }

    var isMuted: Bool {
        switch self {
        case .actionable: return false
        default: return true
        }
    }
}

// MARK: - Match Actions Bridge

/// HomeView 提供給 ChatDetailView 的回調集 — 解耦 chat 與 match state。
struct InviteMatchActions {
    var acceptInvite: (InviteStore.Invite) -> Void
    var undoAcceptInvite: (InviteStore.Invite) -> Void

    static var noop: InviteMatchActions {
        InviteMatchActions(
            acceptInvite: { _ in },
            undoAcceptInvite: { _ in }
        )
    }
}
