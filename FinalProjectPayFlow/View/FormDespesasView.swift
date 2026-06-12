// Importa os componentes visuais usados para montar a tela e reagir às ações do usuário.
import SwiftUI

// Importa o Core Data, necessário para salvar e editar as despesas cadastradas.
import CoreData

// Esta view exibe o formulário usado para cadastrar uma nova despesa ou editar uma já existente.
struct FormDespesasView: View {

    // Recupera o contexto do Core Data que será usado nas operações de gravação.
    @Environment(\.managedObjectContext) private var viewContext

    // Permite fechar a tela atual quando o usuário salvar ou voltar.
    @Environment(\.dismiss) private var dismiss

    // Dá acesso às dependências compartilhadas, como o repositório de despesas.
    @EnvironmentObject private var dependencies: AppDependencies

    // Mantém o estado e as regras de validação do formulário.
    @StateObject private var viewModel = FormDespesasViewModel()

    private var despesa: Despesa?
    private var mesParam: String?
    private var emailUsuario: String

    // Armazena o nome digitado para a despesa.
    @State private var nome: String = ""

    // Armazena o valor mensal informado no formulário.
    @State private var valor: Double? = nil

    // Armazena o mês atualmente selecionado no picker.
    @State private var mes: String = "Janeiro"

    // Lista de meses vinda da fonte única usada no app inteiro.
    private let meses = Meses.todos

    /* Este inicializador recebe, quando necessário, a despesa que será editada
       e também um mês vindo da tela anterior.
       Com isso, o formulário consegue decidir se deve abrir vazio para cadastro
       ou já preenchido para alteração de um registro existente. */
    init(despesa: Despesa? = nil, mes: String? = nil, emailUsuario: String) {
        self.despesa = despesa
        self.mesParam = mes
        self.emailUsuario = emailUsuario
    }

    /* Aqui o formulário é montado.
       A primeira parte reúne os campos que o usuário precisa preencher.
       Depois vem o botão de salvar, que chama o ViewModel para validar e gravar os dados.
       No restante da configuração, a tela define o título, o botão de voltar,
       o preenchimento inicial quando está em modo de edição
       e o alerta mostrado caso alguma validação falhe. */
    var body: some View {
        Form {
            Section("Dados") {
                TextField("Assinatura", text: $nome)

                TextField("Valor mensal", value: $valor, format: .currency(code: "BRL"))
                    .keyboardType(.decimalPad)

                Picker("Mês de vencimento", selection: $mes) {
                    ForEach(meses, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
            }

            Section {
                Button {
                    // Guarda o resultado da tentativa de validação e gravação do formulário.
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
            // Quando existe uma despesa recebida, preenche o formulário com os dados atuais dela.
            if let despesa = despesa {
                self.nome = despesa.nomeDespesa ?? ""
                self.valor = Double(despesa.valorDespesa)
                self.mes = despesa.mes ?? "Janeiro"
            // Quando não há despesa para editar, usa o mês vindo por parâmetro como valor inicial.
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
