import SwiftUI

struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Support")
                    .font(.title2)
                    .bold()
                Text("Provide contact information, FAQ, and help resources for the app.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Support")
    }
}

#Preview {
    SupportView()
}
