import Foundation

enum APIError: LocalizedError {

    case invalidURL
    case invalidResponse
    case httpCode(Int)
    case decoding(Error)

    // Esta propriedade devolve uma mensagem mais amigável para cada tipo de erro.
       
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

    func get<T: Decodable>(_ urlString: String, as type: T.Type) async throws -> T {

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

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
 
