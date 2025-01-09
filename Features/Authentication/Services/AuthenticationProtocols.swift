//
//  AuthenticationProtocols.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.
//

// AuthenticationProtocols.swift

import Foundation
import FirebaseAuth

protocol AuthenticationService {
    func signIn(completion: @escaping (Result<User, AuthError>) -> Void)
    func signOut() throws
}

protocol AuthStateProtocol {
    var isLoggedIn: Bool { get set }
    var displayName: String? { get set }
    var currentUser: User? { get }
    func updateAuthState(user: User?)
    func clearAuthState()
}

enum AuthError: Error {
    case signInFailed(String)
    case signOutFailed(String)
    case missingCredentials
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .missingCredentials:
            return "Missing authentication credentials"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
