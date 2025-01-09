//
//  SettingsView.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//  SettingsView.swift

//  SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @ObservedObject var authState: AuthStateManager
    @StateObject private var viewModel: AuthViewModel
    @EnvironmentObject private var errorHandler: AppErrorHandler
    
    init(authState: AuthStateManager) {
        self.authState = authState
        let errorHandler = AppErrorHandler.shared
        let googleAuthService = GoogleAuthService(errorHandler: errorHandler)
        _viewModel = StateObject(wrappedValue: AuthViewModel(
            authService: googleAuthService,
            authState: authState,
            errorHandler: errorHandler
        ))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Account")) {
                if let displayName = authState.displayName {
                    HStack {
                        Text("Signed in as")
                        Spacer()
                        Text(displayName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {
                    viewModel.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("App Settings")) {
                // Add other app settings here
                Toggle("Notifications", isOn: .constant(true))
                Toggle("Location Services", isOn: .constant(true))
            }
        }
        .alert("Error", isPresented: $errorHandler.showError) {
            Button("OK", role: .cancel) {
                errorHandler.clearError()
            }
        } message: {
            Text(errorHandler.currentError ?? "An unknown error occurred")
        }
    }
}
