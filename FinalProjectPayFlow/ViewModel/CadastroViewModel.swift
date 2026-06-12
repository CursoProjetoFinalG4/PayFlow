/*
Importa o Foundation, base para funcionalidades essenciais da linguagem,
como tratamento de erros e tipos básicos.
*/
import Foundation

/*
Importa o CoreData para permitir manipulação de dados persistidos.
*/
import CoreData

/*
Importa o Combine, utilizado para trabalhar com propriedades reativas (@Published).
*/
import Combine

/*
ViewModel responsável pelas ações relacionadas ao cadastro de despesas.

Ele atua como intermediário entre a View e a camada de repositório,
centralizando regras simples como exclusão e tratamento de erro.
*/
@MainActor
final class CadastroViewModel: ObservableObject {

    // armazena mensagem de erro para ser exibida na UI, caso algo falhe
    @Published var errorMessage: String?

    /*
     Realiza a exclusão de uma ou mais despesas.

     Parâmetros:
     - itens: despesas selecionadas na lista para remoção
     - repository: responsável por executar a operação no CoreData

     Receber os objetos diretamente (em vez de índices) garante que a exclusão
     continua correta mesmo quando a lista exibida está reordenada na tela.

     O método tenta executar a exclusão via repository.
     Caso ocorra erro, a mensagem é capturada e atribuída ao errorMessage,
     permitindo que a interface reaja exibindo o problema ao usuário.
    */
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
