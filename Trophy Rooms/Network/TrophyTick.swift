import Foundation

// Ticks or unticks a trophy for the signed-in player. Returns the server's
// reason when it refuses the tick without throwing; throws on a network failure.
enum TrophyTick {
    static func send(achievementId: String, earned: Bool) async throws -> String? {
        let name = earned ? "MarkAchievementComplete" : "UnmarkAchievementComplete"
        let field = earned ? "markAchievementComplete" : "unmarkAchievementComplete"
        let mutation = """
        mutation \(name)($achievementId: ID!) {
            \(field)(achievementId: $achievementId) {
                success
                error { code message field }
            }
        }
        """

        let response: SimpleMutationResponse = try await NetworkService.shared.fetch(
            query: mutation,
            variables: ["achievementId": achievementId]
        )
        let result = earned ? response.markAchievementComplete : response.unmarkAchievementComplete
        return result?.success == false ? (result?.error?.message ?? "Try again.") : nil
    }
}
