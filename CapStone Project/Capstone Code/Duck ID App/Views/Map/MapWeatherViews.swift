import MapKit
import SwiftUI

// In-app MapKit screen. This does not open Apple Maps; it embeds the map directly.
struct SightingMapView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(SightingsViewModel.self) private var sightingsViewModel

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedSighting: DuckSighting?
    @State private var showsAddSighting = false

    var body: some View {
        NavigationStack {
            Map(position: $position, selection: $selectedSighting) {
                UserAnnotation()
                ForEach(sightingsViewModel.sightings) { sighting in
                    Marker(sighting.speciesName, systemImage: "mappin", coordinate: sighting.coordinate)
                        .tint(.teal)
                        .tag(sighting)
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .safeAreaInset(edge: .bottom) { mapStatusBar }
            .navigationTitle("Map")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showsAddSighting = true } label: { Label("Add", systemImage: "plus") }
                }
            }
            .sheet(item: $selectedSighting) { sighting in
                SightingDetailView(sighting: sighting).presentationDetents([.medium])
            }
            .sheet(isPresented: $showsAddSighting) { AddSightingView() }
            .onAppear {
                locationManager.start()
                centerOnCurrentLocation()
            }
            .onChange(of: locationManager.currentLocation) { _, _ in centerOnCurrentLocation() }
        }
    }

    private var mapStatusBar: some View {
        HStack(spacing: 12) {
            Label("\(sightingsViewModel.sightings.count) sightings", systemImage: "mappin.and.ellipse")
            Spacer()
            if let heading = locationManager.heading?.trueHeading, heading >= 0 {
                Label("\(Int(heading)) deg", systemImage: "location.north.line")
            }
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private func centerOnCurrentLocation() {
        guard let coordinate = locationManager.currentLocation?.coordinate else { return }
        position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
    }
}

// Manual sighting entry using the current CoreLocation coordinate.
struct AddSightingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationManager.self) private var locationManager
    @Environment(SightingsViewModel.self) private var sightingsViewModel
    @Environment(WeatherViewModel.self) private var weatherViewModel

    @State private var selectedSpeciesID = DuckData.species[0].id
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Duck") {
                    Picker("Species", selection: $selectedSpeciesID) {
                        ForEach(DuckData.species) { species in
                            Text(species.commonName).tag(species.id)
                        }
                    }
                }

                Section("Location") {
                    if let coordinate = locationManager.currentLocation?.coordinate {
                        LabeledContent("Latitude", value: coordinate.latitude.formatted(.number.precision(.fractionLength(5))))
                        LabeledContent("Longitude", value: coordinate.longitude.formatted(.number.precision(.fractionLength(5))))
                    } else {
                        Text("Current location unavailable.").foregroundStyle(.secondary)
                        Button("Request Location") {
                            locationManager.requestPermission()
                            locationManager.start()
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle("Add Sighting")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(locationManager.currentLocation == nil)
                }
            }
        }
    }

    private func save() {
        guard let species = DuckData.species(for: selectedSpeciesID), let coordinate = locationManager.currentLocation?.coordinate else { return }
        sightingsViewModel.addSighting(species: species, coordinate: coordinate, notes: notes, weatherSummary: weatherViewModel.snapshot.conditionText)
        dismiss()
    }
}

struct SightingDetailView: View {
    let sighting: DuckSighting

    var body: some View {
        NavigationStack {
            List {
                Section("Duck") {
                    LabeledContent("Species", value: sighting.speciesName)
                    LabeledContent("Date", value: sighting.date.formatted(date: .abbreviated, time: .shortened))
                }
                Section("Location") {
                    LabeledContent("Latitude", value: sighting.latitude.formatted(.number.precision(.fractionLength(5))))
                    LabeledContent("Longitude", value: sighting.longitude.formatted(.number.precision(.fractionLength(5))))
                }
                if !sighting.notes.isEmpty { Section("Notes") { Text(sighting.notes) } }
                if let weatherSummary = sighting.weatherSummary { Section("Weather") { Text(weatherSummary) } }
            }
            .navigationTitle("Sighting")
        }
    }
}

// Weather tab backed by WeatherKit through WeatherViewModel.
struct WeatherView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(WeatherViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Current Weather") {
                    WeatherMetricRow(title: "Condition", value: viewModel.snapshot.conditionText, systemImage: "cloud.sun")
                    WeatherMetricRow(title: "Temperature", value: viewModel.snapshot.temperatureText, systemImage: "thermometer.medium")
                    WeatherMetricRow(title: "Wind", value: viewModel.snapshot.windText, systemImage: "wind")
                    WeatherMetricRow(title: "Precipitation", value: viewModel.snapshot.precipitationText, systemImage: "drop")
                }

                Section("Last Saved Forecast") {
                    LabeledContent("Updated", value: viewModel.snapshot.observedAt.formatted(date: .abbreviated, time: .shortened))
                }

                if let errorMessage = viewModel.errorMessage {
                    Section("Status") { Text(errorMessage).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Weather")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await viewModel.refresh(for: locationManager.currentLocation) } } label: {
                        if viewModel.isLoading { ProgressView() } else { Label("Refresh", systemImage: "arrow.clockwise") }
                    }
                }
            }
            .task {
                locationManager.start()
                await viewModel.refresh(for: locationManager.currentLocation)
            }
        }
    }
}

struct WeatherMetricRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        LabeledContent { Text(value).foregroundStyle(.primary) } label: { Label(title, systemImage: systemImage) }
    }
}
