import SwiftUI

// The weather screen is meant to use Apple WeatherKit data in the finished app.
struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Current Weather")
                    .font(.title2)
                    .bold()

                if let weather = viewModel.weather {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Condition: \(weather.condition)")
                        Text("Temperature: \(weather.temperature, specifier: "%.1f°C")")
                        Text("Wind: \(weather.windSpeed, specifier: "%.1f") mph")
                        Text("Precipitation: \(weather.precipitationChance)%")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                } else {
                    Text("No weather data available.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Weather")
            .task {
                await viewModel.loadWeather()
            }
        }
    }
}

#Preview {
    WeatherView()
}
