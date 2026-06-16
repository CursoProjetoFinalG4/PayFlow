
import SwiftUI
import CoreData


struct VencimentosView: View {

    
     //FetchRequest responsável por buscar as despesas no banco local.
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


     //Define a interface da tela de vencimentos.
    var body: some View {
        List {
            if despesas.isEmpty {
                ContentUnavailableView("Nenhum vencimento cadastrado", systemImage: "calendar")
            } else {
                ForEach(despesasOrdenadas) { item in
                    HStack(spacing: 14) {
                        LogoAssinaturaView(despesa: item, tamanho: 40, simboloTamanho: .body)

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
