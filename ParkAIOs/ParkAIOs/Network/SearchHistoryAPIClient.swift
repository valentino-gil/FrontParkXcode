import Foundation

enum SearchHistoryAPIClient {
    static func getHistory() async throws -> [SearchHistoryItem] {
        guard let token = TokenManager.getToken() else { return [] }
        let (_, data) = try await APIClient.get(
            path: "api/search-history",
            queryItems: [],
            authToken: "Bearer \(token)",
            responseType: [SearchHistoryItem].self
        )
        return data ?? []
    }
}
