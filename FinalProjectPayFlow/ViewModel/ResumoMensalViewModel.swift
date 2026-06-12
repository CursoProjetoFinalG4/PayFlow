/*
Importa o Foundation, necessário para operações básicas,
manipulação de dados e estruturas fundamentais da linguagem.
*/
import Foundation

/*
Importa o Combine, usado para propriedades reativas (@Published),
permitindo atualização automática da UI quando os dados mudam.
*/
import Combine

/*
Representa uma sugestão de economia para o usuário.

Essa struct é usada para indicar quais despesas estão
acima da média de mercado (comparadas com serviços externos).
*/
struct SavingInsight: Identifiable {

    // identificador único usado pelo SwiftUI em listas (ForEach)
    let id = UUID()

    // nome da despesa/assinatura
    let nome: String

    // valor da despesa considerada acima da média
    let valor: Double
}

/*
ViewModel responsável pela tela de resumo mensal.

Ele reúne:
- totais agrupados por mês
- sugestões de economia com base em comparação externa
- controle de loading e erros

Atua integrando dados locais (CoreData) com dados externos (API).
*/
@MainActor
final class ResumoMensalViewModel: ObservableObject {

    // lista de totais agrupados por mês
    @Published var porMes: [MonthlyTotal] = []

    // lista de sugestões de economia calculadas
    @Published var sugestoesEconomia: [SavingInsight] = []

    // indica se os dados estão sendo carregados
    @Published var isLoading = false

    // mensagem de erro para exibição na interface
    @Published var errorMessage: String?

    /*
     Carrega os dados necessários para montar o resumo mensal.

     Parâmetros:
     - assinaturaRepository: fornece dados locais (despesas e totais)
     - pricingRepository: fornece dados externos (preços de serviços)

     Fluxo:
     1. Ativa o loading e limpa erros anteriores
     2. Busca o resumo das despesas locais (agrupado por mês)
     3. Busca serviços externos para cálculo de média
     4. Calcula a média de preços dos serviços externos
     5. Filtra as despesas que estão acima dessa média
     6. Gera sugestões de economia com base nesse filtro
     7. Em caso de erro, captura a mensagem
     8. Finaliza o loading

     Esse método é assíncrono pois depende de chamada externa (API).
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

            // popula os totais agrupados por mês
            porMes = resumo.porMes

            let remotos = try await pricingRepository.fetchRemoteServices()

            // calcula a média de preços dos serviços externos
            let media = remotos.map(\.price).reduce(0.0, +) / Double(max(remotos.count, 1))

            // gera sugestões apenas para despesas acima da média
            sugestoesEconomia = resumo.itens.compactMap { item in
                let valor = Double(item.valorDespesa)

                // ignora itens que estão dentro ou abaixo da média
                guard valor > media else { return nil }

                return SavingInsight(
                    nome: item.nomeDespesa ?? "Sem nome",
                    valor: valor
                )
            }
        } catch {
            // captura erro de qualquer etapa do processo
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
