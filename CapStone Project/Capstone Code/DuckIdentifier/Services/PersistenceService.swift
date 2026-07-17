import Foundation

final class PersistenceService {
    func saveSighting(_ sighting: DuckSighting) {
        // Placeholder for persistence logic.
    }

    func loadSightings() -> [DuckSighting] {
        DuckData.sampleSightings
    }
}
