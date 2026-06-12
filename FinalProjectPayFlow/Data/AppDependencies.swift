// Importa recursos básicos do sistema usados em tipos e estruturas de apoio.
import Foundation

// Importa o Core Data para permitir o uso do contexto de persistência.
import CoreData

// Importa o Combine, necessário para publicação de mudanças observadas pela interface.
import Combine

// Essa classe reúne as dependências principais do app em um único lugar.
// O ObservableObject já fornece o objectWillChange automaticamente.
@MainActor
final class AppDependencies: ObservableObject {

    // Guarda a implementação responsável pelas regras e operações de autenticação.
    let authRepository: AuthRepositoryProtocol

    // Guarda a implementação responsável por buscar e fornecer os dados de preços.
    let pricingRepository: PricingRepositoryProtocol

    /* Este inicializador recebe as dependências principais da aplicação e salva cada uma delas.
       A ideia aqui é deixar a classe pronta para distribuir esses serviços para outras partes do app,
       evitando que cada tela ou camada precise criar suas próprias instâncias.
       Isso também facilita bastante a troca por versões falsas em testes. */
    init(
        authRepository: AuthRepositoryProtocol,
        pricingRepository: PricingRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.pricingRepository = pricingRepository
    }

    /* Este método cria o repositório de assinaturas já ligado ao contexto informado.
       Na prática, ele funciona como um ponto central para montar essa dependência do jeito certo,
       sem espalhar a criação do repositório em vários lugares do projeto.
       Assim, quem precisar trabalhar com assinaturas só pede a instância pronta. */
    func makeAssinaturaRepository(context: NSManagedObjectContext) -> AssinaturaRepositoryProtocol {
        CoreDataAssinaturaRepository(context: context)
    }

    // Mantém a configuração padrão usada pelo aplicativo em execução normal.
    static let live = AppDependencies(
        authRepository: FakeAuthRepository(),
        pricingRepository: RemotePricingRepository(apiClient: APIClient())
    )
}
 
