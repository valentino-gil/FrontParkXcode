import SwiftUI
import MapKit
import CoreLocation
import UIKit

enum MapFilterMode {
    case publicStreet
    case privateParking
}

struct HomeView: View {
    var onReportClick: (_ streetName: String, _ latitude: Double, _ longitude: Double) -> Void = { _, _, _ in }
    
    @State private var showLocationAlert = false

    @StateObject private var locationManager = LocationManager()
    @State private var selectedNavItem: BottomNavItem = .mapa
    @State private var homeProfileImage: UIImage?
    @State private var homeAvatarKey = "default"
    @State private var searchText = ""
    @State private var filterMode: MapFilterMode = .publicStreet
    @State private var timeOption: TimeOption = .now
    @State private var showTimeMenu = false

    @State private var predictions: [NearbyPredictionResponse] = []
    @State private var privateSpots: [PrivateParkingSpot] = []
    @State private var searchedCoordinate: CLLocationCoordinate2D?
    var onFavoritesClick: () -> Void = {}

    @ObservedObject private var favorites = FavoritesStore.shared
    @State private var selectedPlace: FavoritePlace?
    @State private var selectedPercent: Int?
    @State private var selectedLevel: String?
    
    var onDetailClick: (FavoritePlace) -> Void = { _ in }

    @State private var route: MKRoute?
    @State private var pendingRoutePlace: FavoritePlace?
    
    var onHistoryClick: () -> Void = {}
    
    var onProfileClick: () -> Void = {}

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -34.5875, longitude: -58.4205),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )

    private var userName: String {
        UserSession.getName() ?? "Usuario"
    }

    /// Centro sobre el cual se piden predicciones: la búsqueda tiene prioridad,
    /// si no hay búsqueda usamos la ubicación actual.
    private var activeCenter: CLLocationCoordinate2D? {
        searchedCoordinate ?? locationManager.currentLocation
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    if let place = selectedPlace {
                        Marker(place.name, systemImage: "mappin", coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
                            .tint(Color.parkaiBlue)
                    }
                    
                    if let route {
                            MapPolyline(route.polyline)
                                .stroke(Color.parkaiBlue, lineWidth: 5)
                        }

                    if filterMode == .publicStreet {
                        ForEach(predictions, id: \.streetName) { prediction in
                            Annotation(prediction.streetName, coordinate: CLLocationCoordinate2D(latitude: prediction.latitude, longitude: prediction.longitude)) {
                                Circle()
                                    .fill(prediction.color)
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }
                    } else {
                        ForEach(privateSpots) { spot in
                            Annotation("", coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)) {
                                Image(systemName: "p.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.parkaiBlue)
                                    .background(Circle().fill(.white))
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)

                VStack {
                    topBar
                    Spacer()
                }

                // Leyenda de disponibilidad (solo en Vía pública)
                if filterMode == .publicStreet {
                    VStack {
                        HStack {
                            Spacer()
                            legendCard
                                .padding(.top, 190)
                                .padding(.trailing, 16)
                        }
                        Spacer()
                    }
                }

                // Botón de recentrar + botón de reportar
                VStack(spacing: 12) {
                    Spacer()
                    HStack {
                        Button(action: reportTapped) {
                            Text("+ Reportar")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.parkaiBlue)
                                .cornerRadius(24)
                        }
                        Spacer()
                        Button(action: recenterOnUser) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                                .frame(width: 48, height: 48)
                                .background(Color.parkaiBlue)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                    .padding(.horizontal, 20)

                    if let place = selectedPlace {
                        PlaceCardView(
                            place: place,
                            percent: selectedPercent,
                            level: selectedLevel,
                            timeText: timeText,
                            isFavorite: favorites.isFavorite(place),
                            onFavoriteClick: { Task { await favorites.toggle(place) } },
                            onCloseClick: { selectedPlace = nil; route = nil },
                            onDetailClick: { onDetailClick(place) }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            }

            BottomNavBar(
                selectedItem: selectedNavItem,
                onItemSelected: { item in
                    selectedNavItem = item
                    if item == .reportar {
                        reportTapped()
                    }
                    if item == .favoritos {
                        onFavoritesClick()
                    }
                    if item == .historial {
                        onHistoryClick()
                    }
                    if item == .perfil {
                        onProfileClick()
                    }
                    // TODO: navegar a Favoritos, Historial, Perfil cuando existan esas pantallas
                }
            )
        }
        .onAppear {
            Task { await loadHomeProfileImage() }
            Task { await favorites.refresh() }
            selectedNavItem = .mapa
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else if locationManager.authorizationStatus == .authorizedWhenInUse
                        || locationManager.authorizationStatus == .authorizedAlways {
                locationManager.requestCurrentLocation()
            }
            if let pending = favorites.pendingSelection {
                favorites.pendingSelection = nil
                Task { await showPlace(pending) }
            }
            if let routePlace = favorites.pendingRoute {
                favorites.pendingRoute = nil
                pendingRoutePlace = routePlace
                Task { await startPendingRoute() }
            }
        }
        .onChange(of: locationManager.currentLocation?.latitude) { _, _ in
            Task { await startPendingRoute() }   
            guard searchedCoordinate == nil, let coord = locationManager.currentLocation else { return }
            recenter(on: coord, animated: true)
            Task { await loadData(around: coord) }
        }
        .onChange(of: filterMode) { _, _ in
            if let center = activeCenter {
                Task { await loadData(around: center) }
            }
        }
        .onChange(of: timeOption) { _, _ in
            if let center = activeCenter {
                Task { await loadData(around: center) }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("No pudimos obtener tu ubicación", isPresented: $showLocationAlert) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Activá la ubicación o buscá una dirección para poder reportar.")
        }
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hola, \(userName) 👋")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.parkaiBlueDark)
                    Text("¿Dónde querés estacionar?")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.420, green: 0.447, blue: 0.502))
                }
                Spacer()

                Button {
                    onProfileClick()
                } label: {
                    Group {
                        if let image = homeProfileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.parkaiBlue.opacity(0.10))

                                Image(
                                    systemName: homeAvatarSymbols[homeAvatarKey]
                                        ?? "person.crop.circle.fill"
                                )
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color.parkaiBlue)
                                .padding(10)
                            }
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(
                                Color.parkaiBlue.opacity(0.15),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer().frame(height: 16)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.parkaiGray)
                TextField("Buscar dirección o lugar", text: $searchText)
                    .submitLabel(.search)
                    .onSubmit { searchAddress() }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.parkaiGray.opacity(0.4), lineWidth: 1)
            )

            Spacer().frame(height: 12)

            HStack(spacing: 10) {
                filterChip(title: "Vía pública", icon: "car.fill", isSelected: filterMode == .publicStreet) {
                    filterMode = .publicStreet
                }
                filterChip(title: "Estacionamientos", icon: "square.and.arrow.down", isSelected: filterMode == .privateParking) {
                    filterMode = .privateParking
                }

                Spacer()

                Menu {
                    ForEach(TimeOption.allCases) { option in
                        Button(option.label) { timeOption = option }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(timeOption.label)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.parkaiBlueDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.parkaiGray.opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    private func filterChip(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isSelected ? .parkaiBlue : .parkaiGray)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.parkaiBlue : Color.parkaiGray.opacity(0.4), lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }

    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Disponibilidad")
                .font(.system(size: 12, weight: .semibold))
            legendRow(color: .green, label: "Alta")
            legendRow(color: .orange, label: "Media")
            legendRow(color: .red, label: "Baja")
            legendRow(color: .gray, label: "Sin datos")
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 12))
        }
    }
    
    // MARK: - Imagen de perfil en Home

    private var homeAvatarSymbols: [String: String] {
        [
            "default": "person.crop.circle.fill",
            "avatar_1": "person.fill",
            "avatar_2": "face.smiling.fill",
            "avatar_3": "figure.walk",
            "avatar_4": "car.side.fill",
            "avatar_5": "steeringwheel",
            "avatar_6": "bolt.circle.fill"
        ]
    }

    @MainActor
    private func loadHomeProfileImage() async {

        guard let token = TokenManager.getToken(),
              !token.isEmpty else {
            homeProfileImage = nil
            homeAvatarKey = "default"
            return
        }

        do {
            let result = try await AuthAPIClient.getCurrentUser(
                token: token
            )

            guard result.statusCode == 200,
                  let user = result.user else {
                return
            }

            // Si el usuario eligió una fotografía
            if user.hasProfileImage == true {

                let photo = try await ProfileAPIClient.getPhoto()

                homeProfileImage = photo

            } else {

                // Si eligió un avatar prediseñado
                homeProfileImage = nil
                homeAvatarKey = user.avatarKey ?? "default"
            }

        } catch {
            print("Error cargando imagen del Home: \(error)")
        }
    }

    // MARK: - Acciones

    private func recenterOnUser() {
        guard let coord = locationManager.currentLocation else {
            locationManager.requestCurrentLocation()
            return
        }
        searchedCoordinate = nil
        recenter(on: coord, animated: true)
        Task { await loadData(around: coord) }
    }

    private func recenter(on coord: CLLocationCoordinate2D, animated: Bool) {
        let region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        if animated {
            withAnimation { cameraPosition = .region(region) }
        } else {
            cameraPosition = .region(region)
        }
    }

    private var timeText: String {
        let (_, hour) = timeOption.resolvedDayAndHour()
        return String(format: "Estimación para hoy, %02d:00", hour)
    }

    private func searchAddress() {
        let text = searchText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        Task {
            // Agregamos ", Buenos Aires" para que no encuentre calles homónimas de otras ciudades
            let query = text.lowercased().contains("buenos aires") ? text : "\(text), Buenos Aires, Argentina"
            guard let placemark = try? await CLGeocoder().geocodeAddressString(query).first,
                  let coord = placemark.location?.coordinate else { return }

            let street = [placemark.thoroughfare, placemark.subThoroughfare]
                .compactMap { $0 }
                .joined(separator: " ")
            let place = FavoritePlace(
                name: street.isEmpty ? text : street,
                neighborhood: placemark.subLocality ?? placemark.locality ?? "",
                latitude: coord.latitude,
                longitude: coord.longitude
            )
            await showPlace(place)
        }
    }

    private func showPlace(_ place: FavoritePlace) async {
        let coord = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        searchedCoordinate = coord
        selectedPlace = place
        selectedPercent = nil
        selectedLevel = nil
        recenter(on: coord, animated: true)

        // Predicción puntual de ese lugar
        let (dayOfWeek, hour) = timeOption.resolvedDayAndHour()
        if let prediction = try? await ParkingPredictionAPIClient.getPrediction(
            streetName: place.name,
            latitude: place.latitude,
            longitude: place.longitude,
            dayOfWeek: dayOfWeek,
            hour: hour
        ) {
            selectedPercent = prediction.estimatedAvailabilityPercent
            selectedLevel = prediction.level
        }

        // Y el heatmap de la zona alrededor
        await loadData(around: coord)
    }

    private func loadData(around coord: CLLocationCoordinate2D) async {
        if filterMode == .publicStreet {
            let (dayOfWeek, hour) = timeOption.resolvedDayAndHour()
            do {
                predictions = try await ParkingPredictionAPIClient.getNearbyPredictions(
                    placeName: searchText.isEmpty ? "Mi ubicación" : searchText,
                    latitude: coord.latitude,
                    longitude: coord.longitude,
                    dayOfWeek: dayOfWeek,
                    hour: hour
                )
            } catch {
                predictions = []
            }
        } else {
            privateSpots = await PrivateParkingAPIClient.getNearby(latitude: coord.latitude, longitude: coord.longitude)
        }
    }
    
    private func startPendingRoute() async {
        guard let place = pendingRoutePlace, let origin = locationManager.currentLocation else { return }
        pendingRoutePlace = nil

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)))
        request.transportType = .automobile

        selectedPlace = place
        guard let result = try? await MKDirections(request: request).calculate(),
              let found = result.routes.first else { return }

        route = found
        let rect = found.polyline.boundingMapRect
        withAnimation {
            cameraPosition = .rect(rect.insetBy(dx: -rect.width * 0.3, dy: -rect.height * 0.3))
        }
    }
    
    private func reportTapped() {
        Task {
            guard let target = await resolveReportLocation() else {
                showLocationAlert = true
                return
            }
            onReportClick(target.name, target.latitude, target.longitude)
        }
    }

    private func resolveReportLocation() async -> (name: String, latitude: Double, longitude: Double)? {
        // 1) Si hay un lugar seleccionado (buscado), se reporta ahí
        if let place = selectedPlace {
            return (place.name, place.latitude, place.longitude)
        }
        // 2) Si no, la ubicación actual
        guard let coord = locationManager.currentLocation else { return nil }
        let name = await streetName(for: coord)
        return (name, coord.latitude, coord.longitude)
    }

    private func streetName(for coord: CLLocationCoordinate2D) async -> String {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        if let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first {
            let street = [placemark.thoroughfare, placemark.subThoroughfare]
                .compactMap { $0 }
                .joined(separator: " ")
            if !street.isEmpty { return street }
        }
        return "Ubicación actual"
    }
}

#Preview {
    HomeView()
}
