
import Foundation
import Combine


//ViewModel responsável pela tela principal de despesas.
@MainActor
final class MesesDespesasViewModel: ObservableObject {

    @Published var totalAssinaturas = 0
    @Published var totalMensal = 0.0
    @Published var remoteServices: [RemoteService] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    
     //Responsável por carregar todos os dados necessários para a tela.
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
