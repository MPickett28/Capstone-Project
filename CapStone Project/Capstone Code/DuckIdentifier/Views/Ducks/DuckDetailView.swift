import SwiftUI

// This screen gives a bit more detail about the selected duck species.
struct DuckDetailView: View {
    let duck: DuckSpecies

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "bird.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .padding()

                Text(duck.commonName)
                    .font(.title)
                    .bold()

                Text(duck.scientificName)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(duck.description)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Duck Details")
    }
}

#Preview {
    DuckDetailView(duck: DuckSpecies.sampleSpecies[0])
}
