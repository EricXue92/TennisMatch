//
//  BookingStore.swift
//  TennisMatch
//
//  Phase 2b: 集中管理"用户已确认/报名/外部占用"的预定状态。
//  替代旧的 BookedSlotStore + HomeView.acceptedMatches + signedUpMatchIDs 三处分散状态。
//
//  - accepted:          用户已加入"我的约球"的条目(报名 + 接受邀请)。
//  - signedUpMatchIDs:  从 accepted.sourceMatchID 派生的 O(1) 镜像,持久化到 UserDefaults。
//  - externalSlots:     mock 阶段用来注入"已占用但不在 accepted 里"的时段(例如示例数据)。
//  接后端时:externalSlots 由订单/邀请接口拉取,不再 mock 注入。
//

import Foundation
import Observation

/// 跨视图记录"已被占用的时段"。`BookingStore` 内部消费,外部少量直接构造(mock seed)。
struct BookedSlot: Identifiable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    /// 冲突 toast 用的人类可读描述,如 `"莎拉 04/19 10:00"`。
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
    private static let signedUpKey = "signedUpMatchIDs"

    /// 用户已确认参加的所有约球(报名 + 接受邀请)。
    private(set) var accepted: [AcceptedMatchInfo] = []

    /// `accepted` 中由"报名 MockMatch"产生的条目 → 其 sourceMatchID 集合。
    /// 用于首页显示"已报名"徽标的 O(1) 查询。
    private(set) var signedUpMatchIDs: Set<UUID> = []

    /// mock 阶段的"外部占用时段"(示例邀请、示例 booking)。
    /// 真实业务中由后端拉取,不会从 UI 主动 add。
    private(set) var externalSlots: [BookedSlot] = []

    init() {
        loadSignedUp()
    }

    // MARK: - Sign up flow (报名 MockMatch)

    /// 报名一个 MockMatch。返回结果由调用方展示 toast / 跳转。
    @discardableResult
    func signUp(matchID: UUID, info: AcceptedMatchInfo) -> SignUpResult {
        if signedUpMatchIDs.contains(matchID) { return .alreadySignedUp }
        if let hit = conflict(start: info.startDate, end: info.endDate, excluding: matchID) {
            return .conflict(label: hit.label)
        }
        accepted.append(info)
        signedUpMatchIDs.insert(matchID)
        persistSignedUp()
        return .ok
    }

    // MARK: - Invitation flow (接受邀请)

    /// 接受邀请。`info.sourceMatchID` 通常为 nil(邀请没有 MockMatch 对应)。
    @discardableResult
    func acceptInvitation(_ info: AcceptedMatchInfo) -> AcceptResult {
        if let hit = conflict(start: info.startDate, end: info.endDate) {
            return .conflict(label: hit.label)
        }
        accepted.append(info)
        if let src = info.sourceMatchID {
            signedUpMatchIDs.insert(src)
            persistSignedUp()
        }
        return .ok
    }

    // MARK: - Cancel

    /// 取消一个 accepted 条目。返回被移除的条目(供撤销 / 业务后续处理)。
    @discardableResult
    func cancel(acceptedID: UUID) -> AcceptedMatchInfo? {
        guard let idx = accepted.firstIndex(where: { $0.id == acceptedID }) else { return nil }
        let removed = accepted.remove(at: idx)
        if let src = removed.sourceMatchID {
            signedUpMatchIDs.remove(src)
            persistSignedUp()
        }
        return removed
    }

    // MARK: - External slots (mock seed only)

    /// 同 id 已存在则覆盖,避免重复登记。
    func registerExternal(_ slot: BookedSlot) {
        externalSlots.removeAll { $0.id == slot.id }
        externalSlots.append(slot)
    }

    func removeExternal(id: UUID) {
        externalSlots.removeAll { $0.id == id }
    }

    // MARK: - Queries

    func isSignedUp(matchID: UUID) -> Bool {
        signedUpMatchIDs.contains(matchID)
    }

    /// 与 `[start, end)` 重叠的第一条占用(优先 accepted,再看 externalSlots)。
    /// `excluding`:重新登记同一 booking 时排除自身 — 既匹配 accepted.id / sourceMatchID,也匹配 externalSlots.id。
    /// 重叠判定: `s1 < e2 && s2 < e1`。
    func conflict(start: Date, end: Date, excluding: UUID? = nil) -> ConflictHit? {
        if let m = accepted.first(where: { info in
            info.id != excluding && info.sourceMatchID != excluding
                && info.startDate < end && start < info.endDate
        }) {
            return ConflictHit(id: m.id, label: m.conflictLabel)
        }
        if let s = externalSlots.first(where: { slot in
            slot.id != excluding && slot.start < end && start < slot.end
        }) {
            return ConflictHit(id: s.id, label: s.label)
        }
        return nil
    }

    // MARK: - Persistence

    private func loadSignedUp() {
        guard let data = UserDefaults.standard.data(forKey: Self.signedUpKey),
              let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            return
        }
        signedUpMatchIDs = ids
    }

    private func persistSignedUp() {
        guard let data = try? JSONEncoder().encode(signedUpMatchIDs) else { return }
        UserDefaults.standard.set(data, forKey: Self.signedUpKey)
    }
}

private extension AcceptedMatchInfo {
    /// 冲突 toast 用的简短标签。复用 AcceptedMatchInfo 已有的展示字段,与旧 BookedSlot.label 同形式:`"organizer dateString time"`。
    var conflictLabel: String {
        "\(organizerName) \(dateString) \(time)"
    }
}
