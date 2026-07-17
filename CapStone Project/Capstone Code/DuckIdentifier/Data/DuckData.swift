import Foundation

// Temporary sample data to wire the app together while the real backend is added.
final class DuckData {
    static let species = DuckSpecies.sampleSpecies

    static let sampleSightings: [DuckSighting] = [
        DuckSighting(id: UUID(), speciesName: "Mallard", latitude: 42.3601, longitude: -71.0589, date: Date(), notes: "Seen near the pond"),
        DuckSighting(id: UUID(), speciesName: "Black Duck", latitude: 42.3610, longitude: -71.0602, date: Date().addingTimeInterval(-3600), notes: "Observed flying overhead")
    ]

    static let sampleWeather = WeatherSnapshot(
        id: UUID(),
        temperature: 18.0,
        windSpeed: 8.0,
        precipitationChance: 20,
        condition: "Partly Cloudy",
        timestamp: Date()
    )
}
