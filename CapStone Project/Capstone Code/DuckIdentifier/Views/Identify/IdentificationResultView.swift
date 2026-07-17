import SwiftUI

struct IdentificationResultView: View {
    let result: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identification Result")
                .font(.headline)

            Text(result)
                .font(.title3)
                .bold()

            Button("Save Sighting") {
                // Placeholder action
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    IdentificationResultView(result: "Mallard")
}
