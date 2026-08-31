import Foundation

enum ParkingPredictionAPIClient {

    static func getNearbyPredictions(
        placeName: String,
        latitude: Double,
        longitude: Double,
        dayOfWeek: Int,
        hour: Int
    ) async throws -> [NearbyPredictionResponse] {
        let query = [
            URLQueryItem(name: "placeName", value: placeName),
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "dayOfWeek", value: "\(dayOfWeek)"),
            URLQueryItem(name: "hour", value: "\(hour)")
        ]

        let token = TokenManager.getToken()
        let authHeader = token.map { "Bearer \($0)" }

        let (_, data) = try await APIClient.get(
            path: "api/predictions/nearby",
            queryItems: query,
            authToken: authHeader,
            responseType: [NearbyPredictionResponse].self
        )
        return data ?? []
    }
}
