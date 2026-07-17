import SwiftUI

// The Ducks tab shows a simple list of duck species the app can identify or describe.
struct DuckListView: View {
    let ducks = DuckSpecies.sampleSpecies

    var body: some View {
        NavigationStack {
            List(ducks) { duck in
                NavigationLink(destination: DuckDetailView(duck: duck)) {
                    HStack {
                        Image(systemName: "bird.fill")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(duck.commonName)
                                .font(.headline)
                            Text(duck.scientificName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Ducks")
        }
    }
}

#Preview {
    DuckListView()
}
