import SwiftUI

struct CameraPicker: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Camera / Photo Picker")
                .font(.headline)
            Text("This view will handle camera capture and photo library selection.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    CameraPicker()
}
