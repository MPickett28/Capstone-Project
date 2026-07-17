import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("About")
                    .font(.title2)
                    .bold()
                Text("Duck Identifier helps users identify local duck species, track sightings, and review weather conditions.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("About")
    }
}

#Preview {
    AboutView()
}
