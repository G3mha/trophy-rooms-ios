import Foundation
import Combine

final class PlatformReleaseFormDraft: ObservableObject {
    @Published var region: String
    @Published var releaseDate: Date

    init(release: PlatformRelease?) {
        self.region = release?.region ?? "NA"

        if let release {
            let formatter = ISO8601DateFormatter()
            self.releaseDate = formatter.date(from: release.releaseDate) ?? Date()
        } else {
            self.releaseDate = Date()
        }
    }
}
