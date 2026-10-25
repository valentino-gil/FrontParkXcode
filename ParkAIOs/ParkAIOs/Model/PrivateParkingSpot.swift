
import Foundation

struct PrivateParkingSpot: Codable, Identifiable {
    let id: Int64
    let name: String
    let address: String
    let neighborhood: String?
    let source: String
    let latitude: Double
    let longitude: Double

    var sourceLabel: String {
        source == "CONCESSIONED"
            ? "Estacionamiento concesionado"
            : "Garaje comercial"
    }
}

enum PrivateParkingAPIClient {

    static func getNearby(
        latitude: Double,
        longitude: Double
    ) async -> [PrivateParkingSpot] {

        let query = [
            URLQueryItem(
                name: "latitude",
                value: String(latitude)
            ),
            URLQueryItem(
                name: "longitude",
                value: String(longitude)
            )
        ]

        do {
            let (_, data) = try await APIClient.get(
                path: "api/parking/private/nearby",
                queryItems: query,
                authToken: TokenManager.getToken().map {
                    "Bearer \($0)"
                },
                responseType: [PrivateParkingSpot].self
            )

            return data ?? []

        } catch {
            print(
                "Error obteniendo estacionamientos: \(error)"
            )
            return []
        }
    }
}
