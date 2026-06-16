import SwiftUI
import CoreData

private struct MarcaVisual {
    let cor: Color
    let simbolo: String
}

private enum MarcaVisualCatalog {
    static let padraoSimbolo = "creditcard.fill"
    static let padraoCor = PayFlowCores.teal

    private static let visuais: [String: MarcaVisual] = [
        "spotify": MarcaVisual(cor: Color(red: 0.11, green: 0.73, blue: 0.33), simbolo: "music.note"),
        "netflix": MarcaVisual(cor: Color(red: 0.90, green: 0.11, blue: 0.14), simbolo: "play.rectangle.fill"),
        "disney": MarcaVisual(cor: Color(red: 0.07, green: 0.24, blue: 0.56), simbolo: "sparkles.tv"),
        "amazon": MarcaVisual(cor: Color(red: 0.00, green: 0.66, blue: 0.87), simbolo: "shippingbox.fill"),
        "youtube": MarcaVisual(cor: Color(red: 0.90, green: 0.11, blue: 0.14), simbolo: "play.circle.fill"),
        "playstation": MarcaVisual(cor: Color(red: 0.00, green: 0.40, blue: 0.75), simbolo: "gamecontroller.fill"),
        "onlyfans": MarcaVisual(cor: Color(red: 0.00, green: 0.69, blue: 0.94), simbolo: "person.crop.circle.fill"),
    ]

    static func visual(paraIdentificador identificador: String?) -> MarcaVisual? {
        guard let identificador else { return nil }
        return visuais[identificador]
    }
}

struct LogoAssinaturaView: View {
    var identificador: String?
    var nome: String?
    var tamanho: CGFloat = 40
    var simboloTamanho: Font = .body

    private var identificadorResolvido: String? {
        identificador ?? nome.flatMap { LogoCatalog.resolver(nome: $0) }
    }

    private var visual: MarcaVisual? {
        MarcaVisualCatalog.visual(paraIdentificador: identificadorResolvido)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill((visual?.cor ?? MarcaVisualCatalog.padraoCor).opacity(visual == nil ? 0.15 : 1))
                .frame(width: tamanho, height: tamanho)

            Image(systemName: visual?.simbolo ?? MarcaVisualCatalog.padraoSimbolo)
                .font(simboloTamanho)
                .foregroundStyle(visual == nil ? MarcaVisualCatalog.padraoCor : .white)
        }
    }
}

extension LogoAssinaturaView {
    init(despesa: Despesa, tamanho: CGFloat = 40, simboloTamanho: Font = .body) {
        self.identificador = despesa.logoIdentificador
        self.nome = despesa.nomeDespesa
        self.tamanho = tamanho
        self.simboloTamanho = simboloTamanho
    }
}
