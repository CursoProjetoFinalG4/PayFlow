/*
Importa o Foundation, usado para recursos básicos da linguagem,
incluindo tratamento de erros e tipos fundamentais.
*/
import Foundation

/*
Importa o Combine, necessário para trabalhar com propriedades reativas (@Published),
permitindo que a UI escute mudanças do ViewModel.
*/
import Combine

/*
ViewModel responsável pelo fluxo de login.

Ele gerencia:
- estado de carregamento
- mensagens de erro
- integração com o repositório de autenticação
- atualização da sessão do usuário
*/
@MainActor
final class LoginViewModel: ObservableObject {

    // indica se o processo de login está em andamento (usado para loading na UI)
    @Published var isLoading = false

    // armazena mensagem de erro para exibição na interface
    @Published var errorMessage: String?

    /*
     Executa o processo de login do usuário.

     Parâmetros:
     - email: email informado no formulário
     - password: senha informada
     - authRepository: responsável por chamar o serviço de autenticação
     - sessionStore: responsável por manter o estado da sessão do usuário

     Fluxo:
     1. Ativa o estado de loading
     2. Limpa mensagens de erro anteriores
     3. Chama o repositório para autenticar (assíncrono)
     4. Em caso de sucesso, atualiza a sessão do usuário
     5. Em caso de erro, captura a mensagem
     6. Finaliza o loading

     Esse método é assíncrono pois envolve chamada externa (API).
    */
    func login(
        email: String,
        password: String,
        authRepository: AuthRepositoryProtocol,
        sessionStore: SessionStore
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authRepository.login(email: email, password: password)
            sessionStore.login(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
