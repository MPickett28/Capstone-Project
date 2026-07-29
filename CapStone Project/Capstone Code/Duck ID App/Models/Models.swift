import CoreLocation
import Foundation

// Basic duck profile shown in the Ducks tab and used to match ML predictions.
struct DuckSpecies: Identifiable, Hashable, Codable {
    let id: String
    let commonName: String
    let scientificName: String
    let sexNotes: String
    let fieldMarks: [String]
    let habitat: String
    let range: String
    let diet: String
    let conservationStatus: String
    let huntingNote: String
    let imageSystemName: String

    var searchableText: String {
        ([commonName, scientificName, sexNotes, habitat, range, diet, conservationStatus, huntingNote] + fieldMarks)
            .joined(separator: " ")
            .localizedLowercase
    }
}

// A saved sighting pin. Coordinates are stored as numbers so the model stays Codable.
struct DuckSighting: Identifiable, Hashable, Codable {
    let id: UUID
    var speciesID: String
    var speciesName: String
    var date: Date
    var latitude: Double
    var longitude: Double
    var notes: String
    var weatherSummary: String?

    init(id: UUID = UUID(), speciesID: String, speciesName: String, date: Date = Date(), latitude: Double, longitude: Double, notes: String = "", weatherSummary: String? = nil) {
        self.id = id
        self.speciesID = speciesID
        self.speciesName = speciesName
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.weatherSummary = weatherSummary
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// Small cached weather record used by the Weather tab and attached to saved sightings.
struct WeatherSnapshot: Codable, Hashable {
    var temperatureText: String
    var conditionText: String
    var windText: String
    var precipitationText: String
    var observedAt: Date

    static let placeholder = WeatherSnapshot(
        temperatureText: "--",
        conditionText: "Weather unavailable",
        windText: "Wind unavailable",
        precipitationText: "Precipitation unavailable",
        observedAt: Date()
    )
}

// Seed duck data. Add more species here as your app grows.
enum DuckData {
    static let species: [DuckSpecies] = [
        DuckSpecies(id: "mallard", commonName: "Mallard", scientificName: "Anas platyrhynchos", sexNotes: "Males have a glossy green head and yellow bill. Females are mottled brown with an orange-and-black bill.", fieldMarks: ["Blue speculum bordered in white", "Rounded head", "Curled black tail feather on drakes"], habitat: "Ponds, marshes, lakes, rivers, sheltered bays, and agricultural wetlands.", range: "Common across North America and often seen year-round where open water remains.", diet: "Aquatic plants, seeds, insects, grains, and small invertebrates.", conservationStatus: "Secure", huntingNote: "Always verify current provincial/state seasons, limits, and licensing before hunting.", imageSystemName: "bird"),
        DuckSpecies(id: "black-duck", commonName: "American Black Duck", scientificName: "Anas rubripes", sexNotes: "Both sexes are dark brown overall with a paler head and olive-yellow to greenish bill.", fieldMarks: ["Dark body", "Purple-blue speculum without bold white borders", "Contrasting pale face"], habitat: "Coastal marshes, wooded wetlands, bogs, estuaries, and freshwater ponds.", range: "Mostly eastern North America, especially Atlantic flyway wetlands.", diet: "Seeds, aquatic vegetation, mollusks, insects, and grain in nearby fields.", conservationStatus: "Managed conservation concern in parts of its range", huntingNote: "Often has specific bag limits because of management concerns. Check local regulations.", imageSystemName: "bird"),
        DuckSpecies(id: "common-goldeneye", commonName: "Common Goldeneye", scientificName: "Bucephala clangula", sexNotes: "Males are black and white with a round white face spot. Females have a chocolate-brown head and gray body.", fieldMarks: ["Bright yellow eye", "Large triangular head", "Fast wingbeats with whistling flight sound"], habitat: "Boreal lakes during breeding season; coastal bays, rivers, and open water in winter.", range: "Breeds across northern forests and winters widely on ice-free water.", diet: "Aquatic insects, crustaceans, mollusks, small fish, and plant material.", conservationStatus: "Secure", huntingNote: "Diving duck regulations may vary by area and season.", imageSystemName: "bird")
    ]

    static func species(for id: String) -> DuckSpecies? {
        species.first { $0.id == id }
    }
}
