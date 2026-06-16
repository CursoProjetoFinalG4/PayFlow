import Foundation
import CoreData


enum Meses {
    static let todos = [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]

   
    static func indice(de mes: String?) -> Int {
        guard let mes, let posicao = todos.firstIndex(of: mes) else {
            return todos.count
        }
        return posicao
    }
}

// Representa um serviço vindo da API remota, já pronto para leitura e exibição na interface.
struct RemoteService: Codable, Identifiable {
    let id: Int
    let title: String
    let price: Double
    let category: String
    let description: String
}

struct MonthlyTotal: Identifiable {
    let id = UUID()
    let month: String
    let total: Double
}

struct DashboardSummary {
    let totalAssinaturas: Int
    let totalMensal: Double
    let porMes: [MonthlyTotal]
    let itens: [Despesa]
}

// Define o contrato das operações de autenticação usadas pelo app.
protocol AuthRepositoryProtocol {
    
    func login(email: String, password: String) async throws
    func register(email: String, password: String) async throws
}

protocol PricingRepositoryProtocol {
    
    func fetchRemoteServices() async throws -> [RemoteService]
}

// Define o contrato das operações ligadas ao cadastro local de assinaturas.
protocol AssinaturaRepositoryProtocol {
    func fetchAll(emailUsuario: String) throws -> [Despesa]
    func save(despesa: Despesa?, nome: String, valor: Double, mes: String, emailUsuario: String) throws
    func delete(_ despesa: Despesa) throws
    func resumo(emailUsuario: String) throws -> DashboardSummary
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyExists

    case invalidRegistration

   
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email vazio ou senha incorreta."
        case .emailAlreadyExists:
            return "Este email já está cadastrado."
        case .invalidRegistration:
            return "Preencha um email válido e uma senha com pelo menos 6 caracteres."
        }
    }
}

// Implementação simples de autenticação usada pelo app, útil para cenário local e testes.
final class FakeAuthRepository: AuthRepositoryProtocol {

    private let chaveUsuarios = "usuariosCadastrados"

    
    func login(email: String, password: String) async throws {
        try await Task.sleep(for: .milliseconds(700))

        let emailLimpo = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !emailLimpo.isEmpty else {
            throw AuthError.invalidCredentials
        }

        let usuarios = carregarUsuarios()

        if let senhaSalva = usuarios[emailLimpo] {
            guard password == senhaSalva else {
                throw AuthError.invalidCredentials
            }
            return
        }

        guard password == "123456" else {
            throw AuthError.invalidCredentials
        }
    }

    
    func register(email: String, password: String) async throws {
        try await Task.sleep(for: .milliseconds(700))

        let emailLimpo = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !emailLimpo.isEmpty, password.count >= 6 else {
            throw AuthError.invalidRegistration
        }

        var usuarios = carregarUsuarios()

        if usuarios[emailLimpo] != nil {
            throw AuthError.emailAlreadyExists
        }

        usuarios[emailLimpo] = password
        UserDefaults.standard.set(usuarios, forKey: chaveUsuarios)
    }

    private func carregarUsuarios() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: chaveUsuarios) as? [String: String] ?? [:]
    }
}

final class RemotePricingRepository: PricingRepositoryProtocol {
    private let apiClient: APIClient

    
    private let titulosTraduzidos: [Int: String] = [
        1: "Mochila para notebook até 15\"",
        2: "Camiseta masculina slim premium",
        3: "Jaqueta masculina de algodão",
        4: "Camisa casual masculina slim",
        5: "Pulseira feminina em ouro e prata",
        6: "Anel de ouro com micropavê",
        7: "Anel banhado a ouro branco",
        8: "Brincos de aço banhados a ouro rosé",
        9: "HD externo WD 2TB USB 3.0",
        10: "SSD interno SanDisk 1TB SATA III",
        11: "SSD Silicon Power 256GB",
        12: "HD externo WD 4TB para PlayStation",
        13: "Monitor Acer 21,5\" Full HD IPS",
        14: "Monitor gamer Samsung 49\" curvo 144Hz",
        15: "Jaqueta feminina de inverno 3 em 1",
        16: "Jaqueta feminina de couro sintético",
        17: "Jaqueta corta-vento feminina",
        18: "Blusa feminina de manga curta",
        19: "Camiseta feminina esportiva",
        20: "Camiseta feminina casual de algodão"
    ]

    private let categoriasTraduzidas: [String: String] = [
        "men's clothing": "Moda Masculina",
        "women's clothing": "Moda Feminina",
        "jewelery": "Joias",
        "electronics": "Eletrônicos"
    ]

    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

 
      
    func fetchRemoteServices() async throws -> [RemoteService] {
        let url = "https://fakestoreapi.com/products"
        let services = try await apiClient.get(url, as: [RemoteService].self)
        let traduzidos = services.map { traduzir($0) }
        return Array(traduzidos.shuffled().prefix(6))
    }

    private func traduzir(_ service: RemoteService) -> RemoteService {
        RemoteService(
            id: service.id,
            title: titulosTraduzidos[service.id] ?? service.title,
            price: service.price,
            category: categoriasTraduzidas[service.category] ?? service.category,
            description: service.description
        )
    }
}

final class CoreDataAssinaturaRepository: AssinaturaRepositoryProtocol {
    private let context: NSManagedObjectContext

    
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll(emailUsuario: String) throws -> [Despesa] {
        let request: NSFetchRequest<Despesa> = Despesa.fetchRequest()
        request.predicate = NSPredicate(format: "emailUsuario == %@", emailUsuario)

        let itens = try context.fetch(request)

        return itens.sorted {
            let mesA = Meses.indice(de: $0.mes)
            let mesB = Meses.indice(de: $1.mes)
            if mesA != mesB { return mesA < mesB }
            return ($0.nomeDespesa ?? "") < ($1.nomeDespesa ?? "")
        }
    }

    func save(despesa: Despesa?, nome: String, valor: Double, mes: String, emailUsuario: String) throws {
        let current = despesa ?? Despesa(context: context)

        if despesa == nil {
            current.id = UUID()
            current.emailUsuario = emailUsuario
        }

        current.nomeDespesa = nome
        current.valorDespesa = Float(valor)
        current.mes = mes
        current.logoIdentificador = LogoCatalog.resolver(nome: nome)

        try context.save()
    }

    
    func delete(_ despesa: Despesa) throws {
        context.delete(despesa)
        try context.save()
    }

   
    func resumo(emailUsuario: String) throws -> DashboardSummary {
        let itens = try fetchAll(emailUsuario: emailUsuario)

        let totalMensal = itens.reduce(0.0) { $0 + Double($1.valorDespesa) }
        let agrupado = Dictionary(grouping: itens) { $0.mes ?? "Não informado" }
        let porMes = agrupado.map { chave, valores in
            MonthlyTotal(
                month: chave,
                total: valores.reduce(0.0) { $0 + Double($1.valorDespesa) }
            )
        }
        .sorted { Meses.indice(de: $0.month) < Meses.indice(de: $1.month) }

        return DashboardSummary(
            totalAssinaturas: itens.count,
            totalMensal: totalMensal,
            porMes: porMes,
            itens: itens
        )
    }
}
