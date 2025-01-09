//
//  AuthView.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.
import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var errorHandler: AppErrorHandler
    
    init(authState: AuthStateProtocol) {
        let errorHandler = AppErrorHandler.shared
        let googleAuthService = GoogleAuthService(errorHandler: errorHandler)
        self.viewModel = AuthViewModel(
            authService: googleAuthService,
            authState: authState,
            errorHandler: errorHandler
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to GoGym")
                .font(.largeTitle)
                .padding()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                signInButton
            }
        }
        .padding()
        .alert("Error", isPresented: $errorHandler.showError) {
            Button("OK", role: .cancel) {
                errorHandler.clearError()
            }
        } message: {
            Text(errorHandler.currentError ?? "An unknown error occurred")
        }
    }
    
    private var signInButton: some View {
        Button(action: viewModel.signIn) {
            HStack {
                Image(systemName: "globe")
                Text("Sign in with Google")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

