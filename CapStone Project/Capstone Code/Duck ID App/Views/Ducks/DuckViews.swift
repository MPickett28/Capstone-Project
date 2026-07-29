import SwiftUI

// Searchable field guide list.
struct DuckListView: View {
    @State private var searchText = ""

    private var filteredSpecies: [DuckSpecies] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
        guard !query.isEmpty else { return DuckData.species }
        return DuckData.species.filter { $0.searchableText.contains(query) }
    }

    var body: some View {
        NavigationStack {
            List(filteredSpecies) { species in
                NavigationLink(value: species) { DuckRow(species: species) }
            }
            .navigationTitle("Ducks")
            .searchable(text: $searchText, prompt: "Search ducks")
            .navigationDestination(for: DuckSpecies.self) { species in
                DuckDetailView(species: species)
            }
        }
    }
}

struct DuckRow: View {
    let species: DuckSpecies

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: species.imageSystemName)
                .font(.title2)
                .foregroundStyle(.teal)
                .frame(width: 42, height: 42)
                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(species.commonName).font(.headline)
                Text(species.scientificName).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Detailed species profile shown from the Ducks tab.
struct DuckDetailView: View {
    let species: DuckSpecies

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: species.imageSystemName)
                        .font(.system(size: 56))
                        .foregroundStyle(.teal)
                        .frame(maxWidth: .infinity)
                    Text(species.scientificName).font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Field Marks") {
                ForEach(species.fieldMarks, id: \.self) { mark in
                    Label(mark, systemImage: "checkmark.circle")
                }
            }

            Section("Identification") { Text(species.sexNotes) }
            Section("Habitat") { Text(species.habitat) }
            Section("Range") { Text(species.range) }
            Section("Diet") { Text(species.diet) }
            Section("Status") { Text(species.conservationStatus) }
            Section("Hunting") { Text(species.huntingNote) }
        }
        .navigationTitle(species.commonName)
    }
}
