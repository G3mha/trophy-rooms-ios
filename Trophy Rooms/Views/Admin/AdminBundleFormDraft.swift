import Foundation
import Combine

final class AdminBundleFormDraft: ObservableObject {
    @Published var name: String
    @Published var slug: String
    @Published var type: BundleType
    @Published var selectedPlatformIds: Set<String>
    @Published var bundleDescription: String
    @Published var coverUrl: String
    @Published var priceString: String

    init(bundle: AppBundle?) {
        self.name = bundle?.name ?? ""
        self.slug = bundle?.slug ?? ""
        self.type = bundle?.type ?? .BUNDLE
        self.selectedPlatformIds = bundle?.platformId.map { [$0] } ?? []
        self.bundleDescription = bundle?.description ?? ""
        self.coverUrl = bundle?.coverUrl ?? ""
        if let price = bundle?.price {
            self.priceString = String(format: "%.2f", price)
        } else {
            self.priceString = ""
        }
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
        let value = bundleDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedCoverUrl: String? {
        let value = coverUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedPrice: Double? {
        Double(priceString)
    }
}
