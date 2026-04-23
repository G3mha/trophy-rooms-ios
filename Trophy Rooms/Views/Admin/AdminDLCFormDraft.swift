import Foundation
import Combine

final class AdminDLCFormDraft: ObservableObject {
    @Published var name: String
    @Published var slug: String
    @Published var type: DLCType
    @Published var dlcDescription: String
    @Published var coverUrl: String
    @Published var priceString: String
    @Published var selectedPlatformIds: Set<String>

    init(dlc: DLC?) {
        self.name = dlc?.name ?? ""
        self.slug = dlc?.slug ?? ""
        self.type = dlc?.type ?? .DLC
        self.dlcDescription = dlc?.description ?? ""
        self.coverUrl = dlc?.coverUrl ?? ""
        if let price = dlc?.price {
            self.priceString = String(format: "%.2f", price)
        } else {
            self.priceString = ""
        }
        self.selectedPlatformIds = Set(dlc?.platforms?.map { $0.id } ?? [])
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
        let value = dlcDescription.trimmingCharacters(in: .whitespacesAndNewlines)
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
