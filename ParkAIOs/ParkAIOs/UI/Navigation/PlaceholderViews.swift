import SwiftUI

// Estos son stubs temporales. Los vamos reemplazando 1 a 1
// a medida que migremos cada pantalla real de Android.











struct ReportViewPlaceholder: View {
    let streetName: String
    let latitude: Double
    let longitude: Double
    let authToken: String
    var onClose: () -> Void
    var onReportSent: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("Reportar (placeholder)")
            Text(streetName).foregroundColor(.gray)
            Button("Enviar reporte") { onReportSent() }
            Button("Cerrar") { onClose() }
        }
    }
}
