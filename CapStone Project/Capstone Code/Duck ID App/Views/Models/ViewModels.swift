import CoreLocation
import Observation
import SwiftUI
import UIKit

// Shared state for saved sightings and map pins.
@MainActor
@Observable
final class SightingsViewModel {
    private let persistence = PersistenceService()
    var sightings: [DuckSighting]

    init() {
        sightings = persistence.loadSightings().sorted { $0.date > $1.date }
    }

    func addSighting(species: DuckSpecies, coordinate: CLLocationCoordinate2D, notes: String, weatherSummary: String?) {
        let sighting = DuckSighting(speciesID: species.id, speciesName: species.commonName, latitude: coordinate.latitude, longitude: coordinate.longitude, notes: notes, weatherSummary: weatherSummary)
        sightings.insert(sighting, at: 0)
        persistence.saveSightings(sightings)
    }

    func deleteSightings(at offsets: IndexSet) {
        sightings.remove(atOffsets: offsets)
        persistence.saveSightings(sightings)
    }
}

// Shared state for WeatherKit loading and cached weather display.
@MainActor
@Observable
final class WeatherViewModel {
    private let service = DuckWeatherService()
    private let persistence = PersistenceService()

    var snapshot: WeatherSnapshot
    var isLoading = false
    var errorMessage: String?

    init() {
        snapshot = persistence.loadWeatherSnapshot() ?? .placeholder
    }

    func refresh(for location: CLLocation?) async {
        guard let location else {
            errorMessage = "Location is needed for local weather."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let freshSnapshot = try await service.snapshot(for: location)
            snapshot = freshSnapshot
            persistence.saveWeatherSnapshot(freshSnapshot)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// State for the Identify tab: selected image, prediction, loading, and errors.
@MainActor
@Observable
final class IdentificationViewModel {
    private let classificationService = ImageClassificationService()

    var selectedImage: UIImage?
    var prediction: IdentificationPrediction?
    var isClassifying = false
    var errorMessage: String?

    var predictedSpecies: DuckSpecies? {
        guard let prediction else { return nil }
        return DuckData.species(for: prediction.speciesID)
    }

    func identify(image: UIImage) async {
        selectedImage = image
        prediction = nil
        errorMessage = nil
        isClassifying = true
        defer { isClassifying = false }

        do {
            prediction = try await classificationService.classify(image)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        selectedImage = nil
        prediction = nil
        errorMessage = nil
    }
}
