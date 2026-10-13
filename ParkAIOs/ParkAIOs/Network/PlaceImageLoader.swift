import UIKit
import MapKit

enum PlaceImageLoader {
    /// Look Around (calle) y, si no hay cobertura, vista satelital.
    static func load(for place: FavoritePlace, size: CGSize) async -> UIImage? {
        let coord = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)

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
