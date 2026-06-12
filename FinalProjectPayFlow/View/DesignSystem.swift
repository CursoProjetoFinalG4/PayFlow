// DesignSystem.swift
//
// Centraliza os elementos visuais reutilizáveis do PayFlow.
// A ideia é estender a identidade premium da tela de login (gradiente teal,
// cápsulas, sombras suaves) para o app inteiro, mantendo tudo coerente.
//
// Os componentes aqui se apoiam na paleta definida em `PayFlowCores`
// (declarada em LoginEstilo.swift) e a complementam com novos tokens.

import SwiftUI

// MARK: - Paleta complementar

/* Tokens extras que fecham o sistema de cores. A paleta base (teal, tealEscuro,
   creme) continua em LoginEstilo.swift; aqui só adicionamos os papéis que faltavam. */
extension PayFlowCores {

    // Texto secundário/legendas, mais suave que o preto padrão.
    static let textoSecundario = Color(red: 0.42, green: 0.47, blue: 0.47)

    // Cor de alerta/atenção, usada para vencimentos e valores em destaque.
    static let coral = Color(red: 0.90, green: 0.42, blue: 0.38)

    // Dourado discreto para reforçar a sensação "premium" (economia/sugestões).
    static let dourado = Color(red: 0.83, green: 0.66, blue: 0.36)
}

// MARK: - Fundo padrão das telas internas

/* Versão mais sóbria do fundo do login: um gradiente suave do creme para um
   leve teal, pensado para ficar atrás de conteúdo sem competir com os cards. */
struct FundoPadraoView: View {
    var body: some View {
        LinearGradient(
            colors: [
                PayFlowCores.creme,
                Color.white,
                PayFlowCores.teal.opacity(0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Card base

/* Container branco com cantos arredondados e sombra suave, no mesmo espírito
   dos campos do login. É o bloco visual de construção das telas internas. */
struct CardPayFlow<Content: View>: View {
    var espacamento: CGFloat = 16
    @ViewBuilder var conteudo: Content

    var body: some View {
        conteudo
            .padding(espacamento)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Card de métrica (indicadores do topo)

/* Card com ícone em círculo, título e valor em destaque. Usado nos indicadores
   da home (total de assinaturas, gasto mensal, etc.). */
struct CardMetrica: View {
    let titulo: String
    let valor: String
    let icone: String
    var cor: Color = PayFlowCores.teal

    var body: some View {
        CardPayFlow {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(cor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icone)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(cor)
                }

                Text(titulo)
                    .font(.subheadline)
                    .foregroundStyle(PayFlowCores.textoSecundario)

                Text(valor)
                    .font(.title3.bold())
                    .foregroundStyle(PayFlowCores.tealEscuro)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Título de seção

/* Cabeçalho de seção padronizado: ícone teal opcional + texto em tealEscuro. */
struct TituloSecao: View {
    let texto: String
    var icone: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icone {
                Image(systemName: icone)
                    .foregroundStyle(PayFlowCores.teal)
            }
            Text(texto)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}

// MARK: - Tag / pílula

/* Etiqueta arredondada (ex.: categoria de um serviço), em teal suave. */
struct TagPayFlow: View {
    let texto: String
    var cor: Color = PayFlowCores.teal

    var body: some View {
        Text(texto)
            .font(.caption.weight(.semibold))
            .foregroundStyle(cor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(cor.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Estilos de botão

/* Botão primário: gradiente teal em cápsula, igual ao "Entrar" do login.
   Inclui micro-feedback de toque (leve redução de escala e opacidade). */
struct PayFlowBotaoPrimario: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [PayFlowCores.teal, PayFlowCores.tealEscuro],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: PayFlowCores.teal.opacity(0.30), radius: 8, y: 4)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/* Botão secundário: contorno teal sobre fundo claro, para ações de menor ênfase. */
struct PayFlowBotaoSecundario: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(PayFlowCores.teal)
            .background(Color.white.opacity(0.65))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(PayFlowCores.teal, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/* Açúcar sintático para usar `.buttonStyle(.payflowPrimario)` / `.payflowSecundario`. */
extension ButtonStyle where Self == PayFlowBotaoPrimario {
    static var payflowPrimario: PayFlowBotaoPrimario { .init() }
}

extension ButtonStyle where Self == PayFlowBotaoSecundario {
    static var payflowSecundario: PayFlowBotaoSecundario { .init() }
}

// MARK: - Linha de navegação (estilo "lista premium")

/* Linha tocável usada dentro de cards para navegação rápida, no padrão dos
   ajustes do iOS: ícone, título e chevron. Pensada para uso em ScrollView. */
struct LinhaNavegacao<Destino: View>: View {
    let titulo: String
    let icone: String
    @ViewBuilder var destino: Destino

    var body: some View {
        NavigationLink {
            destino
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icone)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PayFlowCores.teal)
                    .frame(width: 24)

                Text(titulo)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(PayFlowCores.textoSecundario)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card de serviço/produto externo

/* Card premium para exibir itens vindos da API externa.
   Cada categoria ganha um ícone e cor próprios, criando identidade visual
   por tipo de produto. O layout divide informação (topo) de preço (rodapé),
   separados por uma linha sutil. */
struct CardServico: View {
    let item: RemoteService

    private var meta: (icone: String, cor: Color) {
        let cat = item.category.lowercased()
        if cat.contains("eletr") || cat.contains("electr") {
            return ("laptopcomputer", Color(red: 0.22, green: 0.47, blue: 0.85))
        } else if cat.contains("joia") || cat.contains("jewel") {
            return ("sparkles", Color(red: 0.65, green: 0.38, blue: 0.82))
        } else if cat.contains("feminina") || cat.contains("women") {
            return ("figure.dress.line.vertical.figure", Color(red: 0.88, green: 0.40, blue: 0.62))
        } else {
            return ("tshirt.fill", PayFlowCores.teal)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo: ícone + título + categoria
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [meta.cor.opacity(0.20), meta.cor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)

                    Image(systemName: meta.icone)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(meta.cor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    TagPayFlow(texto: item.category, cor: meta.cor)
                }

                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)

            // Divisória com degradê
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [meta.cor.opacity(0.30), meta.cor.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.bottom, 12)

            // Rodapé: label + preço
            HStack(alignment: .lastTextBaseline) {
                Text("Preço de referência")
                    .font(.caption)
                    .foregroundStyle(PayFlowCores.textoSecundario)

                Spacer()

                Text(item.price, format: .currency(code: "BRL"))
                    .font(.title3.bold())
                    .foregroundStyle(meta.cor)
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: meta.cor.opacity(0.12), radius: 12, x: 0, y: 5)
        .overlay(
            // Barra de acento colorida no topo do card
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [meta.cor.opacity(0.35), meta.cor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Modificador de fundo de tela

/* Aplica o fundo padrão atrás do conteúdo e padroniza a barra de navegação
   com a cor creme da identidade. Use `.fundoPayFlow()` em qualquer tela. */
private struct FundoPayFlowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(FundoPadraoView())
            .toolbarBackground(PayFlowCores.creme.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
    }
}

extension View {
    /* Conveniência para aplicar o fundo e a barra padrão do PayFlow numa tela. */
    func fundoPayFlow() -> some View {
        modifier(FundoPayFlowModifier())
    }
}
