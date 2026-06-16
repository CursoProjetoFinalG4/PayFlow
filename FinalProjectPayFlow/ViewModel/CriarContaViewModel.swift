import Foundation
import Combine

//ViewModel responsável pelo fluxo de criação de conta.


@MainActor
final class CriarContaViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var cadastroConcluido = false

    
     //Executa o cadastro de um novo usuário.
    
    func criarConta(
        email: String,
        senha: String,
        confirmarSenha: String,
        authRepository: AuthRepositoryProtocol
    ) async {
        isLoading = true
        errorMessage = nil
        cadastroConcluido = false

        let emailLimpo = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !emailLimpo.isEmpty else {
            errorMessage = "Digite um email válido."
            isLoading = false
            return
        }

        guard senha.count >= 6 else {
            errorMessage = "A senha precisa ter pelo menos 6 caracteres."
            isLoading = false
            return
        }

        guard senha == confirmarSenha else {
            errorMessage = "As senhas não coincidem."
            isLoading = false
            return
        }

        do {
            try await authRepository.register(email: emailLimpo, password: senha)
            cadastroConcluido = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
