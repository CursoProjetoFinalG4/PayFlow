/*
Importa o SwiftUI, responsável pela construção da interface declarativa.

É usado aqui para montar a lista de vencimentos e os componentes visuais da tela.
*/
import SwiftUI

/*
Importa o CoreData para lidar com persistência local.

Neste caso, ele é utilizado junto com @FetchRequest para buscar
automaticamente as despesas salvas.
*/
import CoreData

/*
View responsável por exibir a lista de vencimentos das despesas.

A tela mostra todas as assinaturas/despesas cadastradas,
ordenadas por mês e nome, facilitando a visualização dos compromissos.

Não possui ViewModel, pois utiliza diretamente o @FetchRequest
para buscar os dados do CoreData.
*/
struct VencimentosView: View {

    /*
     FetchRequest responsável por buscar as despesas no banco local.

     - Ordena primeiro pelo mês (mes)
     - Depois pelo nome da despesa

     O SwiftUI observa automaticamente essa coleção:
     qualquer alteração no CoreData reflete na tela sem precisar recarregar manualmente.
     */
    private let emailUsuario: String

    @FetchRequest private var despesas: FetchedResults<Despesa>

    init(emailUsuario: String) {
        self.emailUsuario = emailUsuario
        _despesas = FetchRequest<Despesa>(
            sortDescriptors: [NSSortDescriptor(key: "nomeDespesa", ascending: true)],
            predicate: NSPredicate(format: "emailUsuario == %@", emailUsuario),
            animation: .default
        )
    }

    private var despesasOrdenadas: [Despesa] {
        despesas.sorted {
            let mesA = Meses.indice(de: $0.mes)
            let mesB = Meses.indice(de: $1.mes)
            if mesA != mesB { return mesA < mesB }
            return ($0.nomeDespesa ?? "") < ($1.nomeDespesa ?? "")
        }
    }

    /*
     Define a interface da tela de vencimentos.

     A estrutura é simples:
     - Uma lista (List)
     - Um estado vazio quando não há dados
     - Um ForEach exibindo cada despesa cadastrada

     Cada item mostra:
     - Nome da despesa
     - Mês de vencimento
     - Valor formatado em moeda (BRL)
     */
    var body: some View {
        List {
            if despesas.isEmpty {
                ContentUnavailableView("Nenhum vencimento cadastrado", systemImage: "calendar")
            } else {
                ForEach(despesasOrdenadas) { item in
                    HStack(spacing: 14) {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundStyle(PayFlowCores.teal)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.nomeDespesa ?? "Sem nome")
                                .font(.headline)

                            Text("Vencimento: \(item.mes ?? "-")")
                                .font(.subheadline)
                                .foregroundStyle(PayFlowCores.textoSecundario)
                        }

                        Spacer()

                        Text(Double(item.valorDespesa), format: .currency(code: "BRL"))
                            .font(.subheadline.bold())
                            .foregroundStyle(PayFlowCores.teal)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.white.opacity(0.7))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FundoPadraoView())
        .navigationTitle("Vencimentos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PayFlowCores.creme.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        VencimentosView(emailUsuario: "preview@payflow.com")
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
