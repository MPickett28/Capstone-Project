import PhotosUI
import SwiftUI
import UIKit

// Identify tab. Handles photo selection and sends the image to the classification view model.
struct IdentifyView: View {
    @State private var viewModel = IdentificationViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showsCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imagePreview
                    imageSourceButtons

                    if viewModel.isClassifying {
                        ProgressView("Identifying").frame(maxWidth: .infinity)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        ContentUnavailableView("Identification Issue", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                    }

                    if let species = viewModel.predictedSpecies, let prediction = viewModel.prediction {
                        IdentificationResultView(species: species, prediction: prediction)
                    }
                }
                .padding()
            }
            .navigationTitle("Identify")
            .toolbar {
                if viewModel.selectedImage != nil {
                    Button("Clear") {
                        viewModel.clear()
                        selectedPhoto = nil
                    }
                }
            }
            .sheet(isPresented: $showsCamera) {
                CameraPicker(sourceType: .camera) { image in
                    Task { await viewModel.identify(image: image) }
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhoto) { _, newValue in loadPhoto(newValue) }
        }
    }

    private var imagePreview: some View {
        Group {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ContentUnavailableView("Choose a Duck Photo", systemImage: "camera.viewfinder", description: Text("Use the camera or photo library to identify a duck."))
                    .frame(minHeight: 260)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var imageSourceButtons: some View {
        HStack(spacing: 12) {
            Button { showsCamera = true } label: {
                Label("Camera", systemImage: "camera").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Library", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // Loads a selected Photos item into UIImage before classification.
    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                viewModel.errorMessage = "The selected photo could not be loaded."
                return
            }
            await viewModel.identify(image: image)
        }
    }
}

// UIKit bridge for the system camera picker.
struct CameraPicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { onImagePicked(image) }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// Shows the best match and lets the user save it as a mapped sighting.
struct IdentificationResultView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(SightingsViewModel.self) private var sightingsViewModel
    @Environment(WeatherViewModel.self) private var weatherViewModel

    let species: DuckSpecies
    let prediction: IdentificationPrediction

    @State private var notes = ""
    @State private var didSave = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.displayName).font(.title2.bold())
                    Text(species.commonName).font(.subheadline).foregroundStyle(.secondary)
                }

                Spacer()

                Text(prediction.confidence > 0 ? prediction.confidence.formatted(.percent.precision(.fractionLength(0))) : "Model needed")
                    .font(prediction.confidence > 0 ? .headline : .caption.bold())
                    .foregroundStyle(prediction.confidence > 0 ? .teal : .orange)
            }

            Text(species.sexNotes)

            if !prediction.classificationLabel.isEmpty {
                LabeledContent("Model label", value: prediction.classificationLabel)
                    .font(.subheadline)
            }

            TextField("Sighting notes", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)

            Button { saveSighting() } label: {
                Label(didSave ? "Saved" : "Save Sighting", systemImage: didSave ? "checkmark.circle.fill" : "mappin.and.ellipse")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(locationManager.currentLocation == nil || didSave)

            if locationManager.currentLocation == nil {
                Text("Enable location to save the sighting on the map.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func saveSighting() {
        guard let coordinate = locationManager.currentLocation?.coordinate else { return }
        sightingsViewModel.addSighting(species: species, coordinate: coordinate, notes: notes, weatherSummary: weatherViewModel.snapshot.conditionText)
        didSave = true
    }
}
