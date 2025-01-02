import FirebaseAuth
import Combine

class AuthState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var displayName: String?

    init() {
        if let user = Auth.auth().currentUser {
            self.isLoggedIn = true
            self.displayName = user.displayName
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
            self.displayName = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
