
import Foundation
import Combine


//ViewModel responsável pela lógica do formulário de cadastro/edição de despesas.
@MainActor
final class FormDespesasViewModel: ObservableObject {

    @Published var errorMessage: String?

    
     //Responsável por salvar uma despesa (nova ou existente).
    func salvar(
        despesa: Despesa?,
        nome: String,
        valor: Double,
        mes: String,
        emailUsuario: String,
        repository: AssinaturaRepositoryProtocol
    ) -> Bool {

        let nomeTratado = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        let mesTratado = mes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nomeTratado.isEmpty, valor > 0, !mesTratado.isEmpty else {
            errorMessage = "Preencha nome, valor e mês corretamente."
            return false
        }

        do {
            try repository.save(despesa: despesa, nome: nomeTratado, valor: valor, mes: mesTratado, emailUsuario: emailUsuario)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
 
