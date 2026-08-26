import SwiftUI

struct ReportView: View {
    let streetName: String
    let latitude: Double
    let longitude: Double
    let authToken: String
    var onClose: () -> Void = {}
    var onReportSent: () -> Void = {}

    @State private var selectedOption: AvailabilityOption?
    @State private var comment = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let borderColor = Color(hex: 0xE5E7EB)
    private let grayText = Color(hex: 0x6B7280)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 16)

                ZStack {
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    Text("Reportar disponibilidad")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.parkaiBlueDark)
                }

                Spacer().frame(height: 8)

                Text("Tu reporte ayuda a toda la comunidad\na encontrar lugar más fácil.")
                    .font(.system(size: 13))
                    .foregroundColor(grayText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Spacer().frame(height: 20)

                // Card con la ubicación seleccionada
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ubicación seleccionada")
                        .font(.system(size: 12))
                        .foregroundColor(grayText)
                    Text(streetName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.parkaiBlueDark)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: 1)
                )

                Spacer().frame(height: 20)

                Text("¿Cómo está el estacionamiento acá?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.parkaiBlueDark)
                Text("Seleccioná la opción que mejor represente la situación actual.")
                    .font(.system(size: 13))
                    .foregroundColor(grayText)

                Spacer().frame(height: 12)

                ForEach(AvailabilityOption.allCases) { option in
                    AvailabilityOptionRow(
                        option: option,
                        isSelected: selectedOption == option,
                        onTap: { selectedOption = option }
                    )
                    .padding(.vertical, 6)
                }

                Spacer().frame(height: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    TextField("Agregá un comentario (opcional)", text: $comment)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .onChange(of: comment) { _, newValue in
                            if newValue.count > 120 {
                                comment = String(newValue.prefix(120))
                            }
                        }
                    Text("\(comment.count)/120")
                        .font(.system(size: 12))
                        .foregroundColor(grayText)
                }

                Spacer().frame(height: 12)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "shield")
                        .foregroundColor(.parkaiBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tu reporte es anónimo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.parkaiBlueDark)
                        Text("No se publica tu nombre ni datos personales.")
                            .font(.system(size: 11))
                            .foregroundColor(grayText)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xEFF6FF))
                .cornerRadius(14)

                if let errorMessage {
                    Spacer().frame(height: 12)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 13))
                }

                Spacer().frame(minHeight: 20)

                Button(action: sendReport) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                            Text("Enviar reporte")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.parkaiBlue)
                    .cornerRadius(14)
                }
                .disabled(selectedOption == nil || isLoading)

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.white)
    }

    private func sendReport() {
        guard let selectedOption else { return }
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let request = CreateParkingReportRequest(
                    streetName: streetName,
                    latitude: latitude,
                    longitude: longitude,
                    reportType: selectedOption.reportType
                )
                let (statusCode, _) = try await ParkingReportAPIClient.createReport(
                    token: "Bearer \(authToken)",
                    request: request
                )

                if (200...299).contains(statusCode) {
                    onReportSent()
                } else {
                    errorMessage = "No se pudo enviar el reporte (\(statusCode))."
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

// ---------- Fila individual de opción ----------
private struct AvailabilityOptionRow: View {
    let option: AvailabilityOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(option.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(option.descriptionText)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x6B7280))
                }

                Spacer()

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .parkaiBlue : Color(hex: 0xE5E7EB))
                    .font(.system(size: 20))
            }
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.parkaiBlue : Color(hex: 0xE5E7EB), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReportView(streetName: "Av. Santa Fe 3200", latitude: -34.5875, longitude: -58.4205, authToken: "token")
}
