import Foundation
import Combine

final class AdminGameVersionFormDraft: ObservableObject {
    @Published var name: String
    @Published var slug: String
    @Published var description: String
    @Published var coverUrl: String
    @Published var selectedDlcIds: [String]
    @Published var selectedGameIds: Set<String>
    @Published var isDefault: Bool
    @Published var digitalOnly: Bool
    @Published var availableDlcs: [DLC]
    @Published var availableGames: [FamilyGame]
    @Published var isLoadingDlcs: Bool
    @Published var isLoadingGames: Bool

    init(version: GameVersion?) {
        self.name = version?.name ?? ""
        self.slug = version?.slug ?? ""
        self.description = version?.description ?? ""
        self.coverUrl = version?.coverUrl ?? ""
        self.selectedDlcIds = version?.dlcs?.map { $0.id } ?? []
        self.selectedGameIds = Set(version?.games?.map { $0.id } ?? [])
        self.isDefault = version?.isDefault ?? false
        self.digitalOnly = version?.digitalOnly ?? false
        self.availableDlcs = []
        self.availableGames = []
        self.isLoadingDlcs = false
        self.isLoadingGames = false
    }

    var isValid: Bool {
        !normalizedName.isEmpty &&
        !normalizedSlug.isEmpty &&
        !selectedGameIds.isEmpty
    }

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedSlug: String {
        slug.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedDescription: String? {
        let value = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedCoverUrl: String? {
        let value = coverUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedDlcIds: [String]? {
        selectedDlcIds.isEmpty ? nil : selectedDlcIds
    }
}
