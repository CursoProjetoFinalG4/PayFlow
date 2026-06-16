import SwiftUI
import CoreData

struct CadastroView: View {

    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var dependencies: AppDependencies
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

    
    private var despesasOrdenadas: [Despesa] {
        despesas.sorted {
            let mesA = Meses.indice(de: $0.mes)
            let mesB = Meses.indice(de: $1.mes)
            if mesA != mesB { return mesA < mesB }
            return ($0.nomeDespesa ?? "") < ($1.nomeDespesa ?? "")
        }
    }

    
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
                            LogoAssinaturaView(despesa: despesa)

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

   
    private func deleteDespesa(offsets: IndexSet) {
        let itens = offsets.map { despesasOrdenadas[$0] }

        cadastroViewModel.deleteDespesa(
            itens,
            repository: dependencies.makeAssinaturaRepository(context: managedObjectContext)
        )
    }
}


#Preview {
    NavigationStack {
        CadastroView(emailUsuario: "preview@payflow.com")
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(AppDependencies.live)
    }
}
