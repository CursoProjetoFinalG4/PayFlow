import SwiftUI
import CoreData

struct FormDespesasView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dependencies: AppDependencies
    @StateObject private var viewModel = FormDespesasViewModel()

    private var despesa: Despesa?
    private var mesParam: String?
    private var emailUsuario: String

    @State private var nome: String = ""
    @State private var valor: Double? = nil
    @State private var mes: String = "Janeiro"

    private let meses = Meses.todos

   
    init(despesa: Despesa? = nil, mes: String? = nil, emailUsuario: String) {
        self.despesa = despesa
        self.mesParam = mes
        self.emailUsuario = emailUsuario
    }

  
    var body: some View {
        Form {
            Section("Dados") {
                HStack(spacing: 14) {
                    LogoAssinaturaView(nome: nome, tamanho: 44, simboloTamanho: .title3)
                    TextField("Assinatura", text: $nome)
                }

                CampoValorBRL(placeholder: "Valor mensal", valorEmReais: $valor)

                Picker("Mês de vencimento", selection: $mes) {
                    ForEach(meses, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
            }

            Section {
                Button {
                    let sucesso = viewModel.salvar(
                        despesa: despesa,
                        nome: nome,
                        valor: valor ?? 0,
                        mes: mes,
                        emailUsuario: emailUsuario,
                        repository: dependencies.makeAssinaturaRepository(context: viewContext)
                    )

                    if sucesso {
                        dismiss()
                    }
                } label: {
                    Label("Salvar", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.payflowPrimario)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(FundoPadraoView())
        .tint(PayFlowCores.teal)
        .navigationTitle(despesa == nil ? "Cadastrar despesa" : "Editar despesa")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PayFlowCores.creme.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Voltar") {
                    dismiss()
                }
            }
        }
        .onAppear {
            if let despesa = despesa {
                self.nome = despesa.nomeDespesa ?? ""
                self.valor = Double(despesa.valorDespesa)
                self.mes = despesa.mes ?? "Janeiro"
            } else if let mesParam = mesParam {
                self.mes = mesParam
            }
        }
        .alert(
            "Validação",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
