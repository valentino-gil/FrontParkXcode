import Foundation

// Respuesta de GET /api/predictions (estimateAvailability)
struct PredictionResponse: Codable {
    let latitude: Double
    let longitude: Double
    let dayOfWeek: Int
    let hour: Int
    let estimatedAvailabilityPercent: Int
    let level: String   // LOW | MEDIUM | HIGH
    let source: String
}   
