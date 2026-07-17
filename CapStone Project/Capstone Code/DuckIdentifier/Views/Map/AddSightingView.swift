import SwiftUI

struct AddSightingView: View {
    @State private var speciesName = "Mallard"
    @State private var notes = ""

    var body: some View {
        Form {
            Section("Sighting") {
                TextField("Species", text: $speciesName)
                TextField("Notes", text: $notes)
                Button("Save Sighting") {
                    // Placeholder action
                }
            }
        }
        .navigationTitle("Add Sighting")
    }
}

#Preview {
    AddSightingView()
}
