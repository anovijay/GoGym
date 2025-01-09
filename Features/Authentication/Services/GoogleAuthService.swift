//
//  GoogleAuthenticationService.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.
//

// GoogleAuthService.swift

import Foundation
import FirebaseAuth
import GoogleSignIn
import Firebase

class GoogleAuthService: AuthenticationService {
    private let errorHandler: ErrorHandling
    
    init(errorHandler: ErrorHandling) {
        self.errorHandler = errorHandler
    }
    
    func signIn(completion: @escaping (Result<User, AuthError>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(.missingCredentials))
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(.failure(.signInFailed("Cannot get root view controller")))
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                self?.errorHandler.handle(error)
                completion(.failure(.signInFailed(error.localizedDescription)))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(.signInFailed("Failed to get user credentials")))
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self?.errorHandler.handle(error)
                    completion(.failure(.signInFailed(error.localizedDescription)))
                } else if let user = authResult?.user {
                    completion(.success(user))
                } else {
                    completion(.failure(.unknownError))
                }
            }
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            errorHandler.handle(error)
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }
}
