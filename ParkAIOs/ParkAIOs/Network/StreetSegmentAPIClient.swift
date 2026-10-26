import Foundation
import CoreLocation

struct SegmentCoordinate: Decodable {
    let latitude: Double
    let longitude: Double

    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct StreetSegmentGeometry: Decodable, Identifiable {
    let id: Int64
    let streetName: String
    // Punto central IDENTICO al usado por /api/predictions/nearby
    let latitude: Double
    let longitude: Double
    // Eje real de la calle, con sus curvas.
    let coordinates: [SegmentCoordinate]
}

enum StreetSegmentAPIClient {
    static func getNearby(latitude: Double, longitude: Double) async throws -> [StreetSegmentGeometry] {
        let query = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude))
        ]
        let (_, data) = try await APIClient.get(
            path: "api/map/nearby-segments",
            queryItems: query,
            authToken: TokenManager.getToken().map { "Bearer \($0)" },
            responseType: [StreetSegmentGeometry].self
        )
        return data ?? []
    }
}
