import SwiftUI

// This screen gives the user a quick Canadian duck hunting reference for the prototype.
struct HuntingRulesView: View {
    private let governmentRulesURL = URL(string: "https://www.canada.ca/en/environment-climate-change/services/migratory-birds-general-regulations.html")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Main Canadian Hunting Rules")
                    .font(.title2)
                    .bold()

                Text("These are quick-reference rules for the app prototype. Always check the latest federal and provincial rules before hunting.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    RuleRow(title: "Freshwater ducks", detail: "Bag limit: 6")
                    RuleRow(title: "Geese", detail: "Bag limit: 3")
                    RuleRow(title: "Licensing", detail: "A valid hunting licence and required tags must be carried.")
                    RuleRow(title: "Season dates", detail: "Check the current season dates for the province and zone you are hunting in.")
                }

                Link("View the official Canadian government rules", destination: governmentRulesURL)
                    .font(.headline)
            }
            .padding()
        }
        .navigationTitle("Hunting Rules")
    }
}

// Simple helper for the rule list so the layout stays clean and readable.
private struct RuleRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    HuntingRulesView()
}
