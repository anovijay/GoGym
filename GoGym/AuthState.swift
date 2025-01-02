import FirebaseAuth
import Combine

class AuthState: ObservableObject {
    @Published var isLoggedIn: Bool = false

    init() {
        // Check Firebase for current user on launch
        self.isLoggedIn = Auth.auth().currentUser != nil
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
