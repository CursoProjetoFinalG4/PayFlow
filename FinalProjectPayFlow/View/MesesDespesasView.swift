/*
Importa o SwiftUI, framework responsável por construir toda a interface da aplicação
utilizando uma abordagem declarativa.
*/
import SwiftUI

/*
Importa o CoreData, utilizado para persistência de dados local no dispositivo.
*/
import CoreData

/*
View principal do fluxo de despesas.

Essa tela funciona como ponto de entrada da aplicação, exibindo:
- Resumo geral das assinaturas
- Acesso rápido para outras funcionalidades
- Lista de serviços externos (dados vindos de API)
*/
struct MesesDespesasView: View {

    // contexto do CoreData utilizado para leitura e escrita de dados
    @Environment(\.managedObjectContext) private var context

    // container de dependências da aplicação (injeção de dependências)
    @EnvironmentObject private var dependencies: AppDependencies

    // responsável por controlar a sessão do usuário (login/logout)
    @EnvironmentObject private var sessionStore: SessionStore

    // ViewModel que concentra toda a lógica e estado da tela
    @StateObject private var mesesView = MesesDespesasViewModel()

    // controla a abertura do modal de cadastro de assinatura
    @State private var exibirCadastro = false

    /*
     Define toda a estrutura visual da tela.

     A tela é composta por:
     - Um NavigationStack para navegação
     - ScrollView com conteúdo rolável
     - Cards de resumo no topo
     - Área de navegação rápida
     - Lista de dados vindos da API
     - Toolbar com ações
     - Modal para cadastro

     Toda alteração no ViewModel reflete automaticamente aqui.
    */
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pay Flow")
                                .font(.largeTitle.bold())
                                .foregroundStyle(PayFlowCores.tealEscuro)
                            Text("Organize suas assinaturas")
                                .font(.subheadline)
                                .foregroundStyle(PayFlowCores.textoSecundario)
                        }
                        Spacer()
                    }
                    .padding(.top, 4)

                    HStack(spacing: 12) {
                        CardMetrica(
                            titulo: "Assinaturas",
                            valor: "\(mesesView.totalAssinaturas)",
                            icone: "creditcard.fill",
                            cor: PayFlowCores.teal
                        )

                        CardMetrica(
                            titulo: "Total mensal",
                            valor: mesesView.totalMensal.formatted(.currency(code: "BRL")),
                            icone: "brazilianrealsign.circle.fill",
                            cor: PayFlowCores.tealEscuro
                        )
                    }

                    CardPayFlow {
                        VStack(alignment: .leading, spacing: 4) {
                            TituloSecao(texto: "Acesso rápido", icone: "square.grid.2x2.fill")
                                .padding(.bottom, 4)

                            LinhaNavegacao(titulo: "Histórico por mês", icone: "calendar") {
                                ListaMesesView(emailUsuario: sessionStore.email)
                            }
                            Divider()
                            LinhaNavegacao(titulo: "Vencimentos", icone: "clock.fill") {
                                VencimentosView(emailUsuario: sessionStore.email)
                            }
                            Divider()
                            LinhaNavegacao(titulo: "Resumo mensal", icone: "chart.bar.fill") {
                                ResumoMensalView()
                            }
                        }
                    }

                    Button {
                        exibirCadastro = true
                    } label: {
                        Label("Cadastrar assinatura", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.payflowPrimario)

                    VStack(alignment: .leading, spacing: 12) {
                        TituloSecao(texto: "Serviços e Produtos", icone: "sparkles")

                        if mesesView.isLoading {
                            CardPayFlow {
                                HStack {
                                    Spacer()
                                    ProgressView("Carregando...")
                                        .tint(PayFlowCores.teal)
                                    Spacer()
                                }
                            }
                        } else if let error = mesesView.errorMessage {
                            CardPayFlow {
                                VStack(spacing: 8) {
                                    ContentUnavailableView("Erro na API", systemImage: "wifi.exclamationmark")
                                    Text(error)
                                        .font(.footnote)
                                        .foregroundStyle(PayFlowCores.textoSecundario)
                                }
                            }
                        } else if mesesView.remoteServices.isEmpty {
                            CardPayFlow {
                                ContentUnavailableView("Sem dados da API", systemImage: "tray")
                            }
                        } else {
                            ForEach(mesesView.remoteServices) { item in
                                CardServico(item: item)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .background(FundoPadraoView())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sair") {
                        sessionStore.logout()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        exibirCadastro = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $exibirCadastro, onDismiss: {
                Task {
                    await recarregarDados()
                }
            }) {
                NavigationStack {
                    FormDespesasView(emailUsuario: sessionStore.email)
                }
            }
            .task {
                await recarregarDados()
            }
        }
    }

    /*
     Responsável por recarregar os dados da tela.

     Aqui o ViewModel é acionado para buscar:
     - dados locais (CoreData)
     - dados externos (API)

     Esse método é utilizado tanto na abertura da tela quanto
     após o fechamento do modal de cadastro.
    */
    private func recarregarDados() async {
        await mesesView.load(
            assinaturaRepository: dependencies.makeAssinaturaRepository(context: context),
            pricingRepository: dependencies.pricingRepository,
            emailUsuario: sessionStore.email
        )
    }

}

/*
View simples responsável por listar os meses do ano.

Serve como navegação para acessar dados filtrados por mês.
*/
private struct ListaMesesView: View {

    let emailUsuario: String
    private let meses = Meses.todos

    var body: some View {
        List(meses, id: \.self) { mes in
            NavigationLink {
                CadastroView(mes: mes, emailUsuario: emailUsuario)
            } label: {
                Label(mes, systemImage: "calendar")
                    .foregroundStyle(.primary)
            }
            .listRowBackground(Color.white.opacity(0.7))
        }
        .scrollContentBackground(.hidden)
        .background(FundoPadraoView())
        .navigationTitle("Meses")
    }
}

#Preview {
    MesesDespesasView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(SessionStore())
        .environmentObject(AppDependencies.live)
}
