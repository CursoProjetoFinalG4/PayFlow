import Foundation
import SwiftUI

enum MoedaBRL {
    private static let locale = Locale(identifier: "pt_BR")
    private static let maxDigitos = 9

    private static var formatador: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        return formatter
    }

    static func centavos(de reais: Double) -> Int {
        Int((reais * 100).rounded())
    }

    static func reais(de centavos: Int) -> Double {
        Double(centavos) / 100.0
    }

    static func formatar(centavos: Int) -> String {
        formatador.string(from: NSNumber(value: reais(de: centavos))) ?? "R$ 0,00"
    }

    static func centavosAPartirDeDigitos(_ texto: String) -> Int {
        let digitos = texto.filter(\.isNumber)
        guard !digitos.isEmpty else { return 0 }
        let limitado = String(digitos.suffix(maxDigitos))
        return Int(limitado) ?? 0
    }
}

struct CampoValorBRL: View {
    let placeholder: String
    @Binding var valorEmReais: Double?

    @State private var textoExibido = ""
    @State private var centavos = 0

    var body: some View {
        TextField(placeholder, text: $textoExibido)
            .keyboardType(.numberPad)
            .onChange(of: textoExibido) { _, novoTexto in
                aplicarDigitos(novoTexto)
            }
            .onAppear {
                sincronizarAPartirDoBinding()
            }
            .onChange(of: valorEmReais) { _, _ in
                sincronizarAPartirDoBinding()
            }
    }

    private func sincronizarAPartirDoBinding() {
        let novosCentavos = valorEmReais.map(MoedaBRL.centavos(de:)) ?? 0
        guard novosCentavos != centavos else { return }
        centavos = novosCentavos
        textoExibido = MoedaBRL.formatar(centavos: centavos)
    }

    private func aplicarDigitos(_ texto: String) {
        let novosCentavos = MoedaBRL.centavosAPartirDeDigitos(texto)
        centavos = novosCentavos
        valorEmReais = novosCentavos > 0 ? MoedaBRL.reais(de: novosCentavos) : nil

        let formatado = MoedaBRL.formatar(centavos: novosCentavos)
        if textoExibido != formatado {
            textoExibido = formatado
        }
    }
}
