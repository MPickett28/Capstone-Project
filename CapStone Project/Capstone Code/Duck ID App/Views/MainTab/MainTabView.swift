import SwiftUI

// Main app navigation. This owns the shared app state and injects it into every tab.
struct MainTabView: View {
    @State private var locationManager = LocationManager()
    @State private var sightingsViewModel = SightingsViewModel()
    @State private var weatherViewModel = WeatherViewModel()

    var body: some View {
        TabView {
            IdentifyView()
                .tabItem { Label("Identify", systemImage: "camera.viewfinder") }

            DuckListView()
                .tabItem { Label("Ducks", systemImage: "list.bullet") }

            SightingMapView()
                .tabItem { Label("Map", systemImage: "map") }

            WeatherView()
                .tabItem { Label("Weather", systemImage: "cloud.sun") }

            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
        .environment(locationManager)
        .environment(sightingsViewModel)
        .environment(weatherViewModel)
        .task { locationManager.start() }
    }
}
