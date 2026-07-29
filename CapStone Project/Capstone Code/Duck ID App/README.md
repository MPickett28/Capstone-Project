# Duck ID App

Duck ID App is a SwiftUI field guide and sighting log for iPhone and iPad. It can classify a Mallard photo as male or female, show basic information about several duck species, save sightings at the user's current location, display those sightings on a map, and retrieve local weather from Apple's WeatherKit.

For a file-by-file and function-by-function explanation of the code, see [HOW_IT_WORKS.md](HOW_IT_WORKS.md).

## Main features

- Identify a duck from the camera or photo library with Core ML and Vision.
- Browse and search a small built-in duck field guide.
- Save a sighting with coordinates, notes, and the latest weather condition.
- View saved sightings as MapKit markers or as a list.
- Display current temperature, conditions, wind, and precipitation chance.
- Keep sightings and the last successful weather result on the device.

## Requirements

- macOS with Xcode 26.4 or a version that supports the project's file format and SDK.
- An iPhone/iPad or simulator running iOS/iPadOS 26.4 or later (the current deployment target).
- An Apple development team for code signing.
- WeatherKit enabled for the app identifier if live weather is required.
- A physical device to test the camera, heading, and realistic location behavior.

The app uses only Apple frameworks; there are no third-party package dependencies.

## Running the project

1. Open `Duck ID App.xcodeproj` in Xcode.
2. Select the **Duck ID App** target, then choose your development team under **Signing & Capabilities**.
3. Confirm that the **WeatherKit** capability is enabled. The repository already contains the WeatherKit entitlement, but the app identifier and development team must also support it.
4. Add privacy usage descriptions in the target's **Info** settings if they are not already supplied by your local Xcode configuration:
   - **Privacy - Camera Usage Description** (`NSCameraUsageDescription`)
   - **Privacy - Location When In Use Usage Description** (`NSLocationWhenInUseUsageDescription`)
5. Select a simulator or connected device and run the **Duck ID App** scheme.
6. Allow location, camera, and photo-library access when prompted. The photo picker uses the system picker, while direct camera capture requires camera permission.

WeatherKit may not return live data in an unsigned or incorrectly provisioned build. The rest of the app can still be explored without live weather.

## How the code works

The app follows a lightweight Model-View-ViewModel style. SwiftUI views render the interface, observable view models hold changing state, services communicate with Apple frameworks and local storage, and model structs describe the data passed between those layers.

```text
Duck_ID_AppApp
    -> ContentView
        -> MainTabView
            -> creates shared LocationManager
            -> creates shared SightingsViewModel
            -> creates shared WeatherViewModel
            -> injects them into five tabs through SwiftUI's environment

User action -> View -> ViewModel -> Service / Apple framework
                              -> observable state changes -> View redraws
```

All three shared objects are created once by `MainTabView`, so the Map, Weather, Identify, and More screens see the same location, weather, and sighting data.

### App entry and navigation

- `Duck ID App/Duck_ID_AppApp.swift` is the `@main` entry point and opens `ContentView`.
- `Duck ID App/ContentView.swift` keeps the root view small and presents `MainTabView`.
- `Views/MainTab/MainTabView.swift` creates the shared state, starts location updates, and defines the five tabs: **Identify**, **Ducks**, **Map**, **Weather**, and **More**.

### Models and built-in duck data

`Models/Models.swift` contains the app's value types:

- `DuckSpecies` stores field-guide information and builds one lowercase `searchableText` string for filtering.
- `DuckSighting` stores a species, date, latitude, longitude, notes, and an optional weather summary. Latitude and longitude are plain numbers so the type remains `Codable`.
- `WeatherSnapshot` stores formatted strings for the weather screen and provides a placeholder when no cached result exists.
- `DuckData` contains the built-in profiles for Mallard, American Black Duck, and Common Goldeneye, and provides lookup by species ID.

To add another field-guide species, add another `DuckSpecies` value to `DuckData.species`. This makes it appear in the Ducks tab and in the manual sighting picker. It does not automatically teach the image classifier the new species.

### Observable state

`Views/Models/ViewModels.swift` contains three `@Observable` classes:

- `SightingsViewModel` loads sightings at startup, keeps them newest-first, and saves after every add or delete.
- `WeatherViewModel` begins with the most recently cached snapshot, requests fresh WeatherKit data, and exposes loading or error state.
- `IdentificationViewModel` owns the selected image and calls the classification service asynchronously.

These types are `@MainActor`, which keeps UI-facing state changes on the main actor.

### Image-identification flow

The identification UI is in `Views/Identify/IdentifyViews.swift`:

1. The user takes a photo with `UIImagePickerController` or selects one with `PhotosPicker`.
2. The selected data is converted to a `UIImage`.
3. `IdentificationViewModel.identify(image:)` calls `ImageClassificationService`.
4. The service finds the compiled `DuckClassifier.mlmodelc` in the app bundle, wraps it in a Vision model, center-crops the image, and performs a `VNCoreMLRequest` on a background queue.
5. The highest-ranked `VNClassificationObservation` becomes an `IdentificationPrediction`.
6. A `male` label is displayed as **Male Mallard** and a `female` label as **Female Mallard**. The result view displays confidence and lets the user save the result at the current coordinate.

The source model is `MachineLearning/DuckClassifier.mlmodel`. If it is missing from the built app, the service deliberately returns a zero-confidence Mallard fallback and the UI displays **Model needed** instead of a percentage.

### Location, sightings, and maps

`LocationManager` in `Services/Services.swift` wraps `CLLocationManager`. It requests when-in-use authorization, publishes the latest location and compass heading, and reports location errors.

`Views/Map/MapWeatherViews.swift` uses that state in several ways:

- `SightingMapView` embeds a hybrid MapKit map, adds a marker for every saved sighting, and centers on the current location.
- Selecting a marker opens `SightingDetailView`.
- `AddSightingView` lets the user select a field-guide species and save it at the current coordinate.
- An identification result can also create a sighting without opening the Map tab.

The app does not upload sightings or share them between devices.

### Weather flow

`DuckWeatherService` calls `WeatherService.shared.weather(for:)` with the current `CLLocation`. It converts the response into a small `WeatherSnapshot` containing formatted temperature, condition, wind, and the first hourly forecast's precipitation chance.

`WeatherView` requests a refresh when it appears and when the user taps the refresh button. A successful result is cached and is also available as the weather summary attached to a newly saved sighting.

### Local persistence

`PersistenceService` encodes values as JSON and stores the resulting `Data` in `UserDefaults` under two keys:

- `savedDuckSightings` for the complete sighting array.
- `lastWeatherSnapshot` for the last successful weather response.

This is suitable for the app's small amount of data. Deleting the app or clearing its data removes these records. For a much larger collection, photos, or synchronization, this layer would be the place to introduce SwiftData, Core Data, CloudKit, or file storage.

### Remaining screens

- `Views/Ducks/DuckViews.swift` implements the searchable field-guide list and species detail pages.
- `Views/More/MoreViews.swift` contains the saved-sighting list, hunting reminders, external learning links, settings, and support information.
- Saved sightings can be deleted by swiping a row in **More > Sightings**.

## Project structure

```text
Duck ID App/
|-- Duck ID App.xcodeproj/       Xcode project and build settings
|-- Duck ID App/                 App entry point, root view, assets, entitlements
|-- Models/Models.swift          Data structures and built-in field-guide records
|-- Services/Services.swift      Persistence, location, weather, and ML services
|-- Views/
|   |-- Models/                  Observable view models
|   |-- MainTab/                 Shared state and tab navigation
|   |-- Identify/                Camera/library selection and result UI
|   |-- Ducks/                   Searchable field guide
|   |-- Map/                     Map, manual sightings, details, and weather UI
|   `-- More/                    Sightings list, information, and settings
|-- MachineLearning/             Core ML model included in the app target
`-- Mallard_Data/                Create ML development dataset (not app resources)
```

## Machine-learning data

`Mallard_Data` is organized in the class-folder format expected by Create ML:

| Split | Female | Male | Total |
|---|---:|---:|---:|
| Training | 546 | 904 | 1,450 |
| Validation | 117 | 193 | 310 |
| Testing | 118 | 195 | 313 |
| **Total** | **781** | **1,292** | **2,073** |

The image folders are not members of the app target and are not needed at runtime. They are used to train or evaluate a replacement model. After training in Create ML, export it as `DuckClassifier.mlmodel`, replace the file in `MachineLearning`, ensure its target membership is enabled, and rebuild the app.

Model output labels must agree with the mapping in `IdentificationPrediction.displayName` and `ImageClassificationService`. The current code explicitly understands `male` and `female`; a multi-species model will require updating that mapping and adding matching `DuckData` records.

## Current limitations

- The classifier is a binary male/female Mallard model, not a general classifier for every species in the field guide.
- A zero-confidence Mallard is used when the compiled model cannot be found.
- Sightings store text and coordinates but do not retain the selected photo.
- Sighting and weather storage is local `UserDefaults`; there is no account, cloud sync, or export.
- Hunting information is a reminder only and is not a live regulations service.
- The **Metric Units** and **Save Weather With Sightings** toggles are persisted with `@AppStorage`, but the current weather formatting and save flow do not yet read those settings.
- There is currently no automated test target in the Xcode project.

## Frameworks used

- **SwiftUI** and **Observation** for UI and state management
- **PhotosUI** and **UIKit** for photo-library and camera input
- **Core ML** and **Vision** for image classification
- **CoreLocation** for coordinates and compass heading
- **MapKit** for the embedded sighting map
- **WeatherKit** for current local weather
- **Foundation/UserDefaults** for JSON-based local persistence
