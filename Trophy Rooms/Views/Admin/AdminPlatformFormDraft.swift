import Foundation
import Combine

final class AdminPlatformFormDraft: ObservableObject {
    @Published var name: String
    @Published var slug: String
    @Published var platformDescription: String
    @Published var consolePictureUrl: String
    @Published var promotionalPictures: [String]
    @Published var releases: [PlatformRelease]

    init(platform: AdminPlatform?) {
        self.name = platform?.name ?? ""
        self.slug = platform?.slug ?? ""
        self.platformDescription = platform?.description ?? ""
        self.consolePictureUrl = platform?.consolePictureUrl ?? ""
        self.promotionalPictures = platform?.promotionalPictures ?? []
        self.releases = platform?.releases ?? []
    }

    var isValid: Bool {
        !normalizedName.isEmpty && !normalizedSlug.isEmpty
    }

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedSlug: String {
        slug.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedDescription: String? {
        let value = platformDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedConsolePictureUrl: String? {
        let value = consolePictureUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedPromotionalPictures: [String]? {
        let values = promotionalPictures
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return values.isEmpty ? nil : values
    }
}
