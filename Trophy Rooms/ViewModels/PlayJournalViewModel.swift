import Foundation
import Combine

@MainActor
class PlayJournalViewModel: ObservableObject {
    @Published var sessions: [PlaySession] = []
    @Published var stats: PlayStats?
    @Published var isLoading = false
    @Published var hasLoadedOnce = false
    @Published var errorMessage: String?

    struct DayGroup: Identifiable {
        let dayKey: String
        let label: String
        let totalMinutes: Int
        let sessions: [PlaySession]

        var id: String { dayKey }
    }

    /// Sessions grouped by calendar day, newest day first
    var dayGroups: [DayGroup] {
        var order: [String] = []
        var grouped: [String: [PlaySession]] = [:]
        for session in sessions {
            if grouped[session.dayKey] == nil {
                order.append(session.dayKey)
            }
            grouped[session.dayKey, default: []].append(session)
        }
        return order.map { key in
            let daySessions = grouped[key] ?? []
            return DayGroup(
                dayKey: key,
                label: Self.dayLabel(for: key),
                totalMinutes: daySessions.reduce(0) { $0 + $1.minutes },
                sessions: daySessions
            )
        }
    }

    func fetch() async {
        if sessions.isEmpty && !hasLoadedOnce {
            isLoading = true
        }
        errorMessage = nil

        let query = """
        query GetPlayJournal {
            myPlaySessions {
                id
                gameId
                game { id title coverUrl platform { id name slug } }
                playedOn
                minutes
                notes
            }
            myPlayStats {
                totalMinutes
                sessionCount
                daysLogged
                currentStreakDays
                thisWeekMinutes
            }
        }
        """

        do {
            let response: PlayJournalResponse = try await NetworkService.shared.fetch(query: query)
            sessions = response.myPlaySessions
            stats = response.myPlayStats
        } catch is CancellationError {
        } catch {
            if sessions.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
        hasLoadedOnce = true
    }

    func log(gameId: String, playedOn: Date, minutes: Int, notes: String?) async -> Bool {
        let mutation = """
        mutation LogPlaySession($input: LogPlaySessionInput!) {
            logPlaySession(input: $input) {
                success
            }
        }
        """

        var input: [String: Any] = [
            "gameId": gameId,
            "playedOn": Self.graphQLDay(from: playedOn),
            "minutes": minutes
        ]
        if let notes, !notes.isEmpty {
            input["notes"] = notes
        }

        do {
            let response: LogPlaySessionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            if response.logPlaySession.success {
                // Logging bumps the game's library status to Playing
                await CacheInvalidation.forLibraryChange()
                await fetch()
                return true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }

    func update(id: String, playedOn: Date, minutes: Int, notes: String?) async -> Bool {
        let mutation = """
        mutation UpdatePlaySession($id: ID!, $input: UpdatePlaySessionInput!) {
            updatePlaySession(id: $id, input: $input) {
                success
            }
        }
        """

        let input: [String: Any] = [
            "playedOn": Self.graphQLDay(from: playedOn),
            "minutes": minutes,
            "notes": (notes?.isEmpty ?? true) ? NSNull() : notes!
        ]

        do {
            let response: UpdatePlaySessionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id, "input": input]
            )
            if response.updatePlaySession.success {
                await fetch()
                return true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }

    func delete(id: String) async {
        let mutation = """
        mutation DeletePlaySession($id: ID!) {
            deletePlaySession(id: $id) {
                success
            }
        }
        """

        do {
            let response: DeletePlaySessionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.deletePlaySession.success {
                sessions.removeAll { $0.id == id }
                await fetch()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Date helpers

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let dayDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    /// The user's chosen calendar day encoded as a UTC-midnight DateTime,
    /// matching how the backend stores the date-only column.
    static func graphQLDay(from date: Date) -> String {
        dayKeyFormatter.string(from: date) + "T00:00:00.000Z"
    }

    static func dayLabel(for dayKey: String) -> String {
        let today = dayKeyFormatter.string(from: Date())
        let yesterday = dayKeyFormatter.string(from: Date().addingTimeInterval(-86400))
        if dayKey == today { return "Today" }
        if dayKey == yesterday { return "Yesterday" }
        guard let date = dayKeyFormatter.date(from: dayKey) else { return dayKey }
        return dayDisplayFormatter.string(from: date)
    }
}
