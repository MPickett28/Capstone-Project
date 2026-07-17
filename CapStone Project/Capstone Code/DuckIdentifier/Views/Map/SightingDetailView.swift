import SwiftUI

struct SightingDetailView: View {
    let sighting: DuckSighting

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sighting.speciesName)
                .font(.title2)
                .bold()

            Text("Date: \(sighting.date, formatter: itemFormatter)")
            Text("Coordinates: \(sighting.latitude), \(sighting.longitude)")

            if let notes = sighting.notes {
                Text("Notes: \(notes)")
            }
        }
        .padding()
        .navigationTitle("Sighting Details")
    }

    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    SightingDetailView(sighting: DuckData.sampleSightings[0])
}
