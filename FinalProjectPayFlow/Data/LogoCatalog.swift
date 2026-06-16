import Foundation

struct MarcaAssinaturaInfo: Identifiable {
    let id: String
    let aliases: [String]
}

enum LogoCatalog {
    static let marcas: [MarcaAssinaturaInfo] = [
        MarcaAssinaturaInfo(id: "spotify", aliases: ["spotify"]),
        MarcaAssinaturaInfo(id: "netflix", aliases: ["netflix"]),
        MarcaAssinaturaInfo(id: "disney", aliases: ["disney", "disney plus", "disney+"]),
        MarcaAssinaturaInfo(id: "amazon", aliases: ["amazon", "amazon prime", "prime video"]),
        MarcaAssinaturaInfo(id: "youtube", aliases: ["youtube", "youtube premium"]),
        MarcaAssinaturaInfo(id: "playstation", aliases: ["playstation", "ps plus", "playstation plus"]),
        MarcaAssinaturaInfo(id: "onlyfans", aliases: ["onlyfans", "only fans"]),
    ]

    static func normalizar(_ texto: String) -> String {
        texto
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "pt_BR"))
            .lowercased()
            .replacingOccurrences(of: "+", with: " plus ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func resolver(nome: String) -> String? {
        let normalizado = normalizar(nome)
        guard !normalizado.isEmpty else { return nil }

        let ordenadas = marcas.sorted {
            ($0.aliases.map { normalizar($0).count }.max() ?? 0) >
            ($1.aliases.map { normalizar($0).count }.max() ?? 0)
        }

        for marca in ordenadas {
            for alias in marca.aliases {
                let aliasNorm = normalizar(alias)
                guard !aliasNorm.isEmpty else { continue }
                if normalizado == aliasNorm || normalizado.contains(aliasNorm) {
                    return marca.id
                }
            }
        }

        return nil
    }

    static func marca(porIdentificador identificador: String?) -> MarcaAssinaturaInfo? {
        guard let identificador else { return nil }
        return marcas.first { $0.id == identificador }
    }

    static func marca(paraNome nome: String) -> MarcaAssinaturaInfo? {
        marca(porIdentificador: resolver(nome: nome))
    }
}
