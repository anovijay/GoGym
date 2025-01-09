//
//  AuthenticationStateManager.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.
//
import Foundation
import FirebaseAuth
import Combine

class AuthStateManager: ObservableObject, AuthStateProtocol {
    @Published var isLoggedIn: Bool = false
    @Published var displayName: String?
    
    var currentUser: User? {
        Auth.auth().currentUser
    }
    
    init() {
        if let user = Auth.auth().currentUser {
            updateAuthState(user: user)
        }
    }
    
    func updateAuthState(user: User?) {
        isLoggedIn = user != nil
        displayName = user?.displayName
    }
    
    func clearAuthState() {
        isLoggedIn = false
        displayName = nil
    }
}
