
import Foundation
import Combine


struct SavingInsight: Identifiable {

    let id = UUID()
    let nome: String
    let valor: Double
}


//ViewModel responsável pela tela de resumo mensal.
@MainActor
final class ResumoMensalViewModel: ObservableObject {

    @Published var porMes: [MonthlyTotal] = []
    @Published var sugestoesEconomia: [SavingInsight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    
     //Carrega os dados necessários para montar o resumo mensal.
    func load(
        assinaturaRepository: AssinaturaRepositoryProtocol,
        pricingRepository: PricingRepositoryProtocol,
        emailUsuario: String
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let resumo = try assinaturaRepository.resumo(emailUsuario: emailUsuario)

            porMes = resumo.porMes
            let remotos = try await pricingRepository.fetchRemoteServices()
            let media = remotos.map(\.price).reduce(0.0, +) / Double(max(remotos.count, 1))

            sugestoesEconomia = resumo.itens.compactMap { item in
                let valor = Double(item.valorDespesa)
                guard valor > media else { return nil }

                return SavingInsight(
                    nome: item.nomeDespesa ?? "Sem nome",
                    valor: valor
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
