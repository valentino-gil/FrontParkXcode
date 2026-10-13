import Foundation

struct SearchHistoryItem: Codable, Identifiable {
    let placeName: String
    let latitude: Double
    let longitude: Double
    let searchedAt: String   

    var id: String { "\(placeName)_\(searchedAt)" }

    var date: Date? {
        let base = searchedAt.split(separator: ".").first.map(String.init) ?? searchedAt
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: base)
    }

    var asPlace: FavoritePlace {
        FavoritePlace(name: placeName, latitude: latitude, longitude: longitude)
    }
}
