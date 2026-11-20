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
    @State private var showAddressNotFoundAlert = false



    @StateObject private var locationManager = LocationManager()

    @State private var selectedNavItem: BottomNavItem = .mapa

    @State private var homeProfileImage: UIImage?

    @State private var homeAvatarKey = "default"

    @State private var searchText = ""

    @State private var filterMode: MapFilterMode = .publicStreet

    @State private var timeOption: TimeOption = .now

    @State private var showTimeMenu = false



    @State private var predictions: [NearbyPredictionResponse] = []
    // Geometrías oficiales de los tramos de CABA (independientes de ML).
    @State private var streetSegments: [StreetSegmentGeometry] = []
    // Evita que respuestas de otra búsqueda sobrescriban el mapa actual.
    @State private var mapDataRequestID = UUID()


    @State private var privateSpots: [PrivateParkingSpot] = []
    @State private var selectedPrivateSpot: PrivateParkingSpot?

    @State private var searchedCoordinate: CLLocationCoordinate2D?

    var onFavoritesClick: () -> Void = {}



    @ObservedObject private var favorites = FavoritesStore.shared

    @State private var selectedPlace: FavoritePlace?

    @State private var selectedPercent: Int?

    @State private var selectedLevel: String?

    // Permite ignorar respuestas de predicción de una tarjeta ya cerrada.
    @State private var selectionRequestID = UUID()

    // Evita que una búsqueda pendiente reabra la tarjeta después de cerrarla.
    @State private var searchRequestID = UUID()



    var onDetailClick: (FavoritePlace) -> Void = { _ in }



    @State private var route: MKRoute?

    @State private var pendingRoutePlace: FavoritePlace?

    // Destino de la ruta propia de ParkAI hacia un garaje real.
    @State private var privateRouteDestination: PrivateParkingSpot?
    @State private var pendingPrivateRouteSpot: PrivateParkingSpot?
    @State private var showPrivateRouteAlert = false
    @State private var privateRouteAlertMessage = ""



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



    // Las predicciones actuales siguen definiendo el color.
    // La geometría solo define por dónde dibujar el tramo.
    private struct ColoredStreetSegment: Identifiable {
        let id: Int64
        let coordinates: [CLLocationCoordinate2D]
        let color: Color
    }

    private func matchingSegment(for prediction: NearbyPredictionResponse) -> StreetSegmentGeometry? {
        streetSegments.first { segment in
            abs(segment.latitude - prediction.latitude) < 0.0000008 &&
            abs(segment.longitude - prediction.longitude) < 0.0000008 &&
            segment.streetName.caseInsensitiveCompare(prediction.streetName) == .orderedSame
        }
    }

    // Paleta de disponibilidad de ParkAI, compartida por lineas y puntos.
    private func availabilityColor(for level: String) -> Color {
        switch level.uppercased() {
        case "HIGH":
            return .green
        case "MEDIUM":
            return .yellow
        case "LOW":
            return .red
        default:
            return .gray
        }
    }

    private var coloredStreetSegments: [ColoredStreetSegment] {
        predictions.compactMap { prediction in
            guard let segment = matchingSegment(for: prediction),
                  segment.coordinates.count >= 2 else { return nil }
            return ColoredStreetSegment(
                id: segment.id,
                coordinates: segment.coordinates.map(\.mapCoordinate),
                color: availabilityColor(for: prediction.level)
            )
        }
    }

    private var pointPredictions: [NearbyPredictionResponse] {
        predictions.filter { matchingSegment(for: $0) == nil }
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



                    if let parking = privateRouteDestination {
                        Marker(
                            parking.name,
                            systemImage: "parkingsign.circle.fill",
                            coordinate: CLLocationCoordinate2D(
                                latitude: parking.latitude,
                                longitude: parking.longitude
                            )
                        )
                        .tint(Color.parkaiBlue)
                    }

                    if filterMode == .publicStreet {

                        // Tramos reales del callejero: línea desde el inicio
                        // hasta el final de la geometría oficial.
                        ForEach(coloredStreetSegments) { segment in
                            MapPolyline(coordinates: segment.coordinates)
                                .stroke(segment.color, lineWidth: 7)
                        }

                        // Fuera de CABA (o si el endpoint de geometrías falla)
                        // conservamos los puntos que ya usaba ParkAI.
                        ForEach(pointPredictions.indices, id: \.self) { index in
                            let prediction = pointPredictions[index]
                            Annotation(
                                prediction.streetName,
                                coordinate: CLLocationCoordinate2D(
                                    latitude: prediction.latitude,
                                    longitude: prediction.longitude
                                )
                            ) {
                                Circle()
                                    .fill(availabilityColor(for: prediction.level))
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }

                    } else {

                        ForEach(privateSpots) { spot in

                            Annotation("", coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)) {

                                Button {
                                    selectedPrivateSpot = spot
                                } label: {
                                    Image(systemName: "p.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.parkaiBlue)
                                        .background(Circle().fill(.white))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Ver estacionamiento: \(spot.name)")
                            }

                        }

                    }

                    // Mantener la ruta de navegación por encima de las líneas
                    // de disponibilidad para distinguirla con claridad.
                    if let route {
                        MapPolyline(route.polyline)
                            .stroke(Color.parkaiBlue, lineWidth: 5)
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

                            onCloseClick: { dismissPlaceCard() },

                            onDetailClick: { onDetailClick(place) }

                        )

                        .padding(.horizontal, 16)
                        // Botón de cierre visible, por encima de la esquina
                        // derecha de la tarjeta (sin tapar el corazón).
                        .overlay(alignment: .topTrailing) {
                            Button(action: dismissPlaceCard) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white, in: Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.2)))
                                    .shadow(color: .black.opacity(0.12), radius: 3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Cerrar tarjeta de ubicación")
                            .offset(x: -9, y: -19)
                        }

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

            // Si el usuario pidió una ruta antes de tener GPS, iniciarla al recibirlo.
            if let spot = pendingPrivateRouteSpot {
                Task { await startPrivateParkingRoute(to: spot) }
            }

            guard searchedCoordinate == nil, let coord = locationManager.currentLocation else { return }

            recenter(on: coord, animated: true)

            Task { await loadData(around: coord) }

        }

        .onChange(of: filterMode) { _, newMode in

            if newMode == .privateParking {
                dismissPlaceCard()
            } else {
                selectedPrivateSpot = nil
            }

            if let center = activeCenter {
                Task { await loadData(around: center) }
            }

        }

        .onChange(of: timeOption) { _, _ in

            if let center = activeCenter {

                Task { await loadData(around: center) }

            }

        }

        .sheet(item: $selectedPrivateSpot) { spot in
            PrivateParkingDetailSheet(
                spot: spot,
                userCoordinate: locationManager.currentLocation,
                onNavigateInParkAI: {
                    selectedPrivateSpot = nil
                    Task { await startPrivateParkingRoute(to: spot) }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .navigationBarBackButtonHidden(true)

        .alert("No pudimos calcular la ruta", isPresented: $showPrivateRouteAlert) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(privateRouteAlertMessage)
        }

        .alert("No pudimos obtener tu ubicación", isPresented: $showLocationAlert) {

            Button("Entendido", role: .cancel) {}

        } message: {

            Text("Activá la ubicación o buscá una dirección para poder reportar.")

        }

        .alert("Dirección no encontrada", isPresented: $showAddressNotFoundAlert) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("No encontramos una calle, dirección o lugar que coincida con tu búsqueda en Buenos Aires. Probá con otro nombre o agregá la altura.")
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

            legendRow(color: .yellow, label: "Media")

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



    // Cierra la tarjeta y la ruta, pero deja la cámara y el mapa de calor
    // en la zona que el usuario está mirando.
    private func dismissPlaceCard() {
        selectionRequestID = UUID()
        searchRequestID = UUID()
        selectedPlace = nil
        selectedPercent = nil
        selectedLevel = nil
        route = nil
        privateRouteDestination = nil
        pendingPrivateRouteSpot = nil
        searchText = ""
        // NO borramos searchedCoordinate para conservar el mapa actual.
    }

    private func recenterOnUser() {
        // También cerramos la tarjeta cuando volvemos a nuestra ubicación.
        dismissPlaceCard()
        searchedCoordinate = nil

        guard let coord = locationManager.currentLocation else {
            locationManager.requestCurrentLocation()
            return
        }

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



    // MARK: - Búsqueda validada (no aceptar la ubicación genérica de Buenos Aires)

    /// Normaliza los términos para comparar lo escrito con el resultado de MapKit.
    /// No es una validación postal exacta: evita falsos positivos obvios.
    private func searchWords(_ value: String) -> [String] {
        let normalized = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive],
                     locale: Locale(identifier: "es_AR"))
            .lowercased()

        let ignored: Set<String> = [
            "av", "avda", "avenida", "calle", "gral", "general",
            "de", "del", "la", "las", "los", "el", "y", "en", "al",
            "buenos", "aires", "argentina", "caba", "capital", "federal",
            "ciudad", "autonoma", "nro", "numero", "num"
        ]

        return normalized
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !ignored.contains($0) }
    }

    private func searchResultMatches(_ item: MKMapItem, query: String) -> Bool {
        let words = searchWords(query)
        guard !words.isEmpty else { return false }

        let placemark = item.placemark
        let description = [
            item.name, placemark.name, placemark.thoroughfare,
            placemark.subThoroughfare, placemark.subLocality,
            placemark.locality, placemark.title
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        let returnedWords = Set(searchWords(description))
        let normalizedDescription = description
            .folding(options: [.caseInsensitive, .diacriticInsensitive],
                     locale: Locale(identifier: "es_AR"))
            .lowercased()

        // La sigla de UADE puede figurar en Apple Maps con su nombre completo.
        return words.allSatisfy { word in
            returnedWords.contains(word) ||
            (word == "uade" && normalizedDescription.contains("universidad argentina de la empresa"))
        }
    }

    private func searchAddress() {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let requestID = UUID()
        searchRequestID = requestID

        Task { @MainActor in
            // Búsqueda por texto dentro del área metropolitana, priorizando CABA.
            // NO concatenamos "Buenos Aires, Argentina" a un texto inexistente,
            // porque el geocodificador anterior ignoraba el texto y devolvía la ciudad.
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -34.61, longitude: -58.43),
                span: MKCoordinateSpan(latitudeDelta: 0.30, longitudeDelta: 0.38)
            )
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = text
            request.region = region
            request.resultTypes = [.address, .pointOfInterest]

            do {
                let response = try await MKLocalSearch(request: request).start()
                guard searchRequestID == requestID else { return }

                guard let item = response.mapItems.first(where: {
                    searchResultMatches($0, query: text)
                }) else {
                    showAddressNotFoundAlert = true
                    return
                }

                let coordinate = item.placemark.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else {
                    showAddressNotFoundAlert = true
                    return
                }

                let placemark = item.placemark
                let street = [placemark.thoroughfare, placemark.subThoroughfare]
                    .compactMap { $0 }
                    .joined(separator: " ")

                let place = FavoritePlace(
                    name: item.name ?? (street.isEmpty ? text : street),
                    neighborhood: placemark.subLocality ?? placemark.locality ?? "",
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )

                await showPlace(place)
            } catch {
                guard searchRequestID == requestID else { return }
                showAddressNotFoundAlert = true
            }
        }
    }


    private func showPlace(_ place: FavoritePlace) async {

        let requestID = UUID()
        selectionRequestID = requestID

        let coord = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)

        searchedCoordinate = coord

        selectedPlace = place

        selectedPercent = nil

        selectedLevel = nil

        recenter(on: coord, animated: true)




        let (dayOfWeek, hour) = timeOption.resolvedDayAndHour()

        if let prediction = try? await ParkingPredictionAPIClient.getPrediction(

            streetName: place.name,

            latitude: place.latitude,

            longitude: place.longitude,

            dayOfWeek: dayOfWeek,

            hour: hour

        ) {
            
            guard selectionRequestID == requestID else { return }
            selectedPercent = prediction.estimatedAvailabilityPercent
            selectedLevel = prediction.level
        }

        guard selectionRequestID == requestID else { return }
        await loadData(around: coord)

    }



    private func loadData(around coord: CLLocationCoordinate2D) async {
        let requestID = UUID()
        mapDataRequestID = requestID

        if filterMode == .publicStreet {
            let (dayOfWeek, hour) = timeOption.resolvedDayAndHour()

            do {
                
                let newPredictions = try await ParkingPredictionAPIClient.getNearbyPredictions(
                    placeName: searchText.isEmpty ? "Mi ubicación" : searchText,
                    latitude: coord.latitude,
                    longitude: coord.longitude,
                    dayOfWeek: dayOfWeek,
                    hour: hour
                )

                
                let newSegments = (try? await StreetSegmentAPIClient.getNearby(
                    latitude: coord.latitude,
                    longitude: coord.longitude
                )) ?? []

                guard mapDataRequestID == requestID else { return }
                predictions = newPredictions
                streetSegments = newSegments

            } catch {
                guard mapDataRequestID == requestID else { return }
                predictions = []
                streetSegments = []
                print("Error cargando disponibilidad: \(error)")
            }
        } else {
            let spots = await PrivateParkingAPIClient.getNearby(
                latitude: coord.latitude,
                longitude: coord.longitude
            )
            guard mapDataRequestID == requestID else { return }
            privateSpots = spots
        }
    }

    
    private func startPrivateParkingRoute(to spot: PrivateParkingSpot) async {
        selectionRequestID = UUID()
        searchRequestID = UUID()
        selectedPlace = nil
        selectedPercent = nil
        selectedLevel = nil
        selectedPrivateSpot = nil
        searchText = ""
        route = nil
        privateRouteDestination = spot

        let destination = CLLocationCoordinate2D(
            latitude: spot.latitude,
            longitude: spot.longitude
        )
        searchedCoordinate = destination

        guard let origin = locationManager.currentLocation else {
            pendingPrivateRouteSpot = spot
            locationManager.requestCurrentLocation()
            return
        }

        pendingPrivateRouteSpot = nil

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        do {
            let response = try await MKDirections(request: request).calculate()

            
            guard privateRouteDestination?.id == spot.id else { return }

            guard let bestRoute = response.routes.first else {
                privateRouteAlertMessage = "No hay un recorrido en auto disponible para este estacionamiento."
                showPrivateRouteAlert = true
                return
            }

            route = bestRoute
            let rect = bestRoute.polyline.boundingMapRect
            withAnimation {
                cameraPosition = .rect(
                    rect.insetBy(dx: -rect.width * 0.3, dy: -rect.height * 0.3)
                )
            }
        } catch {
            guard privateRouteDestination?.id == spot.id else { return }
            privateRouteAlertMessage = "No fue posible calcular el recorrido. Verificá la conexión y volvé a intentarlo."
            showPrivateRouteAlert = true
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

        

        if let place = selectedPlace {

            return (place.name, place.latitude, place.longitude)

        }

        

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
