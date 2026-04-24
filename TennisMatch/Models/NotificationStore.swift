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

    var icon: String { type.icon }
    var iconBg: Color { type.iconBg }
    var iconColor: Color { type.iconColor }
}

@Observable
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
    static let mockSeed: [MatchNotification] = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd"
        func d(_ offset: Int) -> String {
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { return "01/01" }
            return fmt.string(from: date)
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
