import Foundation

struct PrivateParkingSpot: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let pricePerHour: Double?
}

// TODO: reemplazar por una llamada real a tu backend cuando exista el endpoint
// de estacionamientos privados (garages/playas). Por ahora, mock fijo.
enum PrivateParkingAPIClient {
    static func getNearby(latitude: Double, longitude: Double) async -> [PrivateParkingSpot] {
        [
            PrivateParkingSpot(name: "Garage Palermo", latitude: latitude + 0.002, longitude: longitude + 0.001, pricePerHour: 1500),
            PrivateParkingSpot(name: "Playa Santa Fe", latitude: latitude - 0.0015, longitude: longitude + 0.002, pricePerHour: 1200),
            PrivateParkingSpot(name: "Estacionamiento Central", latitude: latitude + 0.001, longitude: longitude - 0.0018, pricePerHour: 1800)
        ]
    }
}
