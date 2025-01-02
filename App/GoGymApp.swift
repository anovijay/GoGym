//
//  GoGymApp.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore

@main
struct GoGymApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            MainScreen(authState: authState) // Always starts with the main screen
        }
    }
}
