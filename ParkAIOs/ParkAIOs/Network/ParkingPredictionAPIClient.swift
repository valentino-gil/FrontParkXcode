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
    
    static func getPrediction(
        streetName: String,
        latitude: Double,
        longitude: Double,
        dayOfWeek: Int,
        hour: Int
    ) async throws -> PredictionResponse? {
        let query = [
            URLQueryItem(name: "streetName", value: streetName),
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "dayOfWeek", value: "\(dayOfWeek)"),
            URLQueryItem(name: "hour", value: "\(hour)")
        ]
        let (_, data) = try await APIClient.get(
            path: "api/predictions",
            queryItems: query,
            authToken: TokenManager.getToken().map { "Bearer \($0)" },
            responseType: PredictionResponse.self
        )
        return data
    }
}
