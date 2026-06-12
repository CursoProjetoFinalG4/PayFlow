// Importa recursos básicos do sistema, como URL, erros e comunicação de rede.
import Foundation

// Este enum reúne os erros mais comuns que podem acontecer durante a chamada da API.
enum APIError: LocalizedError {

    // Indica que a string informada não conseguiu ser convertida em uma URL válida.
    case invalidURL

    // Indica que a resposta recebida não veio no formato HTTP esperado.
    case invalidResponse

    // Guarda o código HTTP retornado pelo servidor quando a requisição falha.
    case httpCode(Int)

    // Guarda o erro ocorrido ao tentar transformar o JSON no tipo esperado.
    case decoding(Error)

    /* Esta propriedade devolve uma mensagem mais amigável para cada tipo de erro.
       A ideia aqui é evitar mensagens técnicas demais e deixar o retorno mais claro,
       principalmente quando o erro precisar ser mostrado na interface ou registrado
       de forma mais compreensível durante os testes. */
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida."
        case .invalidResponse:
            return "Resposta inválida do servidor."
        case .httpCode(let code):
            return "Erro HTTP \(code)."
        case .decoding:
            return "Erro ao processar os dados da API."
        }
    }
}

// Esta classe centraliza as chamadas HTTP e o processamento básico das respostas da API.
final class APIClient {

    /* Este método faz uma requisição GET para a URL informada e tenta converter
       o retorno para o tipo esperado.
       Primeiro ele valida se a URL foi montada corretamente.
       Depois executa a chamada na rede e confere se a resposta realmente veio como HTTP.
       Em seguida verifica se o servidor respondeu com sucesso.
       Se estiver tudo certo, o JSON recebido é convertido para o tipo informado.
       Caso algo falhe no caminho, o método lança um erro específico para facilitar
       a identificação do problema. */
    func get<T: Decodable>(_ urlString: String, as type: T.Type) async throws -> T {

        // Guarda a URL convertida a partir do texto recebido no parâmetro.
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        // Guarda os dados retornados pela API e também a resposta bruta da requisição.
        let (data, response) = try await URLSession.shared.data(from: url)

        // Mantém a resposta já convertida para o tipo HTTP, permitindo acessar o status code.
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Confere se o servidor respondeu com um código de sucesso.
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpCode(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
 
