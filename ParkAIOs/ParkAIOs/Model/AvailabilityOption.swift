import SwiftUI


enum AvailabilityOption: CaseIterable, Identifiable {
    case many
    case few
    case full

    var id: Self { self }

    var label: String {
        switch self {
        case .many: return "Hay varios lugares"
        case .few: return "Hay pocos lugares"
        case .full: return "Está casi lleno"
        }
    }

    var descriptionText: String {
        switch self {
        case .many: return "Es fácil encontrar lugar para estacionar."
        case .few: return "Cuesta encontrar lugar."
        case .full: return "Muy difícil encontrar lugar."
        }
    }

    var color: Color {
        switch self {
        case .many: return Color(hex: 0x22C55E)
        case .few: return Color(hex: 0xF59E0B)
        case .full: return Color(hex: 0xEF4444)
        }
    }

    // decisión: "cuesta" pero todavía se encuentra. Cambiá a "NOT_FOUND" si preferís lo contrario
    var reportType: String {
        switch self {
        case .many: return "FOUND"
        case .few: return "FOUND"
        case .full: return "NOT_FOUND"
        }
    }
}
