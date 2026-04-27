//
//  TennisMatchApp.swift
//  TennisMatch
//
//  Created by XUE on 18/4/2026.
//

import SwiftUI

@main
struct TennisMatchApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var localeManager = LocaleManager.shared
    @State private var followStore = FollowStore()
    @State private var userStore = UserStore()
    @State private var bookingStore = BookingStore(currentUserID: UUID())
    // TODO(Task 21): wire BookingStore(currentUserID: userStore.id) — requires AppStorage binding
    @State private var notificationStore = NotificationStore()
    /// Phase E: BookingStore.notify(...) 的出口由 NotificationStore 承接。
    /// 两个 store 都是 app 生命周期的 @State,这里在 root view 出现时一次性接线。
    @State private var didWireNotifications = false
    @State private var creditScoreStore = CreditScoreStore()
    @State private var ratingFeedbackStore = RatingFeedbackStore()
    @State private var tournamentStore = TournamentStore()
    @State private var inviteStore = InviteStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    NavigationStack {
                        HomeView()
                        //LoginView()
                    }
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }
            // TODO(Phase1.5): 暂时强制浅色 — MessagesView / RecommendedPlayersSection / LoginView
            // 等 ~7 处仍硬编码 `Color.white`,跟随系统切深色时白底文字对比度完全失效。
            // 见审计 P2-#11,等 Theme 语义色全覆盖后再移除。
            .preferredColorScheme(.light)
            .environment(\.locale, localeManager.currentLocale)
            .environment(localeManager)
            .environment(followStore)
            .environment(userStore)
            .environment(bookingStore)
            .environment(notificationStore)
            .environment(creditScoreStore)
            .environment(ratingFeedbackStore)
            .environment(tournamentStore)
            .environment(inviteStore)
            .task {
                // Phase E: 接线 BookingStore → NotificationStore(只接一次)。
                if !didWireNotifications {
                    bookingStore.notificationStore = notificationStore
                    didWireNotifications = true
                }
            }
        }
    }
}
