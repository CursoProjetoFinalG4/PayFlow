import Foundation
import CoreData
import Combine


@MainActor
final class AppDependencies: ObservableObject {

    let authRepository: AuthRepositoryProtocol
    let pricingRepository: PricingRepositoryProtocol

    init(
        authRepository: AuthRepositoryProtocol,
        pricingRepository: PricingRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.pricingRepository = pricingRepository
    }

    // Este método cria o repositório de assinaturas já ligado ao contexto informado.
        
    func makeAssinaturaRepository(context: NSManagedObjectContext) -> AssinaturaRepositoryProtocol {
        CoreDataAssinaturaRepository(context: context)
    }

    // Mantém a configuração padrão usada pelo aplicativo em execução normal.
    static let live = AppDependencies(
        authRepository: FakeAuthRepository(),
        pricingRepository: RemotePricingRepository(apiClient: APIClient())
    )
}
 
