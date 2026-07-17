import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Sightings", destination: Text("Sightings"))
                NavigationLink("Hunting Rules", destination: HuntingRulesView())
                NavigationLink("Resources", destination: ResourcesView())
                NavigationLink("Settings", destination: SettingsView())
                NavigationLink("Support", destination: SupportView())
            }
            .navigationTitle("More")
        }
    }
}

#Preview {
    MoreView()
}
