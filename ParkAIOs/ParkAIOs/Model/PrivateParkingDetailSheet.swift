import SwiftUI
import MapKit
import CoreLocation

// Detalle de estacionamiento con datos verificados del backend ParkAI.
// No muestra precios, horarios, disponibilidad ni fotografías que el dataset no contiene.
struct PrivateParkingDetailSheet: View {
    let spot: PrivateParkingSpot
    var userCoordinate: CLLocationCoordinate2D? = nil
    // Acción entregada por HomeView para trazar la ruta en el mapa de ParkAI.
    var onNavigateInParkAI: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let blue = Color(red: 0.08, green: 0.40, blue: 0.94)
    private let ink = Color(red: 0.09, green: 0.15, blue: 0.29)

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
    }

    private var distanceText: String? {
        guard let userCoordinate else { return nil }
        let origin = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let destination = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
        let meters = origin.distance(from: destination)
        if meters < 1000 { return "A \(Int(meters.rounded())) m de tu ubicación" }
        return String(format: "A %.1f km de tu ubicación", meters / 1000)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                mapHeader

                VStack(alignment: .leading, spacing: 0) {
                    titleBlock
                    Divider().padding(.vertical, 14)

                    detailRow(
                        icon: "mappin.and.ellipse",
                        title: spot.address,
                        subtitle: [spot.neighborhood, distanceText]
                            .compactMap { $0 }
                            .filter { !$0.isEmpty }
                            .joined(separator: " · ")
                    )
                    Divider().padding(.vertical, 12)

                    detailRow(
                        icon: "car.side.fill",
                        title: spot.sourceLabel,
                        subtitle: "Ubicación registrada en datos públicos"
                    )
                    Divider().padding(.vertical, 12)

                    detailRow(
                        icon: "checkmark.circle",
                        title: "Disponibilidad no informada",
                        subtitle: "No contamos con ocupación en tiempo real"
                    )
                    Divider().padding(.vertical, 12)

                    detailRow(
                        icon: "tag",
                        title: "Tarifa no informada",
                        subtitle: "Consultá el precio directamente con el establecimiento"
                    )
                    Divider().padding(.vertical, 12)

                    detailRow(
                        icon: "clock",
                        title: "Horario no informado",
                        subtitle: "No podemos confirmar si está abierto ahora"
                    )

                    informationNotice
                        .padding(.top, 22)

                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                            onNavigateInParkAI()
                        } label: {
                            Label("Cómo llegar", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(blue)

                        Button(action: openGoogleMaps) {
                            Label("Google Maps", systemImage: "map")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .tint(blue)
                    }
                    .padding(.top, 18)

                    Text("Fuente de ubicaciones: Gobierno de la Ciudad de Buenos Aires (BA Data).")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
                .padding(20)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    private var mapHeader: some View {
        ZStack(alignment: .topLeading) {
            Map(initialPosition: .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                )
            )) {
                Marker(spot.name, systemImage: "parkingsign.circle.fill", coordinate: coordinate)
                    .tint(blue)
            }
            .mapControlVisibility(.hidden)
            .allowsHitTesting(false)
            .frame(height: 270)
            .clipped()

            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ink)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 13))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
            }
            .padding(.leading, 20)
            .padding(.top, 56)
        }
        .accessibilityLabel("Mapa con la ubicación registrada del estacionamiento")
    }

    private var titleBlock: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "parkingsign.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(blue)

            VStack(alignment: .leading, spacing: 5) {
                Text(spot.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(spot.sourceLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func detailRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 19))
                .foregroundStyle(ink)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var informationNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(blue)
            VStack(alignment: .leading, spacing: 4) {
                Text("Información importante")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(blue)
                Text("La ubicación procede de un registro público. Los horarios, las tarifas, la disponibilidad y el funcionamiento actual no están verificados.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    private func openGoogleMaps() {
        var components = URLComponents(string: "https://www.google.com/maps/dir/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "destination", value: "\(spot.latitude),\(spot.longitude)"),
            URLQueryItem(name: "travelmode", value: "driving")
        ]
        guard let url = components?.url else { return }
        openURL(url)
    }
}
