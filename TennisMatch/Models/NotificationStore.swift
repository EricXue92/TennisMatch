//
//  NotificationStore.swift
//  TennisMatch
//
//  Cross-view notification feed. Seeded with mock entries so NotificationsView
//  has content on first launch, and exposed via @Environment so other surfaces
//  (organizer cancel, sign-up confirm…) can push new notifications without
//  reaching into NotificationsView's private state.
//
//  Mock 阶段不持久化:重启 app 即清空。接后端时换成"拉取通知列表 + 服务端推送"。
//

import Foundation
import Observation
import SwiftUI

/// Phase E: 业务事件 kind(后端字段一致)。与 `NotificationType`(图标/颜色)分离 —
/// 同一个 kind 在 UI 上仍用 NotificationType 渲染。新通知必填,旧 mock seed 可省。
enum NotificationKind: String, Codable {
    case applicationReceived       // host: 有人报名了
    case approvalDeadlineSoon      // host: 你还没处理,2h 后自动通过
    case applicationAutoApproved   // applicant: 自动通过了
    case applicationRejected       // applicant: 被拒了
    case waitlistedToApproved      // applicant: 候补递补成功
    case applicationExpired        // applicant: 球局过期未处理
}

enum NotificationType {
    case signUp, accepted, cancelled, updated

    var icon: String {
        switch self {
        case .signUp: return "person.badge.plus"
        case .accepted: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .updated: return "arrow.triangle.2.circlepath"
        }
    }

    var iconBg: Color {
        switch self {
        case .signUp: return Theme.primaryLight
        case .accepted: return Theme.confirmedBg
        case .cancelled: return Theme.requiredBg
        case .updated: return Theme.pendingBg
        }
    }

    var iconColor: Color {
        switch self {
        case .signUp: return Theme.primary
        case .accepted: return Theme.primary
        case .cancelled: return Theme.requiredText
        case .updated: return Theme.pendingBadge
        }
    }
}

struct MatchNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let body: String
    /// 人类可读的相对时间(`"剛剛"`, `"10 分鐘前"`, `"昨天"`)。
    /// Mock 阶段直接传字符串;接后端时换成 timestamp + 渲染时格式化。
    let time: String
    var isRead: Bool
    /// Phase E: 业务事件 kind(用于后端字段对齐 + 行为路由)。旧 mock seed 不带。
    var kind: NotificationKind? = nil
    /// Phase E: 同 key + 未读 时,`upsert` 会覆盖现有条目,避免「N 人报名」连续刷屏。
    /// 命名约定:`received-{matchID}`、`auto-{matchID}-{applicantID}` 等。
    var coalesceKey: String? = nil

    var icon: String { type.icon }
    var iconBg: Color { type.iconBg }
    var iconColor: Color { type.iconColor }
}

@Observable
@MainActor
final class NotificationStore {
    private(set) var notifications: [MatchNotification]

    init(notifications: [MatchNotification] = NotificationStore.mockSeed) {
        self.notifications = notifications
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    /// 新通知插入到最前面,便于按时间倒序展示。
    func push(_ notification: MatchNotification) {
        notifications.insert(notification, at: 0)
    }

    /// Phase E:同 `coalesceKey` + 未读 时覆盖现有条目,否则 push。
    /// 用例:host 在短时间内收到「A 报名」「B 报名」「C 报名」,合并成最新一条,
    /// 避免红点 / 列表被同类事件刷屏。读过的旧条目保持不变(历史可见)。
    func upsert(_ notification: MatchNotification) {
        if let key = notification.coalesceKey,
           let idx = notifications.firstIndex(where: {
               $0.coalesceKey == key && !$0.isRead
           }) {
            notifications[idx] = notification
        } else {
            notifications.insert(notification, at: 0)
        }
    }

    /// Phase E:把 `coalesceKey` 匹配的所有通知标为已读。
    /// host 进入 MatchDetailView 时调用 — 走过一次审核区块即视为「看过这批申请」。
    func markSeen(coalesceKey: String) {
        for i in notifications.indices where notifications[i].coalesceKey == coalesceKey {
            notifications[i].isRead = true
        }
    }

    func markAllRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
    }

    func markRead(id: UUID) {
        guard let idx = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[idx].isRead = true
    }

    /// 与原 NotificationsView 中 mock 数据等价,统一在 store 内维护。
    /// 日期使用相對計算，確保 mock 數據永不過期。
    nonisolated static let mockSeed: [MatchNotification] = {
        func d(_ offset: Int) -> String {
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { return "01/01" }
            return AppDateFormatter.monthDay.string(from: date)
        }
        return [
            MatchNotification(type: .signUp, title: "新的報名", body: "王強 報名了你發起的雙打約球（\(d(0)) 跑馬地）", time: "10 分鐘前", isRead: false),
            MatchNotification(type: .accepted, title: "報名已接受", body: "你報名的莎拉單打約球（\(d(-1)) 維多利亞公園）已確認", time: "2 小時前", isRead: false),
            MatchNotification(type: .updated, title: "約球更新", body: "志明 的單打約球時間更改為 16:30", time: "3 小時前", isRead: true),
            MatchNotification(type: .cancelled, title: "約球取消", body: "小美 取消了雙打約球（\(d(-2)) 沙田公園）", time: "昨天", isRead: true),
            MatchNotification(type: .signUp, title: "新的報名", body: "嘉欣 報名了你發起的雙打約球（\(d(0)) 跑馬地）", time: "昨天", isRead: true),
            MatchNotification(type: .accepted, title: "報名已接受", body: "你報名的 Michael 單打約球（\(d(4)) 跑馬地）已確認", time: "2 天前", isRead: true),
            MatchNotification(type: .signUp, title: "新的報名", body: "阿豪 報名了你發起的雙打約球（\(d(1)) 將軍澳）", time: "2 天前", isRead: true),
            MatchNotification(type: .updated, title: "約球更新", body: "大衛 的雙打約球地點更改為歌和老街公園", time: "3 天前", isRead: true),
            MatchNotification(type: .cancelled, title: "約球取消", body: "麗莎 取消了雙打約球（\(d(-1)) 香港網球中心）", time: "3 天前", isRead: true),
            MatchNotification(type: .signUp, title: "新的報名", body: "思慧 報名了你發起的單打約球（\(d(6)) 將軍澳）", time: "4 天前", isRead: true),
        ]
    }()
}
