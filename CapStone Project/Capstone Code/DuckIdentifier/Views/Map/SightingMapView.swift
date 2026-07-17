import SwiftUI
import MapKit

// The map screen uses Apple Maps / MapKit for the live map and saved sightings view.
struct SightingMapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationStack {
            Map(coordinateRegion: $region, annotationItems: DuckData.sampleSightings) { sighting in
                MapMarker(coordinate: sighting.coordinate, tint: .blue)
            }
            .navigationTitle("Map")
            .onAppear {
                locationManager.requestPermission()
                locationManager.start()
            }
        }
    }
}

#Preview {
    SightingMapView()
}
