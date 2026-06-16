
import Foundation
import CoreData
import Combine


@MainActor
final class CadastroViewModel: ObservableObject {

    @Published var errorMessage: String?

    
     //Realiza a exclusão de uma ou mais despesas.
    func deleteDespesa(
        _ itens: [Despesa],
        repository: AssinaturaRepositoryProtocol
    ) {
        do {
            for despesa in itens {
                try repository.delete(despesa)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
