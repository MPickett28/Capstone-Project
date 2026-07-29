# How Duck ID App Works

This document is a detailed tour of the Duck ID App codebase. It explains how the files connect, what each type does, how data moves through the app, and what happens when the user performs the main actions.

For installation and project requirements, see [README.md](README.md).

## 1. The overall design

The app is divided into four main layers:

| Layer | Responsibility | Main location |
|---|---|---|
| Models | Describe ducks, sightings, weather, and predictions | `Models/Models.swift` and `IdentificationPrediction` |
| Services | Talk to storage and Apple frameworks | `Services/Services.swift` |
| View models | Hold changing screen state and coordinate work | `Views/Models/ViewModels.swift` |
| Views | Draw the interface and respond to user input | `Views/**` |

This is similar to the Model-View-ViewModel pattern:

```text
User
  -> taps or selects something in a View
  -> View calls a ViewModel method
  -> ViewModel calls a Service
  -> Service uses Core ML, CoreLocation, WeatherKit, or UserDefaults
  -> result is stored in observable ViewModel state
  -> SwiftUI sees the state change and redraws the affected View
```

The layers are intentionally small. For example, the weather screen does not call WeatherKit directly. It asks `WeatherViewModel`, which asks `DuckWeatherService`, and the result is converted to the app's own `WeatherSnapshot` model.

## 2. Swift concepts used throughout the project

Understanding these features makes the rest of the code easier to follow.

### `struct` and `class`

Most SwiftUI views and data models are `struct` values. SwiftUI can create new view values whenever state changes, so views should describe the desired interface rather than manually modifying controls.

The observable managers and view models are `class` reference types. Multiple views can refer to the same instance and therefore see the same location, sightings, or weather state.

### Protocol conformances

- `View` means a type can describe SwiftUI interface content through its `body` property.
- `App` marks the type that describes the application's scenes.
- `Identifiable` gives each value a stable `id`, allowing `List` and `ForEach` to track rows.
- `Hashable` allows values to be compared, used in navigation, attached to map selections, or stored in hashed collections.
- `Codable` combines `Encodable` and `Decodable`, allowing a value to be converted to and from JSON.
- `LocalizedError` lets a custom error provide readable text through `errorDescription`.
- `CLLocationManagerDelegate` and `UIImagePickerControllerDelegate` receive callbacks from UIKit/CoreLocation objects.

### Property wrappers and macros

- `@main` identifies the application's entry point.
- `@Observable` makes stored properties observable. When one changes, SwiftUI views reading it can update.
- `@State` gives a view ownership of temporary, mutable UI state. SwiftUI preserves it while the view remains active.
- `@Environment(Type.self)` retrieves a shared observable object inserted by an ancestor view.
- `@Environment(\.dismiss)` retrieves SwiftUI's action for closing the current sheet or presented screen.
- `@AppStorage("key")` reads and writes a simple value in `UserDefaults` automatically.
- `@MainActor` requires UI-facing state and methods to run on the main actor, preventing unsafe concurrent UI updates.

The `$` prefix creates a binding to a state value. For example, `$selectedPhoto` lets `PhotosPicker` both read the selection and write a new selection into the view's state.

### `async`, `await`, `Task`, and `throws`

Location, weather, photo loading, and model work may take time. An `async` function can suspend without freezing the UI, and `await` marks a call that may suspend. `Task { ... }` starts asynchronous work from a synchronous button, view modifier, or delegate callback.

A `throws` function can fail. Callers use `try` and normally a `do/catch` block to turn the failure into an error message for the UI.

### Optionals and `guard`

Types ending in `?`, such as `CLLocation?`, may contain a value or `nil`. The app uses `guard let` and `if let` to safely unwrap them. A guard exits the current function early when required data is missing.

## 3. Application startup

### `Duck ID App/Duck_ID_AppApp.swift`

`import SwiftUI` makes the SwiftUI types available.

`@main struct Duck_ID_AppApp: App` is the entry point created by iOS when the user launches the application. Its `body` returns a `Scene`, not a normal view, because an app can own one or more windows or scenes.

`WindowGroup` asks SwiftUI to manage the application's window. The first view placed inside the window is `ContentView()`.

Startup is therefore:

```text
iOS launches app
  -> Duck_ID_AppApp.body
  -> WindowGroup
  -> ContentView
  -> MainTabView
```

### `Duck ID App/ContentView.swift`

`ContentView` is a small root view. Its entire `body` returns `MainTabView()`, keeping startup separate from feature navigation.

The `#Preview` block is only for Xcode's preview canvas. It creates a `ContentView` without changing the production app.

## 4. Shared navigation and state

### `Views/MainTab/MainTabView.swift`

`MainTabView` owns the three objects that need to be shared between several screens:

- `locationManager` contains authorization, current location, heading, and location errors.
- `sightingsViewModel` contains the saved sightings.
- `weatherViewModel` contains cached or freshly loaded weather.

They use `@State` so SwiftUI keeps each object alive across redraws of `MainTabView`.

The `TabView` creates five top-level tabs:

1. `IdentifyView`
2. `DuckListView`
3. `SightingMapView`
4. `WeatherView`
5. `MoreView`

Each `.tabItem` supplies the visible tab name and an SF Symbol.

The three `.environment(...)` modifiers place the shared objects into the environment below `MainTabView`. A child view can then retrieve the same instance by writing, for example:

```swift
@Environment(SightingsViewModel.self) private var sightingsViewModel
```

The `.task` modifier calls `locationManager.start()` when the tab interface becomes active. This begins the location-permission/update process early so coordinates are more likely to be ready when another tab needs them.

## 5. Data models and seed data

### `Models/Models.swift`

This file imports `Foundation` for types such as `UUID`, `Date`, and `Codable`, and `CoreLocation` for `CLLocationCoordinate2D`.

### `DuckSpecies`

`DuckSpecies` represents one entry in the field guide. Its properties contain:

- A stable text `id`, such as `mallard`.
- Common and scientific names.
- Identification notes and a list of field marks.
- Habitat, range, diet, conservation, and hunting text.
- An SF Symbol name used as the current placeholder artwork.

Most properties are `let`, so a species record cannot be changed after it is created.

`searchableText` is a computed property. It combines all useful text fields and the field-mark array, joins them with spaces, and lowercases the result. `DuckListView` can then search one string instead of checking every property separately.

### `DuckSighting`

`DuckSighting` is the saved record used by both the map and sightings list.

- `id` is a `UUID`, giving every sighting a unique identity.
- `speciesID` connects the record to a `DuckSpecies` entry.
- `speciesName` stores a display name directly, so an old sighting remains readable even if the field-guide data changes.
- `date` records when the sighting object was created.
- `latitude` and `longitude` store the position as `Double` values.
- `notes` stores user-entered text.
- `weatherSummary` is optional because weather may be unavailable.

The initializer supplies useful defaults: a new UUID, the current date, empty notes, and no weather. Callers only need to provide the required species and coordinates.

The computed `coordinate` property converts the two stored numbers into `CLLocationCoordinate2D` when MapKit needs a coordinate. The code stores numbers instead of `CLLocationCoordinate2D` because the plain numeric representation is easy to encode with `Codable`.

### `WeatherSnapshot`

`WeatherSnapshot` is the app's small, storage-friendly weather model. It holds already formatted strings rather than WeatherKit's complete response.

`placeholder` is a static default displayed before any successful weather request. It prevents the view from needing an optional snapshot and gives the UI meaningful unavailable text.

### `DuckData`

`DuckData` is an `enum` used as a namespace. No `DuckData` instance needs to be created.

`species` is the hard-coded field-guide array containing Mallard, American Black Duck, and Common Goldeneye. Views use this single array for the searchable guide and manual-sighting picker.

`species(for:)` searches the array for the first record whose ID equals the supplied ID. It returns an optional because an ID might not exist.

Adding a record to this array adds it to the guide and picker. It does not retrain or expand the Core ML model.

## 6. Services

### `Services/Services.swift`

This file integrates the app with local storage, CoreLocation, WeatherKit, Core ML, and Vision.

### `PersistenceService`

`PersistenceService` is a small wrapper around `UserDefaults`.

The two private key strings identify the stored values. Keeping them in one place prevents accidental differences between save and load operations. `JSONEncoder` and `JSONDecoder` convert the app's `Codable` models to and from `Data`.

`loadSightings()` works as follows:

1. Ask `UserDefaults` for `Data` under `savedDuckSightings`.
2. Return an empty array if nothing has been saved.
3. Attempt to decode `[DuckSighting]` from the data.
4. Return an empty array if decoding fails.

`saveSightings(_:)` performs the reverse process. It JSON-encodes the complete array and stores the resulting `Data`. If encoding fails, the function returns without saving.

`loadWeatherSnapshot()` and `saveWeatherSnapshot(_:)` use the same pattern for one `WeatherSnapshot`. The load method returns `nil` when nothing valid is cached.

This service deliberately hides persistence errors with `try?`. That keeps the UI simple, but it also means users are not told if stored data becomes invalid.

### `LocationManager`

`LocationManager` inherits from `NSObject` because `CLLocationManager` uses Objective-C delegate patterns. It conforms to `CLLocationManagerDelegate` so CoreLocation can send it authorization, location, heading, and error events.

Its observable properties are:

- `authorizationStatus`: the current permission state.
- `currentLocation`: the latest location, or `nil` before one arrives.
- `heading`: the latest compass reading, or `nil` if unavailable.
- `errorMessage`: readable text from the latest location failure.

In `init()` it reads the existing authorization state, assigns itself as the underlying manager's delegate, requests accuracy to roughly the nearest ten metres, and sets a ten-metre movement filter. The filter means CoreLocation generally does not need to report every tiny position change.

`requestPermission()` asks for when-in-use access. iOS presents the system permission prompt, provided the app has a location usage description in its generated Info.plist.

`start()` requests permission if it has never been decided, starts location updates, and starts heading updates if the device has a compass.

The delegate methods are marked `nonisolated` because CoreLocation does not promise to call them on the main actor. Each callback creates a `Task { @MainActor in ... }` before changing observable UI state:

- `locationManagerDidChangeAuthorization` updates the status and restarts location updates after permission is granted.
- `didUpdateLocations` takes the newest location, stores it, and clears the last error.
- `didUpdateHeading` stores the new compass heading.
- `didFailWithError` stores the error's localized description.

### `DuckWeatherService`

This service keeps a reference to `WeatherService.shared`, Apple's shared WeatherKit service.

`snapshot(for:)` is asynchronous and throwing because a network/service request can take time or fail. It:

1. Requests weather for a `CLLocation`.
2. Reads the current-weather result.
3. Uses the first hourly forecast's precipitation chance, or zero if no hourly entry exists.
4. Formats temperature, condition, wind speed, and precipitation for display.
5. Returns the much smaller `WeatherSnapshot` used by the app.

WeatherKit authorization depends on the target entitlement, code signing, and App ID configuration.

### `IdentificationPrediction`

This type is the app's simplified classification result:

- `speciesID` links to the field guide.
- `speciesName` is a fallback display name.
- `classificationLabel` is the raw label produced by Core ML.
- `confidence` is a value between zero and one.

`displayName` lowercases the label and changes `male` to `Male Mallard` and `female` to `Female Mallard`. Any other label displays `speciesName`.

### `ImageClassificationService`

`ClassificationError` defines readable failures for an invalid image and an empty classifier result.

`classify(_:)` performs the model inference:

1. Look in the built application bundle for `DuckClassifier.mlmodelc`. Xcode compiles the source `.mlmodel` into `.mlmodelc` during the build.
2. If the compiled model is missing, return the first field-guide species—currently Mallard—with an empty label and zero confidence. This is why the UI can display `Model needed` without crashing.
3. Load the compiled model with `MLModel`.
4. Wrap it in `VNCoreMLModel` so Vision can preprocess the image and return classification observations.
5. Extract a `CGImage` from the selected `UIImage`; throw `invalidImage` if that is impossible.
6. Use `withCheckedThrowingContinuation` to expose Vision's callback-based API as an `async throws` function.
7. Create a `VNCoreMLRequest` and inspect its first `VNClassificationObservation`, which is the highest-ranked result.
8. Try to match the raw model label against a field-guide common name or ID. If none matches, use the first species, Mallard.
9. Resume the awaiting function with an `IdentificationPrediction` containing the raw label and confidence.

`request.imageCropAndScaleOption = .centerCrop` makes Vision crop the image around its center to match the model input shape. This avoids stretching but may exclude a duck near the edge of a photo.

The request is performed on a global user-initiated queue so CPU-heavy image processing does not freeze the main interface.

The bundled model labels are `Male` and `Female`. Those labels do not contain a field-guide species name, so the service uses the Mallard fallback species and `displayName` adds the sex-specific name.

## 7. View models

### `Views/Models/ViewModels.swift`

The three view models are `@MainActor` and `@Observable`. Views read their properties, and SwiftUI redraws when those properties change.

### `SightingsViewModel`

At initialization, it loads the sighting array and sorts it newest-first with `$0.date > $1.date`.

`addSighting(...)` builds a `DuckSighting` from a species and `CLLocationCoordinate2D`, inserts it at index zero so it immediately appears first, and persists the new complete array.

`deleteSightings(at:)` receives an `IndexSet` from SwiftUI's swipe-to-delete system, removes those rows, and saves the remaining array.

### `WeatherViewModel`

It owns a `DuckWeatherService`, a `PersistenceService`, the current `snapshot`, a loading flag, and an optional error message.

During initialization it loads cached weather or uses `WeatherSnapshot.placeholder`.

`refresh(for:)`:

1. Rejects a missing location with a readable error.
2. Sets `isLoading` to true.
3. Uses `defer` to guarantee that `isLoading` returns to false whether the request succeeds or fails.
4. Awaits a fresh snapshot.
5. On success, updates observable state, saves the snapshot, and clears the error.
6. On failure, preserves the previous/cached snapshot and displays the new error.

### `IdentificationViewModel`

This view model owns the selected `UIImage`, optional result, classification loading flag, and optional error.

`predictedSpecies` is computed from the prediction's `speciesID` and `DuckData.species(for:)`.

`identify(image:)` saves the selected image for the preview, clears the previous result/error, turns on the loading indicator, and awaits `ImageClassificationService.classify`. It stores either the prediction or the error text, and `defer` always turns loading off.

`clear()` removes the selected image, prediction, and error so the Identify screen returns to its initial state.

## 8. Identify screen

### `Views/Identify/IdentifyViews.swift`

This file imports `PhotosUI` for the photo picker, `UIKit` for `UIImagePickerController`, and `SwiftUI` for the screen.

### `IdentifyView`

The view owns three pieces of local state:

- One `IdentificationViewModel` for image/result state.
- The selected `PhotosPickerItem`.
- A Boolean controlling whether the camera sheet is visible.

The body uses `NavigationStack` for a title and toolbar, `ScrollView` so results fit on smaller devices, and a vertical stack for the content.

Conditional UI is driven by view-model state:

- `isClassifying` shows a progress indicator.
- `errorMessage` shows an error placeholder.
- A non-nil predicted species and prediction show `IdentificationResultView`.
- A selected image adds a **Clear** toolbar button.

`imagePreview` either converts the selected `UIImage` into a resizable SwiftUI `Image` or displays instructions. `scaledToFit` preserves the photo's aspect ratio.

`imageSourceButtons` contains:

- A Camera button that sets `showsCamera` to true.
- A `PhotosPicker` restricted to image media that writes into `selectedPhoto`.

The camera `.sheet` creates `CameraPicker`. Its completion closure receives a `UIImage`, starts a task, and awaits identification.

`.onChange(of: selectedPhoto)` calls `loadPhoto` whenever the library selection changes. `loadPhoto` asynchronously requests the selected asset as `Data`, creates a `UIImage`, reports a loading error if conversion fails, and otherwise begins identification.

### `CameraPicker`

`UIImagePickerController` is a UIKit controller, so it cannot be inserted into SwiftUI directly. `UIViewControllerRepresentable` is the adapter between the two frameworks.

- `sourceType` says whether the caller wants the camera or library.
- `onImagePicked` is a closure used to send the selected `UIImage` back to SwiftUI.
- `makeUIViewController` creates the UIKit picker, falls back to the photo library when the requested source is unavailable, and assigns its delegate.
- `updateUIViewController` is empty because no UIKit settings need to change after creation.
- `makeCoordinator` creates the delegate object that stays connected to the picker.

The nested `Coordinator` inherits from `NSObject` and implements both required picker delegate protocols. When the user finishes, it extracts `.originalImage`, calls the completion closure, and dismisses the sheet. Cancelling only dismisses it.

### `IdentificationResultView`

This view receives an immutable species and prediction, reads the three shared environment objects, and owns temporary note text plus a `didSave` flag.

It displays:

- The prediction's friendly display name.
- The field-guide species name and identification notes.
- A rounded confidence percentage, or `Model needed` for the zero-confidence fallback.
- The raw model label when it is not empty.
- A multiline notes field.
- A button for saving the result as a sighting.

The save button is disabled until a current location exists and after one save, preventing duplicate taps. `saveSighting()` unwraps the current coordinate, calls the shared `SightingsViewModel`, attaches the current weather condition text, and changes the button to **Saved**.

## 9. Field-guide screens

### `Views/Ducks/DuckViews.swift`

### `DuckListView`

`searchText` stores the search-bar input. The computed `filteredSpecies` trims spaces, lowercases the query, returns every species for an empty query, or checks whether each species' combined `searchableText` contains it.

The view displays a `List` of results. Each `NavigationLink(value:)` passes a hashable `DuckSpecies` value into the navigation stack. `.navigationDestination(for:)` explains how to turn that value into `DuckDetailView`.

### `DuckRow`

This reusable row displays an SF Symbol, the common name, and the scientific name. The frame, teal tint, rounded background, and vertical padding are visual modifiers only; they do not alter data.

### `DuckDetailView`

The detail view receives one species and creates sections for its icon, scientific name, field marks, identification notes, habitat, range, diet, conservation status, and hunting note.

`ForEach(species.fieldMarks, id: \.self)` creates one row per string. `\.self` is safe here because the strings in a species' field-mark array are expected to be unique.

## 10. Map, sighting, and weather screens

### `Views/Map/MapWeatherViews.swift`

### `SightingMapView`

The map reads the shared location manager and sightings view model. It owns:

- `position`, the map camera state.
- `selectedSighting`, which is set when a marker is selected.
- `showsAddSighting`, which controls the manual-entry sheet.

The embedded `Map` binds to both camera position and selection. It contains a `UserAnnotation` and a teal `Marker` for every sighting. `.tag(sighting)` connects a selected marker to the `selectedSighting` binding.

The map uses hybrid imagery with realistic elevation and adds user-location, compass, and scale controls.

The bottom `mapStatusBar` displays the number of sightings. If CoreLocation supplies a valid true heading, it also displays the heading as an integer number of degrees.

The toolbar's add button opens `AddSightingView`. Selecting a marker opens `SightingDetailView` as a medium-height sheet.

When the view appears, it starts location updates and tries to center the map. It also watches `currentLocation` and centers again when a location arrives. `centerOnCurrentLocation()` builds a small `MKCoordinateRegion` around the coordinate; it does nothing while location is `nil`.

### `AddSightingView`

This sheet reads the dismiss action and all three shared objects. Its local state starts with the first species ID—Mallard—and empty notes.

The form provides:

- A picker built from every `DuckData.species` entry.
- Five-decimal-place latitude and longitude when location exists.
- A request-location button when it does not.
- A multiline notes field.
- Cancel and Save toolbar actions.

Save stays disabled without a location. The private `save()` method looks up the selected species, unwraps the coordinate, adds a sighting with the current weather condition, and dismisses the sheet.

### `SightingDetailView`

This view receives one sighting and formats its species, date/time, latitude, and longitude. Notes and weather sections only appear when those optional pieces of information exist.

The same detail view is used in the marker sheet and the More tab's saved-sighting list.

### `WeatherView`

The weather tab reads shared location and weather state. It displays four `WeatherMetricRow` values plus the observation date from the cached/current snapshot. If the view model has an error, a Status section appears without deleting the previously displayed snapshot.

The toolbar refresh button starts an asynchronous refresh. Its label changes to `ProgressView` while loading.

The view's `.task` starts location updates and immediately calls refresh with the location available at that moment. If a coordinate has not arrived yet, `WeatherViewModel` reports `Location is needed for local weather`; the user can retry with the toolbar button after location becomes available.

### `WeatherMetricRow`

This small reusable view accepts a title, value, and SF Symbol name. `LabeledContent` places the icon/title on one side and formatted weather value on the other.

## 11. More screens and settings

### `Views/More/MoreViews.swift`

### `MoreView`

The More tab is a navigation menu. Its links open saved sightings, hunting reminders, resources, settings, and support screens.

### `SightingsListView`

This view reads the shared sightings view model and creates content for every sighting. `.onDelete` supplies deleted row offsets to `deleteSightings(at:)`, which updates memory and `UserDefaults`.

The current code places a complete `SightingDetailView` inside each list iteration rather than using a compact `NavigationLink` row. It still uses the detail type, but a conventional future design would normally show a summary row that navigates to the detail screen.

### `HuntingRulesView`

This is static informational UI. It reminds the user to check seasons, licences, legal hours, limits, and official regulations. It does not fetch live legal information.

### `ResourcesView`

The Learning section uses SwiftUI `Link` values to open two external websites. The other section lists the Apple technologies used by the app. The URLs are force-unwrapped with `!`; this is acceptable for fixed valid string literals, although a malformed future URL would crash at construction.

### `SettingsView`

The two `@AppStorage` properties automatically persist Boolean values in `UserDefaults`. Toggling a switch writes the new value immediately.

At present, no other code reads `usesMetricUnits` or `savesWeatherWithSightings`. The switches remember their positions, but they do not yet change weather formatting or whether weather is attached to a sighting.

### `SupportView`

This static page displays the app name/version and a short note explaining that a replacement classifier can be trained with Create ML and added to the target.

## 12. Complete user flows

### Launch flow

```text
App launches
  -> MainTabView creates shared managers/view models
  -> SightingsViewModel loads and sorts saved sightings
  -> WeatherViewModel loads cached weather or placeholder
  -> MainTabView inserts shared objects into environment
  -> locationManager.start() requests/starts location updates
```

### Identify a photo

```text
Camera or Library
  -> UIImage
  -> IdentificationViewModel.identify
  -> ImageClassificationService.classify
  -> Core ML model wrapped by Vision
  -> best VNClassificationObservation
  -> IdentificationPrediction
  -> observable prediction changes
  -> IdentificationResultView appears
```

### Save an identified sighting

```text
Save Sighting button
  -> read current coordinate from LocationManager
  -> read current condition from WeatherViewModel
  -> SightingsViewModel.addSighting
  -> insert sighting at beginning of array
  -> PersistenceService JSON-encodes array
  -> UserDefaults stores data
  -> Map and More tabs update from shared observable array
```

### Refresh weather

```text
Weather screen task or Refresh button
  -> WeatherViewModel.refresh(currentLocation)
  -> DuckWeatherService.snapshot
  -> WeatherKit request
  -> WeatherSnapshot
  -> update observable screen state
  -> JSON-encode and cache in UserDefaults
```

### Delete a sighting

```text
Swipe to delete in More > Sightings
  -> SwiftUI supplies IndexSet
  -> SightingsViewModel removes those indices
  -> remaining array is saved
  -> shared list and map update
```

## 13. Non-Swift project files

### `MachineLearning/DuckClassifier.mlmodel`

This is the source Core ML model. Xcode compiles it during the app build and copies the compiled resource into the application bundle. Runtime code looks for `DuckClassifier.mlmodelc`, not the source extension.

### `Mallard_Data/`

These Female/Male image folders are training, validation, and testing inputs for Create ML. They are development data, not runtime app data, and are not included in the app target. The running classifier does not open these JPEG files.

### `Duck ID App/Assets.xcassets`

The asset catalog stores the application icon and accent-color definition used by Xcode. Duck rows currently use SF Symbols rather than individual duck images from this catalog.

### `Duck ID App/Duck ID App.entitlements`

This property-list file enables the WeatherKit entitlement. It tells the signed application which protected Apple capability it expects to use. The matching capability must also be enabled for the App ID/development team.

### `Duck ID App.xcodeproj/project.pbxproj`

This is Xcode's project configuration. It records the target, source groups, resource membership, signing configuration, deployment target, generated Info.plist settings, and build phases. It is normally edited through Xcode rather than by hand.

Some directories are file-system-synchronized groups, so Xcode tracks files in those folders automatically. The `MachineLearning` group is synchronized into the target, allowing Xcode to compile and bundle the `.mlmodel`. `Mallard_Data` is not a target group, which keeps thousands of training images out of the installed app.

## 14. Important behavior and limitations

- The model recognizes the `Male` and `Female` classes from the Mallard dataset. It does not identify every field-guide species.
- Model labels that do not contain a known species name or ID fall back to the first `DuckData` entry, Mallard.
- A missing model also returns a zero-confidence Mallard placeholder instead of throwing an error.
- The saved photo is held in memory for the current Identify screen but is not written into `DuckSighting` or local storage.
- The weather condition attached to a sighting is whatever snapshot is currently in `WeatherViewModel`; it may be cached, unavailable, or older than the sighting.
- Settings values are stored but are not connected to service behavior yet.
- Location updates are started by several views but are never explicitly stopped.
- UserDefaults is suitable for this small text dataset but not for a large photo library.
- There is no automated test target in the project.

## 15. Where to make common changes

| Goal | Main code to change |
|---|---|
| Add a field-guide species | `DuckData.species` in `Models/Models.swift` |
| Change saved sighting fields | `DuckSighting`, `SightingsViewModel`, persistence, and relevant views |
| Support more classifier labels/species | Core ML model, `ImageClassificationService`, and `IdentificationPrediction.displayName` |
| Change image crop behavior | `request.imageCropAndScaleOption` in `ImageClassificationService` |
| Change map appearance | `SightingMapView` in `MapWeatherViews.swift` |
| Change weather values | `DuckWeatherService.snapshot` and `WeatherView` |
| Replace UserDefaults storage | `PersistenceService` |
| Make settings functional | Read the `@AppStorage` keys in weather/sighting logic |
| Add real duck artwork | Asset catalog plus `DuckSpecies`/duck views |
| Add cloud synchronization | Replace or extend `PersistenceService` |

