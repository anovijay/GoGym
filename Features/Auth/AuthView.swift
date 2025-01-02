import SwiftUI
import GoogleSignIn
import Firebase
import FirebaseAuth

struct AuthView: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        VStack {
            Text("Sign in with Google")
                .font(.largeTitle)
                .padding()

            Button(action: {
                googleSignIn()
            }) {
                Text("Sign in with Google")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }

    func googleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Missing client ID")
            return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Cannot get root view controller")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Error retrieving user or ID token")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    print("Firebase sign-in failed: \(error.localizedDescription)")
                } else {
                    print("User signed in successfully")
                    authState.isLoggedIn = true // Update login state
                }
            }
        }
    }
}
