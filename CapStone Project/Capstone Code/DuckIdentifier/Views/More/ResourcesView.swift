import SwiftUI

struct ResourcesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Resources")
                    .font(.title2)
                    .bold()
                Text("Add educational materials, conservation links, and support articles here.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Resources")
    }
}

#Preview {
    ResourcesView()
}
