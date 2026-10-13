import SwiftUI
import MapKit

struct PlaceCardView: View {
    let place: FavoritePlace
    let percent: Int?
    let level: String?
    let timeText: String
    let isFavorite: Bool
    var onFavoriteClick: () -> Void
    var onCloseClick: () -> Void
    var onDetailClick: () -> Void = {}

    private var levelColor: Color {
        switch level {
        case "HIGH": return Color(hex: 0x22C55E)
        case "MEDIUM": return Color(hex: 0xF59E0B)
        case "LOW": return Color(hex: 0xEF4444)
        default: return .parkaiGray
        }
    }

    private var levelText: String {
        switch level {
        case "HIGH": return "Alta disponibilidad"
        case "MEDIUM": return "Media disponibilidad"
        case "LOW": return "Baja disponibilidad"
        default: return "Sin datos"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.parkaiGray.opacity(0.4))
                .frame(width: 40, height: 4)
                .onTapGesture { onCloseClick() }

            HStack(alignment: .top, spacing: 14) {
                Text(percent.map { "\($0)%" } ?? "--")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(levelColor)
                    .frame(width: 84, height: 70)
                    .background(levelColor.opacity(0.12))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.parkaiBlueDark)
                        .lineLimit(1)
                    if !place.neighborhood.isEmpty {
                        Text(place.neighborhood)
                            .font(.system(size: 13))
                            .foregroundColor(.parkaiGray)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(levelColor).frame(width: 8, height: 8)
                        Text(levelText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(levelColor)
                    }
                    Text(timeText)
                        .font(.system(size: 12))
                        .foregroundColor(.parkaiGray)
                }

                Spacer()

                Button(action: onFavoriteClick) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.parkaiBlue)
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.parkaiGray.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            HStack(spacing: 12) {
                Button(action: openInMaps) {
                    HStack {
                        Image(systemName: "location.north.fill")
                        Text("Ir hacia allá")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.parkaiBlue)
                    .cornerRadius(12)
                }

                Button(action: onDetailClick) {
                    Text("Ver detalle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.parkaiBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color(hex: 0xEFF6FF))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }

    private func openInMaps() {
        let item = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        ))
        item.name = place.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
