/*
Importa o Foundation, utilizado para recursos básicos da linguagem
como tratamento de erros e estruturas de dados.
*/
import Foundation

/*
Importa o Combine, permitindo o uso de propriedades reativas (@Published),
que notificam automaticamente a interface quando há alterações.
*/
import Combine

/*
ViewModel responsável pela tela principal de despesas.

Ele centraliza:
- cálculos de resumo (total de assinaturas e valor mensal)
- consumo de dados externos (API de serviços)
- controle de loading e erros

Atua como ponte entre a View e os repositórios.
*/
@MainActor
final class MesesDespesasViewModel: ObservableObject {

    // quantidade total de assinaturas cadastradas
    @Published var totalAssinaturas = 0

    // soma total mensal das despesas
    @Published var totalMensal = 0.0

    // lista de serviços externos obtidos via API
    @Published var remoteServices: [RemoteService] = []

    // indica se os dados estão sendo carregados
    @Published var isLoading = false

    // armazena mensagem de erro para exibição na UI
    @Published var errorMessage: String?

    /*
     Responsável por carregar todos os dados necessários para a tela.

     Parâmetros:
     - assinaturaRepository: fornece dados locais (CoreData)
     - pricingRepository: fornece dados externos (API)

     Fluxo:
     1. Ativa estado de loading
     2. Limpa erros anteriores
     3. Busca resumo das assinaturas (total e valor)
     4. Busca lista de serviços externos
     5. Atualiza propriedades observadas pela UI
     6. Em caso de erro, captura mensagem
     7. Finaliza loading

     Esse método é assíncrono pois envolve chamada externa (API).
    */
    func load(
        assinaturaRepository: AssinaturaRepositoryProtocol,
        pricingRepository: PricingRepositoryProtocol,
        emailUsuario: String
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let resumo = try assinaturaRepository.resumo(emailUsuario: emailUsuario)
            totalAssinaturas = resumo.totalAssinaturas
            totalMensal = resumo.totalMensal
            remoteServices = try await pricingRepository.fetchRemoteServices()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
