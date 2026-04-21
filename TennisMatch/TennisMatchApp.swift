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
        }
    }
}
