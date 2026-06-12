/*
Importa o framework de construção de interface declarativa da Apple.

É usado para montar toda a UI da tela de forma reativa.
*/
import SwiftUI

/*
Importa o CoreData para persistência local.

Aqui é utilizado para recuperar os dados de assinaturas salvos no app.
*/
import CoreData

/*
View responsável por exibir um resumo mensal das despesas.

Essa tela apresenta:
- Totais agrupados por mês
- Sugestões de economia com base em comparação com preços externos

Ela depende de um ViewModel que concentra toda a lógica de carregamento
e processamento dos dados.
*/
struct ResumoMensalView: View {

    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var dependencies: AppDependencies
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel = ResumoMensalViewModel()

    /*
     Define a estrutura visual da tela.

     A tela é organizada em uma List com duas seções principais:
     - Totais por mês (agrupamento e soma das despesas)
     - Potencial economia (comparação com preços externos)

     Também trata os estados comuns:
     - carregando (loading)
     - erro
     - vazio (sem dados)

     O carregamento dos dados acontece automaticamente com o .task,
     assim que a tela é exibida.
     */
    var body: some View {
        List {
            Section {
                if viewModel.isLoading {
                    ProgressView("Carregando resumo...")
                        .tint(PayFlowCores.teal)
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(PayFlowCores.coral)
                } else if viewModel.porMes.isEmpty {
                    ContentUnavailableView("Resumo vazio", systemImage: "chart.bar")
                } else {
                    ForEach(viewModel.porMes) { item in
                        HStack {
                            Text(item.month)
                                .fontWeight(.medium)
                            Spacer()
                            Text(item.total, format: .currency(code: "BRL"))
                                .font(.subheadline.bold())
                                .foregroundStyle(PayFlowCores.teal)
                        }
                        .listRowBackground(Color.white.opacity(0.7))
                    }
                }
            } header: {
                TituloSecao(texto: "Totais por mês", icone: "calendar")
            }

            Section {
                if viewModel.sugestoesEconomia.isEmpty {
                    Text("Nenhuma assinatura acima da média dos preços externos.")
                        .foregroundStyle(PayFlowCores.textoSecundario)
                        .listRowBackground(Color.white.opacity(0.7))
                } else {
                    ForEach(viewModel.sugestoesEconomia) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(PayFlowCores.teal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.nome)
                                    .fontWeight(.medium)
                                Text(item.valor, format: .currency(code: "BRL"))
                                    .font(.caption)
                                    .foregroundStyle(PayFlowCores.textoSecundario)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.7))
                    }
                }
            } header: {
                TituloSecao(texto: "Potencial economia", icone: "sparkles")
            }
        }
        .scrollContentBackground(.hidden)
        .background(FundoPadraoView())
        .navigationTitle("Resumo mensal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PayFlowCores.creme.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .task {
            await viewModel.load(
                assinaturaRepository: dependencies.makeAssinaturaRepository(context: context),
                pricingRepository: dependencies.pricingRepository,
                emailUsuario: sessionStore.email
            )
        }
    }
}

#Preview {
    NavigationStack {
        ResumoMensalView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(AppDependencies.live)
            .environmentObject(SessionStore())
    }
}
