import SwiftUI
import MapKit
import CoreLocation

enum MapFilterMode {
    case publicStreet
    case privateParking
}

struct HomeView: View {
    var onReportClick: () -> Void = {}

    @StateObject private var locationManager = LocationManager()
    @State private var selectedNavItem: BottomNavItem = .mapa
    @State private var searchText = ""
    @State private var filterMode: MapFilterMode = .publicStreet
    @State private var timeOption: TimeOption = .now
    @State private var showTimeMenu = false

    @State private var predictions: [NearbyPredictionResponse] = []
    @State private var privateSpots: [PrivateParkingSpot] = []
    @State private var searchedCoordinate: CLLocationCoordinate2D?

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
                            Annotation(spot.name, coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)) {
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
                VStack {
                    Spacer()
                    HStack {
                        Button(action: onReportClick) {
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
                    .padding(20)
                }
            }

            BottomNavBar(
                selectedItem: selectedNavItem,
                onItemSelected: { item in
                    selectedNavItem = item
                    if item == .reportar {
                        onReportClick()
                    }
                    // TODO: navegar a Favoritos, Historial, Perfil cuando existan esas pantallas
                }
            )
        }
        .onAppear {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else if locationManager.authorizationStatus == .authorizedWhenInUse
                        || locationManager.authorizationStatus == .authorizedAlways {
                locationManager.requestCurrentLocation()
            }
        }
        .onChange(of: locationManager.currentLocation?.latitude) { _, _ in
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
                Circle()
                    .fill(Color(red: 0.898, green: 0.906, blue: 0.922))
                    .frame(width: 44, height: 44)
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

    private func searchAddress() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            let geocoder = CLGeocoder()
            if let placemark = try? await geocoder.geocodeAddressString(searchText).first,
               let coord = placemark.location?.coordinate {
                searchedCoordinate = coord
                recenter(on: coord, animated: true)
                await loadData(around: coord)
            }
        }
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
}

#Preview {
    HomeView()
}
