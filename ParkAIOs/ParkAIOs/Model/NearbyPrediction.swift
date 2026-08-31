import Foundation

struct NearbyPredictionResponse: Codable {
    let streetName: String
    let latitude: Double
    let longitude: Double
    let estimatedAvailabilityPercent: Int
    let level: String   // "LOW" | "MEDIUM" | "HIGH"
    let source: String  

    var color: Color {
        switch level {
        case "HIGH": return .green
        case "MEDIUM": return .orange
        case "LOW": return .red
        default: return .gray
        }
    }
}

import SwiftUI
