// Importa os componentes visuais usados para montar a tela.
import SwiftUI

// Importa o Core Data, necessário para manipular o registro exibido.
import CoreData

// Esta view mostra os dados de uma despesa já cadastrada e oferece ações de edição e exclusão.
struct DetalheDespesaView: View {

    // Recupera o contexto do Core Data disponível no ambiente da tela.
    @Environment(\.managedObjectContext) private var context

    // Permite fechar a tela atual e voltar para a anterior.
    @Environment(\.dismiss) private var dismiss

    // Dá acesso às dependências compartilhadas, como o repositório usado para excluir a despesa.
    @EnvironmentObject private var dependencies: AppDependencies

    let despesa: Despesa
    let emailUsuario: String

    // Controla a abertura da tela de edição.
    @State private var exibirEdicao = false

    // Controla a exibição do alerta de confirmação antes de excluir.
    @State private var exibirAlertaExclusao = false

    // Guarda a mensagem de erro quando alguma operação falha.
    @State private var errorMessage: String?

    /* Aqui a tela é montada com as informações principais da despesa.
       Primeiro são mostrados os dados cadastrados, como nome, valor e vencimento.
       Depois aparecem as ações disponíveis para quem estiver usando a tela.
       Também ficam configurados o modal de edição, o alerta de confirmação da exclusão
       e o alerta de erro, caso alguma tentativa de remoção não dê certo. */
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CardPayFlow {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(PayFlowCores.teal.opacity(0.15))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "creditcard.fill")
                                    .font(.title2)
                                    .foregroundStyle(PayFlowCores.teal)
                            }

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
