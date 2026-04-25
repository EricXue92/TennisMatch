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
    @State private var bookedSlotStore = BookedSlotStore()
    @State private var notificationStore = NotificationStore()
    @State private var creditScoreStore = CreditScoreStore()
    @State private var ratingFeedbackStore = RatingFeedbackStore()
    @State private var tournamentStore = TournamentStore()

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
            .environment(\.locale, localeManager.currentLocale)
            .environment(localeManager)
            .environment(followStore)
            .environment(userStore)
            .environment(bookedSlotStore)
            .environment(notificationStore)
            .environment(creditScoreStore)
            .environment(ratingFeedbackStore)
            .environment(tournamentStore)
        }
    }
}
