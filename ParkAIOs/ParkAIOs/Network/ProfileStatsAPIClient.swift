
import Foundation

struct ProfileStatsResponse: Decodable {
    let favoritesCount: Int
    let reportsCount: Int
    let searchesCount: Int
}

enum ProfileStatsAPIClient {

    static func getStats() async throws -> ProfileStatsResponse {

        guard let token = TokenManager.getToken(),
              !token.isEmpty else {
            throw ProfileAPIError.noToken
        }

        let result = try await APIClient.get(
            path: "api/profile/stats",
            queryItems: [],
            authToken: "Bearer \(token)",
            responseType: ProfileStatsResponse.self
        )

        guard (200...299).contains(result.statusCode),
              let stats = result.data else {
            throw ProfileAPIError.serverError(result.statusCode)
        }

        return stats
    }
}
