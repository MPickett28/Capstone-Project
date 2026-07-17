import Foundation
import SwiftUI

@MainActor
final class IdentificationViewModel: ObservableObject {
    @Published var result: String = ""
    @Published var isProcessing = false

    private let classifier = ImageClassificationService()

    func identify(imageData: Data) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            result = try await classifier.classify(imageData: imageData)
        } catch {
            result = "Unable to identify duck"
        }
    }
}
