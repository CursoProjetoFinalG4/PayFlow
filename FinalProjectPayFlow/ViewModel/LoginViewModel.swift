
import Foundation
import Combine


@MainActor
final class LoginViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?

    func login(
        email: String,
        password: String,
        authRepository: AuthRepositoryProtocol,
        sessionStore: SessionStore
    ) async {
        isLoading = true
        errorMessage = nil

        let emailLimpo = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await authRepository.login(email: emailLimpo, password: password)
            sessionStore.login(email: emailLimpo)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
