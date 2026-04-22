//
//  TennisMatchApp.swift
//  TennisMatch
//
//  Created by XUE on 18/4/2026.
//

import SwiftUI

@main
struct TennisMatchApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @State private var followStore = FollowStore()
    @State private var userStore = UserStore()
    @State private var bookedSlotStore = BookedSlotStore()
    @State private var notificationStore = NotificationStore()
    @State private var creditScoreStore = CreditScoreStore()
    @State private var ratingFeedbackStore = RatingFeedbackStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isLoggedIn {
                    HomeView()
                } else {
                    LoginView()
                }
            }
            .environment(followStore)
            .environment(userStore)
            .environment(bookedSlotStore)
            .environment(notificationStore)
            .environment(creditScoreStore)
            .environment(ratingFeedbackStore)
        }
    }
}
