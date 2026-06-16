

import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var isLoggedIn: Bool
    @Published private(set) var email: String

    init() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.email = UserDefaults.standard.string(forKey: "loggedUserEmail") ?? ""
    }

    func login(email: String) {
        self.isLoggedIn = true
        self.email = email
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(email, forKey: "loggedUserEmail")
    }

    func logout() {
        self.isLoggedIn = false
        self.email = ""
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "loggedUserEmail")
    }
}
