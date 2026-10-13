import Foundation

struct FavoritePlace: Identifiable, Equatable {
    var serverId: Int64? = nil
    let name: String
    var neighborhood: String = ""
    let latitude: Double
    let longitude: Double

    // Misma regla que el back: mismo nombre de calle (sin mayúsculas ni espacios extra)
    var id: String { name.trimmingCharacters(in: .whitespaces).lowercased() }

    static func == (lhs: FavoritePlace, rhs: FavoritePlace) -> Bool {
        lhs.id == rhs.id
    }
}

// DTOs del back
struct FavoriteRequestDTO: Codable {
    let streetName: String
    let latitude: Double
    let longitude: Double
}

struct FavoriteDTO: Codable {
    let id: Int64
    let streetName: String
    let latitude: Double
    let longitude: Double

    var asPlace: FavoritePlace {
        FavoritePlace(serverId: id, name: streetName, latitude: latitude, longitude: longitude)
    }
}
