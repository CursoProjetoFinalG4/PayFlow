import SwiftUI
import CoreData

struct DetalheDespesaView: View {

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dependencies: AppDependencies

    let despesa: Despesa
    let emailUsuario: String

    @State private var exibirEdicao = false
    @State private var exibirAlertaExclusao = false
    @State private var errorMessage: String?

    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CardPayFlow {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            LogoAssinaturaView(despesa: despesa, tamanho: 52, simboloTamanho: .title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(despesa.nomeDespesa ?? "Sem nome")
                                    .font(.title3.bold())
                                    .foregroundStyle(PayFlowCores.tealEscuro)
                                Text("Vencimento: \(despesa.mes ?? "Não informado")")
                                    .font(.subheadline)
                                    .foregroundStyle(PayFlowCores.textoSecundario)
                            }
                        }

                        Divider()

                        HStack {
                            Text("Valor mensal")
                                .foregroundStyle(PayFlowCores.textoSecundario)
                            Spacer()
                            Text(Double(despesa.valorDespesa), format: .currency(code: "BRL"))
                                .font(.title3.bold())
                                .foregroundStyle(PayFlowCores.teal)
                        }
                    }
                }

                Button {
                    exibirEdicao = true
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                .buttonStyle(.payflowPrimario)

                Button(role: .destructive) {
                    exibirAlertaExclusao = true
                } label: {
                    Label("Excluir", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .foregroundStyle(PayFlowCores.coral)
                        .background(PayFlowCores.coral.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(FundoPadraoView())
        .navigationTitle("Detalhe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PayFlowCores.creme.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $exibirEdicao) {
            NavigationStack {
                FormDespesasView(despesa: despesa, mes: despesa.mes, emailUsuario: emailUsuario)
            }
        }
        .alert("Excluir assinatura?", isPresented: $exibirAlertaExclusao) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) {
                do {
                    try dependencies.makeAssinaturaRepository(context: context).delete(despesa)
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert(
            "Erro",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
