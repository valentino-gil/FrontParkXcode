import SwiftUI
import MapKit
import CoreLocation

private enum FavoritesFilter { case all, publicStreet, privateParking }

struct FavoritesView: View {
    var onBackClick: () -> Void = {}
    var onSelect: (FavoritePlace) -> Void = { _ in }
    var onDetail: (FavoritePlace) -> Void = { _ in }

    @ObservedObject private var store = FavoritesStore.shared
    @StateObject private var locationManager = LocationManager()

    @State private var filter: FavoritesFilter = .all
    @State private var isEditing = false
    @State private var showTip = true
    @State private var images: [String: UIImage] = [:]
    @State private var availability: [String: (percent: Int, level: String)] = [:]

    private var visible: [FavoritePlace] {
        switch filter {
        case .all, .publicStreet: return store.favorites
        case .privateParking: return []
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                Spacer().frame(height: 16)
                filterTabs
                Spacer().frame(height: 16)

                if visible.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(visible) { place in
                            card(for: place)
                        }
                    }
                }

                if showTip && !visible.isEmpty {
                    Spacer().frame(height: 12)
                    tipBanner
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.white)
        .task {
            if locationManager.authorizationStatus == .authorizedWhenInUse
                || locationManager.authorizationStatus == .authorizedAlways {
                locationManager.requestCurrentLocation()
            }
            await store.refresh()
            await loadExtras()
        }
        .onChange(of: store.favorites.count) { _, _ in
            Task { await loadExtras() }
        }
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mis favoritos")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.parkaiBlueDark)
                Text("Tus lugares guardados para acceder rápido.")
                    .font(.system(size: 14))
                    .foregroundColor(.parkaiGray)
            }
            Spacer()
            Button(action: { isEditing.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                    Text(isEditing ? "Listo" : "Editar")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.parkaiBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.parkaiGray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.top, 8)
    }

    private var filterTabs: some View {
        HStack(spacing: 0) {
            tab(title: "Todos (\(store.favorites.count))", icon: "heart", selected: filter == .all) { filter = .all }
            tab(title: "Vía pública (\(store.favorites.count))", icon: "p.circle.fill", selected: filter == .publicStreet) { filter = .publicStreet }
            tab(title: "Privados (0)", icon: "e.circle.fill", selected: filter == .privateParking) { filter = .privateParking }
        }
        .padding(2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.parkaiGray.opacity(0.3), lineWidth: 1)
        )
    }

    private func tab(title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(title).lineLimit(1).minimumScaleFactor(0.8)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(selected ? .parkaiBlue : .parkaiBlueDark)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(selected ? Color(hex: 0xEFF6FF) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.parkaiBlue.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(.parkaiGray)
            Text(filter == .privateParking ? "Todavía no hay estacionamientos privados guardados" : "Todavía no guardaste lugares")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.parkaiBlueDark)
                .multilineTextAlignment(.center)
            Text("Buscá una dirección en el mapa y tocá el corazón para guardarla.")
                .font(.system(size: 14))
                .foregroundColor(.parkaiGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 20)
    }

    private var tipBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "heart").foregroundColor(.parkaiBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Consejo")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.parkaiBlue)
                Text("Organizá tus favoritos por cercanía para encontrarlos más rápido.")
                    .font(.system(size: 12))
                    .foregroundColor(.parkaiGray)
            }
            Spacer()
            Button(action: { showTip = false }) {
                Image(systemName: "xmark").foregroundColor(.parkaiBlue)
            }
        }
        .padding(14)
        .background(Color(hex: 0xEFF6FF))
        .cornerRadius(14)
    }

    // MARK: - Tarjeta

    private func card(for place: FavoritePlace) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let image = images[place.id] {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.parkaiGray.opacity(0.15)
                            .overlay(ProgressView())
                    }
                }
                .frame(width: 80, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Text("P")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(Color(hex: 0x16A34A))
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.parkaiBlueDark)
                        .lineLimit(2)
                    Spacer()
                    if isEditing {
                        Button(action: { Task { await store.remove(place) } }) {
                            Image(systemName: "trash").foregroundColor(.red)
                        }
                    } else {
                        Menu {
                            Button("Ver detalle") { onDetail(place) }
                            Button("Ver en el mapa") { onSelect(place) }
                            Button("Eliminar", role: .destructive) {
                                Task { await store.remove(place) }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.parkaiBlueDark)
                                .frame(width: 28, height: 20)
                        }
                    }
                }

                Text("Estacionamiento en vía pública")
                    .font(.system(size: 12))
                    .foregroundColor(.parkaiGray)

                availabilityRow(for: place)

                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "clock").font(.system(size: 11))
                        Text(timeText)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.parkaiGray)

                    Spacer()

                    if let distance = distanceText(to: place) {
                        HStack(spacing: 4) {
                            Text(distance)
                            Image(systemName: "figure.walk")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.parkaiBlueDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.parkaiGray.opacity(0.12))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.parkaiGray.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { if !isEditing { onSelect(place) } }
    }

    private func availabilityRow(for place: FavoritePlace) -> some View {
        let info = availability[place.id]
        let color = levelColor(info?.level)
        return HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(levelText(info?.level, percent: info?.percent))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
        }
    }

    // MARK: - Helpers

    private var timeText: String {
        let (_, hour) = TimeOption.now.resolvedDayAndHour()
        return String(format: "Estimación hoy, %02d:00", hour)
    }

    private func levelColor(_ level: String?) -> Color {
        switch level {
        case "HIGH": return Color(hex: 0x16A34A)
        case "MEDIUM": return Color(hex: 0xF59E0B)
        case "LOW": return Color(hex: 0xEF4444)
        default: return .parkaiGray
        }
    }

    private func levelText(_ level: String?, percent: Int?) -> String {
        let suffix = percent.map { " (\($0)%)" } ?? ""
        switch level {
        case "HIGH": return "Alta disponibilidad\(suffix)"
        case "MEDIUM": return "Media disponibilidad\(suffix)"
        case "LOW": return "Baja disponibilidad\(suffix)"
        default: return "Calculando..."
        }
    }

    private func distanceText(to place: FavoritePlace) -> String? {
        guard let user = locationManager.currentLocation else { return nil }
        let meters = CLLocation(latitude: user.latitude, longitude: user.longitude)
            .distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
        if meters < 1000 { return "\(Int(meters.rounded())) m" }
        return String(format: "%.1f km", meters / 1000)
    }

    // MARK: - Carga de fotos y disponibilidad

    private func loadExtras() async {
        let (dayOfWeek, hour) = TimeOption.now.resolvedDayAndHour()
        for place in store.favorites {
            if images[place.id] == nil, let image = await loadImage(for: place) {
                images[place.id] = image
            }
            if availability[place.id] == nil,
               let prediction = try? await ParkingPredictionAPIClient.getPrediction(
                    streetName: place.name,
                    latitude: place.latitude,
                    longitude: place.longitude,
                    dayOfWeek: dayOfWeek,
                    hour: hour
               ) {
                availability[place.id] = (prediction.estimatedAvailabilityPercent, prediction.level)
            }
        }
    }

    /// Intenta Look Around (foto a nivel de calle). Si no hay cobertura, usa vista satelital.
    private func loadImage(for place: FavoritePlace) async -> UIImage? {
        let coord = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        let size = CGSize(width: 240, height: 312)

        if let scene = try? await MKLookAroundSceneRequest(coordinate: coord).scene {
            let options = MKLookAroundSnapshotter.Options()
            options.size = size
            let snapshotter = MKLookAroundSnapshotter(scene: scene, options: options)
            if let snapshot = try? await snapshotter.snapshot {
                return snapshot.image
            }
        }

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coord, latitudinalMeters: 200, longitudinalMeters: 200)
        options.size = size
        options.mapType = .hybrid
        if let snapshot = try? await MKMapSnapshotter(options: options).start() {
            return snapshot.image
        }
        return nil
    }
}

#Preview {
    FavoritesView()
}
