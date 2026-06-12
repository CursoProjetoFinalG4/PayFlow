// Importa os componentes visuais do SwiftUI usados para montar a tela.
import SwiftUI

// Importa o Core Data, necessário para acessar, listar e remover as despesas salvas.
import CoreData

// Esta view mostra a lista de assinaturas cadastradas e permite navegar para os detalhes ou incluir novos itens.
struct CadastroView: View {

    // Recupera o contexto do Core Data disponível no ambiente da aplicação.
    @Environment(\.managedObjectContext) private var managedObjectContext

    // Dá acesso às dependências compartilhadas, como os repositórios usados pela tela.
    @EnvironmentObject private var dependencies: AppDependencies

    // Mantém o estado e as ações da tela, principalmente para exclusão e tratamento de erro.
    @StateObject private var cadastroViewModel = CadastroViewModel()

    var mes: String?
    private let emailUsuario: String

    @FetchRequest private var despesas: FetchedResults<Despesa>

    init(mes: String? = nil, emailUsuario: String) {
        self.mes = mes
        self.emailUsuario = emailUsuario

        if let mes = mes {
            _despesas = FetchRequest<Despesa>(
                sortDescriptors: [NSSortDescriptor(key: "nomeDespesa", ascending: true)],
                predicate: NSPredicate(format: "mes == %@ AND emailUsuario == %@", mes, emailUsuario)
            )
        } else {
            _despesas = FetchRequest<Despesa>(
                sortDescriptors: [
                    NSSortDescriptor(key: "mes", ascending: true),
                    NSSortDescriptor(key: "nomeDespesa", ascending: true)
                ],
                predicate: NSPredicate(format: "emailUsuario == %@", emailUsuario)
            )
        }
    }

    /* Lista já ordenada pela posição real do mês no calendário e depois pelo nome.
       O mês é texto no banco, então a ordenação alfabética sairia errada
       (Abril antes de Janeiro); por isso a ordenação é feita aqui em memória. */
    private var despesasOrdenadas: [Despesa] {
        despesas.sorted {
            let mesA = Meses.indice(de: $0.mes)
            let mesB = Meses.indice(de: $1.mes)
            if mesA != mesB { return mesA < mesB }
            return ($0.nomeDespesa ?? "") < ($1.nomeDespesa ?? "")
        }
    }

    /* Aqui a tela é montada de fato.
       Primeiro ela verifica se existem despesas cadastradas.
       Se não houver nada, mostra uma mensagem vazia para orientar quem estiver usando.
       Se houver registros, monta a lista com navegação para o detalhe de cada item.
       Também configura o botão de adicionar no topo e apresenta um alerta caso alguma operação falhe. */
    var body: some View {
        List {
            if despesas.isEmpty {
                ContentUnavailableView("Nenhuma assinatura cadastrada", systemImage: "creditcard")
            } else {
                ForEach(despesasOrdenadas) { despesa in
                    NavigationLink {
                        DetalheDespesaView(despesa: despesa, emailUsuario: emailUsuario)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(PayFlowCores.teal.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "creditcard.fill")
                                    .foregroundStyle(PayFlowCores.teal)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(despesa.nomeDespesa ?? "Sem nome")
                                    .font(.headline)

                                Text("Vencimento: \(despesa.mes ?? "-")")
                                    .font(.caption)
                                    .foregroundStyle(PayFlowCores.textoSecundario)
                            }

                            Spacer()

                            Text(Double(despesa.valorDespesa), format: .currency(code: "BRL"))
                                .font(.subheadline.bold())
                                .foregroundStyle(PayFlowCores.teal)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                }
                .onDelete(perform: deleteDespesa)
            }
        }
        .scrollContentBackground(.hidden)
        .background(FundoPadraoView())
        .navigationTitle(mes ?? "Histórico")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PayFlowCores.creme.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    FormDespesasView(despesa: nil, mes: mes, emailUsuario: emailUsuario)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert(
            "Erro",
            isPresented: Binding(
                get: { cadastroViewModel.errorMessage != nil },
                set: { if !$0 { cadastroViewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { cadastroViewModel.errorMessage = nil }
        } message: {
            Text(cadastroViewModel.errorMessage ?? "")
        }
    }

    /* Este método trata a exclusão de itens feita pela própria lista.
       Os índices recebidos se referem à lista ordenada exibida na tela,
       então primeiro eles são convertidos nos objetos correspondentes
       e só depois repassados ao ViewModel para a exclusão. */
    private func deleteDespesa(offsets: IndexSet) {
        let itens = offsets.map { despesasOrdenadas[$0] }

        cadastroViewModel.deleteDespesa(
            itens,
            repository: dependencies.makeAssinaturaRepository(context: managedObjectContext)
        )
    }
}

/* Esta prévia serve para abrir a tela no canvas já com o contexto do Core Data
   e com as dependências básicas injetadas, facilitando a visualização durante o desenvolvimento. */
#Preview {
    NavigationStack {
        CadastroView(emailUsuario: "preview@payflow.com")
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(AppDependencies.live)
    }
}
