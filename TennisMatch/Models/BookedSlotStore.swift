//
//  BookedSlotStore.swift
//  TennisMatch
//
//  跨视图记录"用户已占用的时段",供报名前的时间冲突检测使用。
//
//  Mock 阶段不持久化:重启 app 即清空。接后端时改为从订单/邀请接口拉取。
//  store 不是 booking 的"主真理"(那仍在 signedUpMatchIDs / acceptedMatches 等处),
//  只用于"该时段是否已被占用"的查询;每次 booking / cancel 同步推一份过来。
//

import Foundation
import Observation

// `BookedSlot` 已迁移到 BookingStore.swift(Phase 2b)。
// 本文件保留 `BookedSlotStore` 仅为过渡期兼容,完整删除见 Task 8。

@Observable
@MainActor
final class BookedSlotStore {
    private(set) var slots: [BookedSlot] = []

    /// 同 id 已存在则覆盖,避免重复登记。
    func add(_ slot: BookedSlot) {
        slots.removeAll { $0.id == slot.id }
        slots.append(slot)
    }

    func remove(id: UUID) {
        slots.removeAll { $0.id == id }
    }

    /// 找出与 `[start, end)` 时段重叠的第一条 booked slot。
    /// `excluding` 用于检查"修改/重新登记同一个 booking"时排除自身。
    /// 重叠判定: `s1 < e2 && s2 < e1`。
    func conflict(start: Date, end: Date, excluding: UUID? = nil) -> BookedSlot? {
        slots.first { slot in
            guard slot.id != excluding else { return false }
            return slot.start < end && start < slot.end
        }
    }
}
