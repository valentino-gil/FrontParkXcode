import SwiftUI
import CoreLocation

private enum HistoryTab { case searches, parkings, reports }

struct HistoryView: View {
    var onBackClick: () -> Void = {}
    var onSelect: (FavoritePlace) -> Void = { _ in }

    @State private var tab: HistoryTab = .searches
    @State private var items: [SearchHistoryItem] = []
    @State private var isLoading = true
    @State private var images: [String: UIImage] = [:]
    @State private var availability: [String: (percent: Int, level: String)] = [:]
    @State private var reports: [ParkingReportResponse] = []

    private var sections: [(title: String, items: [SearchHistoryItem])] {
        let calendar = Calendar.current
        var today: [SearchHistoryItem] = []
        var yesterday: [SearchHistoryItem] = []
        var week: [SearchHistoryItem] = []
        var older: [SearchHistoryItem] = []

        for item in items {
            guard let date = item.date else { older.append(item); continue }
            if calendar.isDateInToday(date) {
                today.append(item)
            } else if calendar.isDateInYesterday(date) {
                yesterday.append(item)
            } else if let days = calendar.dateComponents([.day], from: date, to: Date()).day, days < 7 {
                week.append(item)
            } else {
                older.append(item)
            }
        }
        return [("Hoy", today), ("Ayer", yesterday), ("Última semana", week), ("Anterior", older)]
            .filter { !$0.1.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer().frame(height: 16)
                tabs
                Spacer().frame(height: 12)

                if tab == .parkings {
                    comingSoon
                } else if tab == .reports {
                    reportsList
                } else if isLoading && items.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 80)
                } else if items.isEmpty {
                    emptyState
                } else {
                    ForEach(sections, id: \.title) { section in
                        Text(section.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.parkaiGray)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        VStack(spacing: 10) {
                            ForEach(section.items) { item in
                                row(for: item)
                            }
                        }
                    }
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.white)
        .task { await load() }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBackClick) {
                    Image(systemName: "arrow.left").foregroundColor(.parkaiBlueDark)
                }
            }
        }
    }

    // MARK: - Secciones

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.parkaiBlue)
                .frame(width: 52, height: 52)
                .overlay(Circle().stroke(Color.parkaiBlue, lineWidth: 3))
            VStack(alignment: .leading, spacing: 3) {
                Text("Historial")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.parkaiBlueDark)
                Text("Tus búsquedas y ubicaciones recientes")
                    .font(.system(size: 14))
                    .foregroundColor(.parkaiGray)
            }
        }
        .padding(.top, 8)
    }

    private var tabs: some View {
        HStack(spacing: 8) {
            chip("Búsquedas", icon: "clock", selected: tab == .searches) { tab = .searches }
            chip("Estacionamientos", icon: "car.fill", selected: tab == .parkings) { tab = .parkings }
            chip("Reportes", icon: "flag", selected: tab == .reports) { tab = .reports }
        }
    }

    private func chip(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(title).lineLimit(1).minimumScaleFactor(0.8)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(selected ? .parkaiBlue : .parkaiBlueDark)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(selected ? Color(hex: 0xEFF6FF) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.parkaiBlue.opacity(0.6) : Color.parkaiGray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var emptyState: some View {
        placeholder(icon: "clock", title: "Todavía no tenés búsquedas",
                    text: "Buscá una dirección en el mapa y va a aparecer acá.")
    }

    private var comingSoon: some View {
        placeholder(icon: "hourglass", title: "Próximamente",
                    text: "Esta sección todavía no está disponible.")
    }

    private func placeholder(icon: String, title: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 44)).foregroundColor(.parkaiGray)
            Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.parkaiBlueDark)
            Text(text).font(.system(size: 14)).foregroundColor(.parkaiGray).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 20)
    }
    
    private var reportsList: some View {
        Group {
            if reports.isEmpty {
                placeholder(icon: "flag", title: "Todavía no hiciste reportes",
                            text: "Cuando reportes cómo está el estacionamiento, va a aparecer acá.")
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(reports.enumerated()), id: \.offset) { _, report in
                        reportRow(report)
                    }
                }
                .padding(.top, 8)
            }
        }
        .task { await loadReports() }
    }

    private func reportRow(_ report: ParkingReportResponse) -> some View {
        let found = report.reportType == "FOUND"
        let color = found ? Color(hex: 0x16A34A) : Color(hex: 0xEF4444)
        return HStack(spacing: 12) {
            Image(systemName: found ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(report.streetName ?? "Ubicación")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.parkaiBlueDark)
                Text(found ? "Encontré lugar" : "No encontré lugar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                Text("\(relativeText(reportDate(report.reportTime))) · Reporte")
                    .font(.system(size: 12))
                    .foregroundColor(.parkaiGray)
            }
            Spacer()
        }
        .padding(12)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.parkaiGray.opacity(0.25), lineWidth: 1))
    }

    private func reportDate(_ text: String?) -> Date? {
        guard let text else { return nil }
        let base = text.split(separator: ".").first.map(String.init) ?? text
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: base)
    }

    private func loadReports() async {
        reports = (try? await ParkingReportAPIClient.getMyReports()) ?? []
    }

    // MARK: - Fila

    private func row(for item: SearchHistoryItem) -> some View {
        let info = availability[item.id]
        let color = levelColor(info?.level)

        return HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = images[item.id] {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Color.parkaiGray.opacity(0.15).overlay(ProgressView())
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if let info {
                    Text("\(info.percent)%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.18))
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.placeName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.parkaiBlueDark)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(levelText(info?.level))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color)
                }
                Text("\(relativeText(item.date)) · Búsqueda")
                    .font(.system(size: 12))
                    .foregroundColor(.parkaiGray)
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.parkaiBlueDark)
        }
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.parkaiGray.opacity(0.25), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect(item.asPlace) }
    }

    // MARK: - Helpers

    private func levelColor(_ level: String?) -> Color {
        switch level {
        case "HIGH": return Color(hex: 0x16A34A)
        case "MEDIUM": return Color(hex: 0xF59E0B)
        case "LOW": return Color(hex: 0xEF4444)
        default: return .parkaiGray
        }
    }

    private func levelText(_ level: String?) -> String {
        switch level {
        case "HIGH": return "Alta disponibilidad"
        case "MEDIUM": return "Disponibilidad media"
        case "LOW": return "Baja disponibilidad"
        default: return "Sin datos suficientes"
        }
    }

    private func relativeText(_ date: Date?) -> String {
        guard let date else { return "" }
        let seconds = Int(Date().timeIntervalSince(date))
        let calendar = Calendar.current
        if seconds < 60 { return "Ahora" }
        if seconds < 3600 { return "Hace \(seconds / 60) min" }
        if calendar.isDateInToday(date) { return "Hace \(seconds / 3600) h" }
        if calendar.isDateInYesterday(date) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"
            return "Ayer \(f.string(from: date))"
        }
        return "Hace \(seconds / 86400) días"
    }

    // MARK: - Carga

    private func load() async {
        do {
            let all = try await SearchHistoryAPIClient.getHistory()
            // "Mi ubicación" lo genera la app sola al cargar el mapa, no es una búsqueda del usuario
            items = all.filter { $0.placeName != "Mi ubicación" }
        } catch {
            print("❌ Error cargando historial: \(error)")
        }
        isLoading = false

        let (dayOfWeek, hour) = TimeOption.now.resolvedDayAndHour()
        for item in items {
            if images[item.id] == nil,
               let image = await PlaceImageLoader.load(for: item.asPlace, size: CGSize(width: 252, height: 252)) {
                images[item.id] = image
            }
            if availability[item.id] == nil,
               let prediction = try? await ParkingPredictionAPIClient.getPrediction(
                    streetName: item.placeName,
                    latitude: item.latitude,
                    longitude: item.longitude,
                    dayOfWeek: dayOfWeek,
                    hour: hour
               ) {
                availability[item.id] = (prediction.estimatedAvailabilityPercent, prediction.level)
            }
        }
    }
}

#Preview {
    HistoryView()
}
