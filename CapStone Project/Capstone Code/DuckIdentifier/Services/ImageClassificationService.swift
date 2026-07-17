import Foundation
import Vision
import CoreML

// This is the place where the app's duck classifier will use project-owned data in the real build.
final class ImageClassificationService {
    func classify(imageData: Data) async throws -> String {
        "Mallard"
    }
}
