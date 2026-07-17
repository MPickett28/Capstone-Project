import Foundation

@MainActor
final class SightingsViewModel: ObservableObject {
    @Published var sightings: [DuckSighting] = []
    private let persistence = PersistenceService()

    func loadSightings() {
        sightings = persistence.loadSightings()
    }

    func addSighting(_ sighting: DuckSighting) {
        persistence.saveSighting(sighting)
        sightings.append(sighting)
    }
}
