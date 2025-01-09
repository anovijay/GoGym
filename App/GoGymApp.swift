//
//  GoGymApp.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//

//  GoGymApp.swift

import SwiftUI
import FirebaseCore

@main
struct GoGymApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authState = AuthStateManager()
    
    // Since AppErrorHandler is a singleton with shared instance,
    // we don't need to create it as a @StateObject
    private let errorHandler = AppErrorHandler.shared
    
    var body: some Scene {
        WindowGroup {
            MainScreen(authState: authState)
                .environmentObject(errorHandler)
        }
    }
}
