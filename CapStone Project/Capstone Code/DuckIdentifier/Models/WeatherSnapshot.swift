import Foundation

// Weather data used by the weather screen and the saved forecast view.
struct WeatherSnapshot: Identifiable, Codable {
    let id: UUID
    let temperature: Double
    let windSpeed: Double
    let precipitationChance: Int
    let condition: String
    let timestamp: Date
}
