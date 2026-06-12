/*
Importa o Foundation, necessário para manipulação de strings,
validações e estruturas básicas da linguagem.
*/
import Foundation

/*
Importa o Combine, utilizado para suporte a propriedades observáveis (@Published),
permitindo que a View reaja às mudanças do ViewModel.
*/
import Combine

/*
ViewModel responsável pela lógica do formulário de cadastro/edição de despesas.

Ele centraliza:
- validação dos dados informados pelo usuário
- chamada ao repositório para persistência
- controle de erro para feedback na UI
*/
@MainActor
final class FormDespesasViewModel: ObservableObject {

    // armazena mensagens de erro para serem exibidas na interface
    @Published var errorMessage: String?

    /*
     Responsável por salvar uma despesa (nova ou existente).

     Parâmetros:
     - despesa: caso exista, indica edição; se nil, será uma nova despesa
     - nome: nome informado pelo usuário
     - valor: valor da despesa
     - mes: mês de referência
     - repository: camada responsável pela persistência dos dados

     Fluxo do método:
     1. Realiza o tratamento básico das strings (trim)
     2. Valida os campos obrigatórios
     3. Se válido, chama o repository para salvar
     4. Em caso de erro, captura a mensagem para exibir na UI

     Retorno:
     - true: quando o salvamento ocorre com sucesso
     - false: quando há erro de validação ou falha na persistência
    */
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
 
