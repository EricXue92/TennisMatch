//
//  MockFriendSchedule.swift
//  TennisMatch
//
//  互關好友的 mock 已有約球檔期 — 模擬「DM 邀請後,被邀好友自己也有時段衝突」場景。
//  僅 demo 用,真實場景由後端查好友日曆。
//

import Foundation

/// 一個已被佔用的時段。`label` 用於婉拒文案,如 "雙打" / "教練課"。
struct FriendBusySlot {
    let start: Date
    let end: Date
    let label: String
}

enum MockFriendSchedule {
    /// 互關好友姓名 → 已佔用時段。未列出的好友視為完全空閒(永遠接受)。
    /// 時段對齊 mockUpcomingMatchesInitial 中已有的時段,讓「邀請該好友到那個時段」
    /// 能穩定觸發婉拒分支,demo 容易演。
    static var busySlots: [String: [FriendBusySlot]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func slot(daysFromNow: Int, startHour: Int, startMinute: Int = 0,
                  endHour: Int, endMinute: Int = 0, label: String) -> FriendBusySlot {
            let day = cal.date(byAdding: .day, value: daysFromNow, to: today) ?? today
            var s = cal.dateComponents([.year, .month, .day], from: day)
            s.hour = startHour; s.minute = startMinute
            var e = s
            e.hour = endHour; e.minute = endMinute
            let start = cal.date(from: s) ?? day
            let end = cal.date(from: e) ?? start.addingTimeInterval(2 * 3600)
            return FriendBusySlot(start: start, end: end, label: label)
        }

        return [
            // 莎拉 — 第 1 天 10:00-12:00 與「莎拉 發起的單打」一致;
            // 如果再邀她 第 1 天 10:00 開始的約球 → 衝突婉拒
            "莎拉":  [slot(daysFromNow: 1, startHour: 10, endHour: 12, label: "單打")],
            // 嘉欣 — 第 -1 天 9:00-11:00(已過期但仍可匹配時段)
            "嘉欣":  [slot(daysFromNow: 6, startHour: 9, endHour: 11, label: "雙打")],
            // 大衛 — 第 4 天 18:30-20:30 與已有約球同
            "大衛":  [slot(daysFromNow: 4, startHour: 18, startMinute: 30, endHour: 20, endMinute: 30, label: "雙打")],
            // 小美 — 第 3 天 14:00-16:00 與「我發起的雙打 跑馬地」一致 → 邀她該場必衝突婉拒
            "小美":  [slot(daysFromNow: 3, startHour: 14, endHour: 16, label: "教練課")],
            // 其餘互關好友視為空閒
        ]
    }

    /// 返回衝突的 slot,nil 表示無衝突。半開區間判斷:`a.start < b.end && b.start < a.end`
    static func conflict(for name: String, start: Date, end: Date) -> FriendBusySlot? {
        guard let slots = busySlots[name] else { return nil }
        return slots.first { slot in
            start < slot.end && slot.start < end
        }
    }
}
