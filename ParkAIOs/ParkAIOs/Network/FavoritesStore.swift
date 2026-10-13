import SwiftUI
internal import Combine

@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var favorites: [FavoritePlace] = []
    /// Cuando tocás un favorito, queda acá y el Home lo recoge para centrar el mapa.
    @Published var pendingSelection: FavoritePlace?
    @Published var pendingRoute: FavoritePlace?

    private init() {}

    private var authHeader: String? {
        TokenManager.getToken().map { "Bearer \($0)" }
    }

    func isFavorite(_ place: FavoritePlace) -> Bool {
        favorites.contains(place)
    }

    func clear() {
        favorites = []
    }

    /// Trae la lista desde el back
    func refresh() async {
        guard let auth = authHeader else { favorites = []; return }
        do {
            let (status, data) = try await APIClient.get(
                path: "api/favorites",
                queryItems: [],
                authToken: auth,
                responseType: [FavoriteDTO].self
            )
            if (200...299).contains(status), let data {
                favorites = data.map { $0.asPlace }
            }
        } catch {
            print("❌ Error cargando favoritos: \(error)")
        }
    }

    func toggle(_ place: FavoritePlace) async {
        if let existing = favorites.first(where: { $0 == place }) {
            await remove(existing)
        } else {
            await add(place)
        }
    }

    private func add(_ place: FavoritePlace) async {
        guard let auth = authHeader else { return }
        do {
            let body = FavoriteRequestDTO(
                streetName: place.name,
                latitude: place.latitude,
                longitude: place.longitude
            )
            let (status, data) = try await APIClient.post(
                path: "api/favorites",
                body: body,
                responseType: FavoriteDTO.self,
                authToken: auth
            )
            if (200...299).contains(status), let data {
                var saved = data.asPlace
                saved.neighborhood = place.neighborhood
                favorites.insert(saved, at: 0)
            } else {
                // Por ejemplo duplicado (409): sincronizamos con lo que tiene el back
                await refresh()
            }
        } catch {
            print("❌ Error guardando favorito: \(error)")
        }
    }

    func remove(_ place: FavoritePlace) async {
        guard let auth = authHeader, let id = place.serverId else { return }
        do {
            let status = try await APIClient.delete(path: "api/favorites/\(id)", authToken: auth)
            if (200...299).contains(status) {
                favorites.removeAll { $0 == place }
            } else {
                await refresh()
            }
        } catch {
            print("❌ Error borrando favorito: \(error)")
        }
    }
}
