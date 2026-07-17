import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Preferences") {
                Toggle("Enable notifications", isOn: .constant(true))
                Toggle("Save sightings automatically", isOn: .constant(true))
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
