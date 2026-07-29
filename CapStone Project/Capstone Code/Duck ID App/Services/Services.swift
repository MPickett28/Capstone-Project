import CoreLocation
import CoreML
import Foundation
import Observation
import UIKit
import Vision
import WeatherKit

// Saves sightings and the last weather snapshot locally using UserDefaults.
struct PersistenceService {
    private let sightingsKey = "savedDuckSightings"
    private let weatherKey = "lastWeatherSnapshot"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func loadSightings() -> [DuckSighting] {
        guard let data = UserDefaults.standard.data(forKey: sightingsKey) else { return [] }
        return (try? decoder.decode([DuckSighting].self, from: data)) ?? []
    }

    func saveSightings(_ sightings: [DuckSighting]) {
        guard let data = try? encoder.encode(sightings) else { return }
        UserDefaults.standard.set(data, forKey: sightingsKey)
    }

    func loadWeatherSnapshot() -> WeatherSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: weatherKey) else { return nil }
        return try? decoder.decode(WeatherSnapshot.self, from: data)
    }

    func saveWeatherSnapshot(_ snapshot: WeatherSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: weatherKey)
    }
}

// Wraps CoreLocation so SwiftUI views can read current location and compass heading.
@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus
    var currentLocation: CLLocation?
    var heading: CLHeading?
    var errorMessage: String?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
    }

    func requestPermission() { manager.requestWhenInUseAuthorization() }

    func start() {
        if authorizationStatus == .notDetermined { requestPermission() }
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { manager.startUpdatingHeading() }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            errorMessage = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in heading = newHeading }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in errorMessage = error.localizedDescription }
    }
}

// Uses Apple's WeatherKit API. The app target still needs the WeatherKit capability enabled.
struct DuckWeatherService {
    private let service = WeatherService.shared

    func snapshot(for location: CLLocation) async throws -> WeatherSnapshot {
        let weather = try await service.weather(for: location)
        let current = weather.currentWeather
        let precipitationChance = weather.hourlyForecast.first?.precipitationChance ?? 0

        return WeatherSnapshot(
            temperatureText: current.temperature.formatted(.measurement(width: .abbreviated, usage: .weather)),
            conditionText: current.condition.description,
            windText: current.wind.speed.formatted(.measurement(width: .abbreviated)),
            precipitationText: precipitationChance.formatted(.percent.precision(.fractionLength(0))),
            observedAt: current.date
        )
    }
}

struct IdentificationPrediction: Hashable {
    var speciesID: String
    var speciesName: String
    var classificationLabel: String
    var confidence: Double

    var displayName: String {
        switch classificationLabel.localizedLowercase {
        case "male":
            return "Male Mallard"
        case "female":
            return "Female Mallard"
        default:
            return speciesName
        }
    }
}

// Runs DuckClassifier.mlmodel through Vision. Until that model exists, it returns a fallback result.
struct ImageClassificationService {
    enum ClassificationError: LocalizedError {
        case invalidImage
        case noResult

        var errorDescription: String? {
            switch self {
            case .invalidImage: "The selected image could not be processed."
            case .noResult: "The classifier did not return a result."
            }
        }
    }

    func classify(_ image: UIImage) async throws -> IdentificationPrediction {
        guard let modelURL = Bundle.main.url(forResource: "DuckClassifier", withExtension: "mlmodelc") else {
            let species = DuckData.species[0]
            return IdentificationPrediction(speciesID: species.id, speciesName: species.commonName, classificationLabel: "", confidence: 0)
        }

        let coreModel = try MLModel(contentsOf: modelURL)
        let visionModel = try VNCoreMLModel(for: coreModel)
        guard let cgImage = image.cgImage else { throw ClassificationError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observation = request.results?.compactMap({ $0 as? VNClassificationObservation }).first else {
                    continuation.resume(throwing: ClassificationError.noResult)
                    return
                }

                let species = DuckData.species.first {
                    observation.identifier.localizedCaseInsensitiveContains($0.commonName) || observation.identifier.localizedCaseInsensitiveContains($0.id)
                } ?? DuckData.species[0]

                continuation.resume(returning: IdentificationPrediction(speciesID: species.id, speciesName: species.commonName, classificationLabel: observation.identifier, confidence: Double(observation.confidence)))
            }

            request.imageCropAndScaleOption = .centerCrop
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try VNImageRequestHandler(cgImage: cgImage).perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
