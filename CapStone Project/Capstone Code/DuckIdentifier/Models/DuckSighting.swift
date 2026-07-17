import Foundation
import MapKit

// A saved duck sighting stores the species, position, and a few details for the map view.
struct DuckSighting: Identifiable, Codable {
    let id: UUID
    let speciesName: String
    let latitude: Double
    let longitude: Double
    let date: Date
    let notes: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
