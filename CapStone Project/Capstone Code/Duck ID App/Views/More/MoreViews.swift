import SwiftUI

// Extra app sections: saved sightings, rules, resources, settings, and support.
struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Saved") {
                    NavigationLink { SightingsListView() } label: { Label("Sightings", systemImage: "mappin.and.ellipse") }
                }
                Section("Information") {
                    NavigationLink { HuntingRulesView() } label: { Label("Hunting Rules", systemImage: "doc.text") }
                    NavigationLink { ResourcesView() } label: { Label("Resources", systemImage: "link") }
                }
                Section("App") {
                    NavigationLink { SettingsView() } label: { Label("Settings", systemImage: "gearshape") }
                    NavigationLink { SupportView() } label: { Label("Support", systemImage: "questionmark.circle") }
                }
            }
                .navigationTitle("More")
        }
    }
}

struct SightingsListView: View {
    @Environment(SightingsViewModel.self) private var sightingsViewModel

    var body: some View {
        List {
            ForEach(sightingsViewModel.sightings) { sighting in
                SightingDetailView(sighting: sighting)
            }
            .onDelete { offsets in sightingsViewModel.deleteSightings(at: offsets) }
        }
        .navigationTitle("Sightings")
    }
}

struct HuntingRulesView: View {
    var body: some View {
        List {
            Section("Before You Hunt") {
                Label("Confirm season dates and bag limits for your area.", systemImage: "calendar")
                Label("Carry the required license, stamps, and permissions.", systemImage: "checkmark.seal")
                Label("Verify legal shooting hours and species restrictions.", systemImage: "clock")
            }
            Section("Note") {
                Text("This app is a field guide and logbook. It does not replace current government regulations.")
            }
        }
        .navigationTitle("Hunting Rules")
    }
}

struct ResourcesView: View {
    var body: some View {
        List {
            Section("Learning") {
                Link("All About Birds", destination: URL(string: "https://www.allaboutbirds.org")!)
                Link("Ducks Unlimited", destination: URL(string: "https://www.ducks.org")!)
            }
            Section("Apple Features Used") {
                Label("MapKit for in-app maps", systemImage: "map")
                Label("CoreLocation for current position", systemImage: "location")
                Label("WeatherKit for local weather", systemImage: "cloud.sun")
                Label("Core ML and Vision for image identification", systemImage: "brain")
            }
        }
        .navigationTitle("Resources")
    }
}

struct SettingsView: View {
    @AppStorage("usesMetricUnits") private var usesMetricUnits = true
    @AppStorage("savesWeatherWithSightings") private var savesWeatherWithSightings = true

    var body: some View {
        Form {
            Toggle("Metric Units", isOn: $usesMetricUnits)
            Toggle("Save Weather With Sightings", isOn: $savesWeatherWithSightings)
        }
        .navigationTitle("Settings")
    }
}

struct SupportView: View {
    var body: some View {
        List {
            Section("About") {
                LabeledContent("App", value: "Duck Identifier")
                LabeledContent("Version", value: "1.0")
            }
            Section("ML Training") {
                Text("Use Xcode Create ML to train an image classifier from your duck photo folders, then add the exported DuckClassifier.mlmodel to the app target.")
            }
        }
        .navigationTitle("Support")
    }
}
