// Importa recursos básicos usados no tratamento de erros e tipos fundamentais.
import Foundation

// Importa o Combine para publicar mudanças que a interface consegue observar.
import Combine

/*
 ViewModel responsável pelo fluxo de criação de conta.

 Ele gerencia:
 - estado de carregamento
 - mensagens de erro
 - validação simples dos campos
 - chamada ao repositório de autenticação
 */
@MainActor
final class CriarContaViewModel: ObservableObject {

    // Indica se o cadastro está em andamento.
    @Published var isLoading = false

    // Guarda a mensagem de erro exibida na tela.
    @Published var errorMessage: String?

    // Indica se o cadastro foi concluído com sucesso.
    @Published var cadastroConcluido = false

    /*
     Executa o cadastro de um novo usuário.

     Fluxo:
     1. Valida se os campos foram preenchidos corretamente
     2. Confere se a senha e a confirmação são iguais
     3. Chama o repositório para salvar o novo usuário
     4. Em caso de sucesso, marca o cadastro como concluído
     */
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
