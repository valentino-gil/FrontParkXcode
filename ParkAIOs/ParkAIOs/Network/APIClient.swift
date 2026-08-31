import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingFailed
}

enum APIClient {

    static let baseURL = "http://localhost:8080/"

    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    static func post<Req: Encodable, Res: Decodable>(
        path: String,
        body: Req,
        responseType: Res.Type,
        authToken: String? = nil
    ) async throws -> (statusCode: Int, data: Res?) {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authToken {
            request.setValue(authToken, forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // 👇 Debug: mostrá siempre lo que llega crudo del backend
        print("📥 [\(path)] status: \(httpResponse.statusCode)")
        print("📥 [\(path)] body: \(String(data: data, encoding: .utf8) ?? "no legible")")

        if (200...299).contains(httpResponse.statusCode) {
            do {
                let decoded = try decoder.decode(Res.self, from: data)
                return (httpResponse.statusCode, decoded)
            } catch {
                // 👇 Ahora sí vas a ver EXACTAMENTE por qué falla el decode
                print("❌ Error decodificando \(Res.self): \(error)")
                return (httpResponse.statusCode, nil)
            }
        } else {
            return (httpResponse.statusCode, nil)
        }
    }

    static func postNoContent<Req: Encodable>(
        path: String,
        body: Req,
        authToken: String? = nil
    ) async throws -> Int {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authToken {
            request.setValue(authToken, forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try encoder.encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        return httpResponse.statusCode
    }
    
    static func get<Res: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        authToken: String? = nil,
        responseType: Res.Type
    ) async throws -> (statusCode: Int, data: Res?) {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let authToken {
            request.setValue(authToken, forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) {
            let decoded = try? decoder.decode(Res.self, from: data)
            return (httpResponse.statusCode, decoded)
        } else {
            return (httpResponse.statusCode, nil)
        }
    }
}
