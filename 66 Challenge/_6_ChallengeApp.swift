//
//  _6_ChallengeApp.swift
//  66 Challenge
//
//  Created by Peter on 2025-02-06.
//

import SwiftUI
import Supabase

@main
struct _6_ChallengeApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
