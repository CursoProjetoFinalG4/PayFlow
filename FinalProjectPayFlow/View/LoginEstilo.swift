import SwiftUI

enum PayFlowCores {
    static let teal = Color(red: 0.18, green: 0.61, blue: 0.55)
    static let tealEscuro = Color(red: 0.10, green: 0.42, blue: 0.38)
    static let creme = Color(red: 0.98, green: 0.96, blue: 0.88)
}

// Monta o fundo com gradiente e símbolos de cifrão, como no design da tela.
struct FundoLoginView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    PayFlowCores.teal.opacity(0.35),
                    PayFlowCores.creme,
                    PayFlowCores.teal.opacity(0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Símbolos grandes e suaves no fundo para dar profundidade à tela.
            VStack {
                HStack {
                    Text("$")
                        .font(.system(size: 90, weight: .bold))
                        .foregroundStyle(PayFlowCores.teal.opacity(0.08))
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Text("$")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundStyle(PayFlowCores.teal.opacity(0.06))
                }
            }
            .padding(24)
        }
    }
}

// Exibe o ícone do app com o desenho da carteira e as linhas de movimento.
struct LogoPayFlowView: View {
    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(PayFlowCores.teal)
                        .frame(width: 18, height: 4)
                }
            }

            ZStack {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(PayFlowCores.teal)

                Text("$")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .offset(y: 2)
            }
        }
        .padding(.top, 8)
    }
}

// Campo de texto arredondado com ícone à esquerda, usado no login e no cadastro.
struct CampoLoginView: View {
    let icone: String
    let placeholder: String
    @Binding var texto: String
    var ehSenha: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icone)
                .foregroundStyle(PayFlowCores.teal)
                .frame(width: 22)

            if ehSenha {
                SecureField(placeholder, text: $texto)
            } else {
                TextField(placeholder, text: $texto)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

// Botão principal com gradiente e seta, usado na ação de entrar ou criar conta.
struct BotaoPrincipalLoginView: View {
    let titulo: String
    let carregando: Bool
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            HStack(spacing: 8) {
                if carregando {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(titulo)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.up.right")
                        .font(.subheadline.bold())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [PayFlowCores.teal, PayFlowCores.tealEscuro],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: PayFlowCores.teal.opacity(0.35), radius: 8, y: 4)
        }
        .disabled(carregando)
    }
}
