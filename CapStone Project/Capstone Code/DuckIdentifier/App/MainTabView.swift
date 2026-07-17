import SwiftUI

// The main tab bar keeps the app split into the five sections from the design.
struct MainTabView: View {
    var body: some View {
        TabView {
            // Camera and identification flow
            IdentifyView()
                .tabItem {
                    Label("Identify", systemImage: "camera.viewfinder")
                }

            DuckListView()
                .tabItem {
                    Label("Ducks", systemImage: "binoculars.fill")
                }

            SightingMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            WeatherView()
                .tabItem {
                    Label("Weather", systemImage: "cloud.sun.fill")
                }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
