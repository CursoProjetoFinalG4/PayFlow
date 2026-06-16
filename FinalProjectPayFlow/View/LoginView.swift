// Importa os componentes visuais necessários para montar a tela de login.
import SwiftUI

struct LoginView: View {

    @EnvironmentObject private var dependencies: AppDependencies
    @EnvironmentObject private var sessionStore: SessionStore
    
    @AppStorage("emailSalvo") private var emailSalvo = ""
    @StateObject private var viewModel = LoginViewModel()
    @State private var emailText = ""
    @State private var senha = ""
    @State private var salvarEmail = false
    @State private var mostrarAlertaSenha = false


    var body: some View {
        NavigationStack {
            ZStack {
                FundoLoginView()

                ScrollView {
                    VStack(spacing: 20) {

                        Text("Pay Flow")
                            .font(.largeTitle.bold())

                        Text("Organizador de assinaturas\ne gastos recorrentes")
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
                            placeholder: "Digite sua senha",
                            texto: $senha,
                            ehSenha: true
                        )

                        HStack {
                            Spacer()
                            Button("Esqueci a senha?") {
                                mostrarAlertaSenha = true
                            }
                            .font(.subheadline)
                            .foregroundStyle(PayFlowCores.teal)
                        }

                        Toggle("Lembre de mim", isOn: $salvarEmail)
                            .tint(PayFlowCores.teal)

                        BotaoPrincipalLoginView(
                            titulo: "Entrar",
                            carregando: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.login(
                                    email: emailText,
                                    password: senha,
                                    authRepository: dependencies.authRepository,
                                    sessionStore: sessionStore
                                )

                                if viewModel.errorMessage == nil {
                                    emailSalvo = salvarEmail ? emailText : ""
                                    senha = ""
                                }
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }



                        NavigationLink {
                            CriarContaView()
                        } label: {
                            Text("Criar Nova Conta")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundStyle(PayFlowCores.teal)
                                .background(Color.white.opacity(0.65))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(PayFlowCores.teal, lineWidth: 1.5)
                                )
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                emailText = emailSalvo
                salvarEmail = !emailSalvo.isEmpty
            }
            .alert("Esqueci a senha", isPresented: $mostrarAlertaSenha) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Para contas de demonstração, use a senha 123456. Se você criou uma conta nova, use a senha cadastrada.")
            }

        }
    }
}


#Preview {
    LoginView()
        .environmentObject(SessionStore())
        .environmentObject(AppDependencies.live)
}
