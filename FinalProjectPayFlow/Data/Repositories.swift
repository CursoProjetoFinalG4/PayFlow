// Importa recursos básicos do sistema, como UUID, protocolos de erro e utilitários gerais.
import Foundation

// Importa o Core Data, usado aqui para buscar, salvar e remover registros locais.
import CoreData

/* Fonte única da lista de meses usada no app inteiro.
   Centralizar aqui evita listas duplicadas nas telas e permite
   ordenar os registros pela posição real do mês no calendário. */
enum Meses {
    static let todos = [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]

    /* Devolve a posição do mês no calendário, usada para ordenação cronológica.
       Meses desconhecidos (ou nulos) vão para o final da lista. */
    static func indice(de mes: String?) -> Int {
        guard let mes, let posicao = todos.firstIndex(of: mes) else {
            return todos.count
        }
        return posicao
    }
}

// Representa um serviço vindo da API remota, já pronto para leitura e exibição na interface.
struct RemoteService: Codable, Identifiable {
    // Identificador único do item retornado pela API.
    let id: Int

    // Nome/Título principal do serviço/produto.
    let title: String

    // Valor cobrado pelo serviço/produto.
    let price: Double

    // Categoria usada para classificar o item retornado.
    let category: String

    // Texto descritivo com mais detalhes sobre o item.
    let description: String
}

// Representa o total consolidado de despesas em um determinado mês.
struct MonthlyTotal: Identifiable {
    // Identificador local usado principalmente em listas do SwiftUI.
    let id = UUID()

    // Nome do mês ao qual o total pertence.
    let month: String

    // Soma dos valores cadastrados naquele mês.
    let total: Double
}

// Reúne os dados principais usados no resumo do painel.
struct DashboardSummary {
    // Quantidade total de assinaturas/despesas encontradas.
    let totalAssinaturas: Int

    // Soma geral dos valores mensais cadastrados.
    let totalMensal: Double

    // Totais agrupados por mês.
    let porMes: [MonthlyTotal]

    // Lista completa dos itens considerados no resumo.
    let itens: [Despesa]
}

// Define o contrato das operações de autenticação usadas pelo app.
protocol AuthRepositoryProtocol {
    /* Este método tenta autenticar o usuário a partir do email e da senha informados.
       A ideia do protocolo é deixar claro que qualquer implementação precisa saber
       validar essas credenciais e avisar quando algo der errado. */
    func login(email: String, password: String) async throws

    /* Este método cadastra um novo usuário com email e senha.
       Qualquer implementação precisa validar os dados e salvar o novo acesso. */
    func register(email: String, password: String) async throws
}

// Define o contrato das operações responsáveis por buscar preços ou serviços remotos.
protocol PricingRepositoryProtocol {
    /* Este método busca a lista de serviços disponíveis na fonte remota.
       Quem implementar esse protocolo precisa devolver os dados já convertidos
       para o formato que o app entende. */
    func fetchRemoteServices() async throws -> [RemoteService]
}

// Define o contrato das operações ligadas ao cadastro local de assinaturas.
protocol AssinaturaRepositoryProtocol {
    /* Busca apenas as despesas do usuário informado. */
    func fetchAll(emailUsuario: String) throws -> [Despesa]

    /* Salva ou atualiza uma despesa, associando-a ao usuário informado na criação. */
    func save(despesa: Despesa?, nome: String, valor: Double, mes: String, emailUsuario: String) throws

    /* Remove uma despesa específica do armazenamento. */
    func delete(_ despesa: Despesa) throws

    /* Monta resumo geral filtrando somente as despesas do usuário informado. */
    func resumo(emailUsuario: String) throws -> DashboardSummary
}

// Reúne os erros de autenticação tratados pela aplicação.
enum AuthError: LocalizedError {
    // Indica que as credenciais informadas não passaram na validação.
    case invalidCredentials

    // Indica que o email informado já foi cadastrado anteriormente.
    case emailAlreadyExists

    // Indica que os dados do cadastro não passaram na validação básica.
    case invalidRegistration

    /* Esta propriedade devolve a mensagem que pode ser mostrada para o usuário
       quando a autenticação falha. Assim o erro fica mais claro e direto. */
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

    // Chave usada para guardar os usuários cadastrados no aparelho.
    private let chaveUsuarios = "usuariosCadastrados"

    /* Este método simula um login sem depender de servidor real.
       Primeiro ele espera um pequeno intervalo para parecer uma chamada de rede.
       Depois valida se o email foi preenchido e confere a senha cadastrada.
       Se o usuário não existir, ainda aceita a senha de demonstração 123456. */
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

    /* Este método salva um novo usuário no aparelho.
       Ele valida os dados, confere se o email ainda não existe
       e grava email e senha no UserDefaults. */
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

    // Lê os usuários já cadastrados no aparelho.
    private func carregarUsuarios() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: chaveUsuarios) as? [String: String] ?? [:]
    }
}

// Implementação responsável por buscar serviços/preços a partir de uma API externa.
final class RemotePricingRepository: PricingRepositoryProtocol {
    // Cliente HTTP usado para fazer a comunicação com a API.
    private let apiClient: APIClient

    /* A fakestoreapi devolve os textos em inglês, mas seu catálogo é fixo
       (sempre os mesmos 20 produtos). Por isso dá para traduzir os nomes
       aqui com um dicionário simples, usando o id como chave. */
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

    // Traduções das quatro categorias usadas pela API.
    private let categoriasTraduzidas: [String: String] = [
        "men's clothing": "Moda Masculina",
        "women's clothing": "Moda Feminina",
        "jewelery": "Joias",
        "electronics": "Eletrônicos"
    ]

    /* Este inicializador recebe o cliente de API que será usado nas requisições.
       Isso evita acoplamento direto e facilita a troca da implementação em testes. */
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    /* Este método consulta a API remota, converte a resposta para a lista esperada,
       traduz os textos para português e devolve somente alguns itens.
       O corte no final ajuda a limitar a quantidade de dados mostrados no app. */
    func fetchRemoteServices() async throws -> [RemoteService] {
        // Guarda o endereço da API que será consultada.
        let url = "https://fakestoreapi.com/products"

        // Guarda os serviços retornados já convertidos para o tipo usado no app.
        let services = try await apiClient.get(url, as: [RemoteService].self)

        // Traduz os textos antes de exibir; itens desconhecidos mantêm o original.
        let traduzidos = services.map { traduzir($0) }

        // Embaralha os itens e pega até 6 resultados aleatórios.
        return Array(traduzidos.shuffled().prefix(6))
    }

    // Monta uma cópia do serviço com título e categoria em português.
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

// Implementação do repositório local baseada em Core Data.
final class CoreDataAssinaturaRepository: AssinaturaRepositoryProtocol {
    // Contexto usado para buscar, criar, editar e remover objetos persistidos.
    private let context: NSManagedObjectContext

    /* Este inicializador recebe o contexto do Core Data que será usado nas operações.
       Com isso, o repositório trabalha sempre sobre a mesma base de dados entregue pelo app. */
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /* Busca apenas as despesas do usuário informado, ordenadas cronologicamente. */
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

    /* Salva ou atualiza uma despesa. Na criação, grava também o email do dono do registro. */
    func save(despesa: Despesa?, nome: String, valor: Double, mes: String, emailUsuario: String) throws {
        let current = despesa ?? Despesa(context: context)

        if despesa == nil {
            current.id = UUID()
            current.emailUsuario = emailUsuario
        }

        current.nomeDespesa = nome
        current.valorDespesa = Float(valor)
        current.mes = mes

        try context.save()
    }

    /* Este método remove uma despesa específica e grava a alteração no contexto.
       Ele é a forma mais direta de exclusão quando o objeto já foi localizado antes. */
    func delete(_ despesa: Despesa) throws {
        context.delete(despesa)
        try context.save()
    }

    /* Este método monta um resumo geral a partir das despesas salvas.
       Primeiro ele busca todos os itens.
       Depois calcula o total mensal acumulado.
       Em seguida agrupa os registros por mês, soma os valores de cada grupo
       e organiza o resultado para facilitar o uso no dashboard. */
    func resumo(emailUsuario: String) throws -> DashboardSummary {
        let itens = try fetchAll(emailUsuario: emailUsuario)

        // Guarda a soma total dos valores de todas as despesas encontradas.
        let totalMensal = itens.reduce(0.0) { $0 + Double($1.valorDespesa) }

        // Guarda os itens agrupados pelo mês informado em cada registro.
        let agrupado = Dictionary(grouping: itens) { $0.mes ?? "Não informado" }

        // Guarda a lista de totais por mês já transformada no formato usado pela interface.
        let porMes = agrupado.map { chave, valores in
            MonthlyTotal(
                month: chave,
                total: valores.reduce(0.0) { $0 + Double($1.valorDespesa) }
            )
        }
        // Ordena pela posição do mês no calendário, e não alfabeticamente.
        .sorted { Meses.indice(de: $0.month) < Meses.indice(de: $1.month) }

        return DashboardSummary(
            totalAssinaturas: itens.count,
            totalMensal: totalMensal,
            porMes: porMes,
            itens: itens
        )
    }
}
