import Foundation

enum TimeOption: CaseIterable, Identifiable {
    case minus20, minus10, now, plus10, plus20

    var id: Self { self }

    var label: String {
        switch self {
        case .minus20: return "Hace 20 min"
        case .minus10: return "Hace 10 min"
        case .now: return "Ahora"
        case .plus10: return "En 10 min"
        case .plus20: return "En 20 min"
        }
    }

    var minuteOffset: Int {
        switch self {
        case .minus20: return -20
        case .minus10: return -10
        case .now: return 0
        case .plus10: return 10
        case .plus20: return 20
        }
    }

    // Devuelve (dayOfWeek, hour) en el formato que espera el backend:
    // Java DayOfWeek → MONDAY=1 ... SUNDAY=7
    func resolvedDayAndHour(from date: Date = Date()) -> (dayOfWeek: Int, hour: Int) {
        let targetDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: date) ?? date
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: targetDate) // domingo=1...sábado=7
        let javaDayOfWeek = ((weekday + 5) % 7) + 1 // convierte a lunes=1...domingo=7
        let hour = calendar.component(.hour, from: targetDate)
        return (javaDayOfWeek, hour)
    }
}
