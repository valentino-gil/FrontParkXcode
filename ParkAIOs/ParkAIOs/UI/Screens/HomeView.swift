import SwiftUI
import MapKit

struct HomeView: View {
    var userName: String = "Luis"
    var onReportClick: () -> Void = {}

    @StateObject private var locationManager = LocationManager()
    @State private var selectedNavItem: BottomNavItem = .mapa
    @State private var searchText = ""

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -34.5875, longitude: -58.4205),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                }
                .mapControls {
                    // Sin controles extra por ahora, replicando el mapa simple de osmdroid
                }
                .ignoresSafeArea(edges: .top)

                VStack {
                    topBar
                    Spacer()
                }

                Button(action: onReportClick) {
                    Text("+ Reportar")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.parkaiBlue)
                        .cornerRadius(24)
                }
                .padding(20)
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
            if let coord = locationManager.currentLocation {
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    )
                }
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
                    .fill(Color(red: 0.898, green: 0.906, blue: 0.922)) // #E5E7EB
                    .frame(width: 44, height: 44)
            }

            Spacer().frame(height: 16)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.parkaiGray)
                TextField("Buscar dirección o lugar", text: $searchText)
                    // TODO: buscador de direcciones
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.parkaiGray.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }
}

#Preview {
    HomeView()
}
