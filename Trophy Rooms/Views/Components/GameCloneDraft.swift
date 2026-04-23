import Foundation
import Combine

final class GameCloneDraft: ObservableObject {
    @Published var selectedPlatformIds: Set<String> = []
    @Published var copyAchievementSets: Bool = true
    @Published var isCloning: Bool = false
    @Published var cloneResults: [CloneResult] = []
    @Published var showingResults: Bool = false

    var isValid: Bool {
        !selectedPlatformIds.isEmpty
    }
}

struct CloneResult: Identifiable {
    let id = UUID()
    let platformId: String
    let platformSlug: String
    let platformName: String
    let success: Bool
    let error: String?
}
