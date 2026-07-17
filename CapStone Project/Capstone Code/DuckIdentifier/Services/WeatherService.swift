import Foundation

// This service is the bridge between the weather screen and the Apple weather API in the finished app.
final class WeatherService {
    func fetchWeather() async throws -> WeatherSnapshot {
        DuckData.sampleWeather
    }
}
