import Foundation

// This model represents the duck species shown in the Ducks tab.
struct DuckSpecies: Identifiable, Hashable {
    let id = UUID()
    let commonName: String
    let scientificName: String
    let description: String
    let imageName: String
}

extension DuckSpecies {
    static let sampleSpecies: [DuckSpecies] = [
        DuckSpecies(commonName: "Mallard", scientificName: "Anas platyrhynchos", description: "Common pond duck with a glossy green head.", imageName: "mallard"),
        DuckSpecies(commonName: "Black Duck", scientificName: "Anas rubripes", description: "A darker, sturdy dabbling duck often found in marshes.", imageName: "black_duck"),
        DuckSpecies(commonName: "Common Goldeneye", scientificName: "Bucephala clangula", description: "A striking diving duck with bright eyes and a rounded head.", imageName: "goldeneye")
    ]
}
