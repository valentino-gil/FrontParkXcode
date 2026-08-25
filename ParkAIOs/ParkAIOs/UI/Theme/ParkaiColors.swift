import SwiftUI

extension Color {
    /// Inicializador desde hex tipo 0xFF1B2A4A o 0x1B2A4A
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    // Paleta ParkAI (idéntica a Color.kt de Android)
    static let parkaiBlueDark = Color(hex: 0x1B2A4A)
    static let parkaiBlue = Color(hex: 0x3B6FE8)
    static let parkaiCyan = Color(hex: 0x4FD1E5)
    static let parkaiGray = Color(hex: 0x9AA3AF)
}
