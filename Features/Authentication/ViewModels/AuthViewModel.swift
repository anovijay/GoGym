//
//  AuthViewModel.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.

//  AuthViewModel.swift

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    private let authService: AuthenticationService
    private let authState: AuthStateProtocol
    private let errorHandler: ErrorHandling
    
    @Published var isLoading = false
    
    init(authService: AuthenticationService,
         authState: AuthStateProtocol,
         errorHandler: ErrorHandling) {
        self.authService = authService
        self.authState = authState
        self.errorHandler = errorHandler
    }
    
    func signIn() {
        isLoading = true
        authService.signIn { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user):
                    self?.authState.updateAuthState(user: user)
                case .failure(let error):
                    self?.errorHandler.handle(error.localizedDescription)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
            authState.clearAuthState()
        } catch {
            errorHandler.handle(error)
        }
    }
}
