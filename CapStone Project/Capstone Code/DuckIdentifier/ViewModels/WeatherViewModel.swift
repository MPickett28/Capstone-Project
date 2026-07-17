import Foundation

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherSnapshot?
    private let service = WeatherService()

    func loadWeather() async {
        do {
            weather = try await service.fetchWeather()
        } catch {
            weather = nil
        }
    }
}
