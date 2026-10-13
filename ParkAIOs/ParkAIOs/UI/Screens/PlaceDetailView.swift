import SwiftUI
import MapKit
import CoreLocation

struct PlaceDetailView: View {
    let place: FavoritePlace
    var onBackClick: () -> Void = {}
    var onGoHereClick: () -> Void = {}
    var onReportClick: () -> Void = {}

    @ObservedObject private var store = FavoritesStore.shared
    @StateObject private var locationManager = LocationManager()
    @Environment(\.openURL) private var openURL

    @State private var image: UIImage?
    @State private var prediction: PredictionResponse?
    @State private var bestHour: (hour: Int, percent: Int)?

    private var isFavorite: Bool { store.isFavorite(place) }

    private var levelColor: Color {
        switch prediction?.level {
        case "HIGH": return Color(hex: 0x16A34A)
        case "MEDIUM": return Color(hex: 0xF59E0B)
        case "LOW": return Color(hex: 0xEF4444)
        default: return .parkaiGray
        }
    }

    private var levelText: String {
        switch prediction?.level {
        case "HIGH": return "Alta disponibilidad"
        case "MEDIUM": return "Media disponibilidad"
        case "LOW": return "Baja disponibilidad"
        default: return "Calculando..."
        }
    }

    private var sourceText: String {
        switch prediction?.source {
        case "python-sklearn-service": return "Modelo de aprendizaje automático con datos de tránsito, sensores y garages de la Ciudad."
        case "community-reports": return "Basado en los reportes de la comunidad en esta zona."
        case "heuristic": return "Estimación según el día y la hora (hay pocos datos de esta zona)."
        default: return "Basado en datos históricos, movilidad y reportes de la comunidad."
        }
    }

    private var hourText: String {
        let (_, hour) = TimeOption.now.resolvedDayAndHour()
        return String(format: "Estimación para hoy, %02d:00", hour)
    }

    private var distanceMeters: Double? {
        guard let user = locationManager.currentLocation else { return nil }
        return CLLocation(latitude: user.latitude, longitude: user.longitude)
            .distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
    }

    private var distanceText: String? {
        guard let m = distanceMeters else { return nil }
        return m < 1000 ? "\(Int(m.rounded())) m" : String(format: "%.1f km", m / 1000)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroImage

                VStack(alignment: .leading, spacing: 16) {
                    titleRow
                    availabilityCard

                    infoRow(icon: "mappin", title: placeTitle,
                            subtitle: distanceText.map { "A \($0) de tu ubicación" } ?? "Ubicación seleccionada",
                            trailing: distanceText.map { AnyView(distanceChip($0)) })
                    Divider()
                    infoRow(icon: "chart.bar.fill", title: "¿Cómo se calcula?", subtitle: sourceText)
                    Divider()
                    infoRow(icon: "clock", title: "Mejor horario estimado",
                            subtitle: bestHour.map { String(format: "Hoy a las %02d:00 (%d%%)", $0.hour, $0.percent) } ?? "Calculando...")
                    Divider()
                    Button(action: onReportClick) {
                        infoRow(icon: "plus", title: "Reportes recientes",
                                subtitle: "Reportá cómo está acá y ayudá a la comunidad",
                                trailing: AnyView(Image(systemName: "chevron.right").foregroundColor(.parkaiGray)))
                    }
                    .buttonStyle(.plain)

                    importantBanner
                    actionButtons

                    HStack(spacing: 4) {
                        Text("¿Problemas con la información?")
                            .foregroundColor(.parkaiGray)
                        Text("Reportar")
                            .fontWeight(.semibold)
                            .foregroundColor(.parkaiBlue)
                            .onTapGesture { onReportClick() }
                    }
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .offset(y: -24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .task { await load() }
    }

    // MARK: - Partes

    private var placeTitle: String {
        place.neighborhood.isEmpty ? place.name : "\(place.name), \(place.neighborhood)"
    }

    private var heroImage: some View {
        ZStack(alignment: .top) {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Color.parkaiGray.opacity(0.2).overlay(ProgressView())
                }
            }
            .frame(height: 260)
            .clipped()

            HStack {
                circleButton(icon: "chevron.left", color: .parkaiBlueDark, action: onBackClick)
                Spacer()
                circleButton(icon: isFavorite ? "heart.fill" : "heart", color: .parkaiBlue) {
                    Task { await store.toggle(place) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
        }
    }

    private func circleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.15), radius: 4)
        }
    }

    private var titleRow: some View {
        HStack(spacing: 14) {
            Text("P")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Color(hex: 0x16A34A))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(place.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.parkaiBlueDark)
                Text("Estacionamiento en vía pública")
                    .font(.system(size: 14))
                    .foregroundColor(.parkaiGray)
            }
        }
    }

    private var availabilityCard: some View {
        HStack(spacing: 16) {
            Text(prediction.map { "\($0.estimatedAvailabilityPercent)%" } ?? "--")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(levelColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(levelText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(levelColor)
                Text(hourText)
                    .font(.system(size: 13))
                    .foregroundColor(.parkaiGray)
            }
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(levelColor)
        }
        .padding(16)
        .background(levelColor.opacity(0.1))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(levelColor.opacity(0.25), lineWidth: 1))
    }

    private func infoRow(icon: String, title: String, subtitle: String, trailing: AnyView? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.parkaiBlue)
                .frame(width: 44, height: 44)
                .background(Color.parkaiGray.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.parkaiBlueDark)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.parkaiGray)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            if let trailing { trailing }
        }
        .contentShape(Rectangle())
    }

    private func distanceChip(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
            Image(systemName: "figure.walk")
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.parkaiBlueDark)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.parkaiGray.opacity(0.12))
        .cornerRadius(10)
    }

    private var importantBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield").foregroundColor(.parkaiBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Información importante")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.parkaiBlue)
                Text("La disponibilidad puede cambiar rápidamente.\nVerificá siempre al llegar.")
                    .font(.system(size: 12))
                    .foregroundColor(.parkaiGray)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(hex: 0xEFF6FF))
        .cornerRadius(14)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onGoHereClick) {
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.north.fill")
                        Text("Ir hacia allá").fontWeight(.semibold)
                    }
                    Text("Usar el mapa de ParkAI").font(.system(size: 11))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color.parkaiBlue)
                .cornerRadius(14)
            }

            Button(action: openGoogleMaps) {
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                        Text("Ver en Google Maps").fontWeight(.semibold)
                    }
                    Text("Abrir en Google Maps").font(.system(size: 11))
                }
                .foregroundColor(.parkaiBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.parkaiBlue, lineWidth: 1.5))
            }
        }
        .font(.system(size: 14))
    }

    // MARK: - Acciones y carga

    private func openGoogleMaps() {
        // Abre la app de Google Maps si está instalada; si no, abre el navegador.
        if let url = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(place.latitude),\(place.longitude)&travelmode=driving") {
            openURL(url)
        }
    }

    private func dayAndHour(offsetHours: Int) -> (Int, Int) {
        let date = Calendar.current.date(byAdding: .hour, value: offsetHours, to: Date()) ?? Date()
        let weekday = Calendar.current.component(.weekday, from: date)
        return (((weekday + 5) % 7) + 1, Calendar.current.component(.hour, from: date))
    }

    private func load() async {
        if locationManager.authorizationStatus == .authorizedWhenInUse
            || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestCurrentLocation()
        }

        async let photo = PlaceImageLoader.load(for: place, size: CGSize(width: 800, height: 520))

        let (dayOfWeek, hour) = TimeOption.now.resolvedDayAndHour()
        prediction = try? await ParkingPredictionAPIClient.getPrediction(
            streetName: place.name, latitude: place.latitude, longitude: place.longitude,
            dayOfWeek: dayOfWeek, hour: hour
        )

        // Mejor horario: la mejor de las próximas 6 horas
        let candidates = await withTaskGroup(of: (Int, Int)?.self) { group -> [(Int, Int)] in
            for offset in 1...6 {
                let (d, h) = dayAndHour(offsetHours: offset)
                group.addTask {
                    guard let p = try? await ParkingPredictionAPIClient.getPrediction(
                        streetName: place.name, latitude: place.latitude, longitude: place.longitude,
                        dayOfWeek: d, hour: h
                    ) else { return nil }
                    return (h, p.estimatedAvailabilityPercent)
                }
            }
            var results: [(Int, Int)] = []
            for await r in group { if let r { results.append(r) } }
            return results
        }
        if let best = candidates.max(by: { $0.1 < $1.1 }) {
            bestHour = (best.0, best.1)
        }

        image = await photo
    }
}

#Preview {
    PlaceDetailView(place: FavoritePlace(name: "Av. Santa Fe 3200", neighborhood: "Palermo", latitude: -34.5875, longitude: -58.4205))
}
