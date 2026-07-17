import SwiftUI

// This is the first screen in the app. It lets the user start the duck identification flow.
struct IdentifyView: View {
    @StateObject private var viewModel = IdentificationViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Identify")
                    .font(.title2)
                    .bold()

                Text("Use your camera or photo library to identify a duck.")
                    .foregroundStyle(.secondary)

                Button("Open Camera") {
                    // Placeholder action
                }
                .buttonStyle(.borderedProminent)

                Button("Choose Photo") {
                    // Placeholder action
                }
                .buttonStyle(.bordered)

                if viewModel.isProcessing {
                    ProgressView("Identifying...")
                }

                if !viewModel.result.isEmpty {
                    IdentificationResultView(result: viewModel.result)
                }
            }
            .padding()
            .navigationTitle("Identify")
        }
    }
}

#Preview {
    IdentifyView()
}
