import SwiftUI

struct CriarContaView: View {

    @EnvironmentObject private var dependencies: AppDependencies

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = CriarContaViewModel()
    @State private var emailText = ""
    @State private var senha = ""
    @State private var confirmarSenha = ""

    
    var body: some View {
        ZStack {
            FundoLoginView()

            ScrollView {
                VStack(spacing: 20) {
                    

                    Text("Criar Conta")
                        .font(.largeTitle.bold())

                    Text("Preencha os dados abaixo\npara começar a usar o Pay Flow")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    CampoLoginView(
                        icone: "envelope.fill",
                        placeholder: "Digite seu email",
                        texto: $emailText
                    )

                    CampoLoginView(
                        icone: "lock.fill",
                        placeholder: "Crie uma senha",
                        texto: $senha,
                        ehSenha: true
                    )

                    CampoLoginView(
                        icone: "lock.rotation",
                        placeholder: "Confirme sua senha",
                        texto: $confirmarSenha,
                        ehSenha: true
                    )

                    BotaoPrincipalLoginView(
                        titulo: "Criar Conta",
                        carregando: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.criarConta(
                                email: emailText,
                                senha: senha,
                                confirmarSenha: confirmarSenha,
                                authRepository: dependencies.authRepository
                            )
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    Button("Já tenho uma conta") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(PayFlowCores.teal)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(PayFlowCores.teal)
                }
            }
        }
        .onChange(of: viewModel.cadastroConcluido) { _, concluido in
            if concluido {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CriarContaView()
            .environmentObject(AppDependencies.live)
    }
}
