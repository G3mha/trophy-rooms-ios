import SwiftUI

// MARK: - Log Play Sheet

/// Quick session logger: pick a game from the likelihood-sorted carousel,
/// tap a duration chip, log. Date defaults to today with a one-tap
/// "Yesterday" and a calendar fallback.
struct LogPlaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let preselectedGame: PlaySessionGame?
    var onLogged: (() -> Void)?

    @StateObject private var journalViewModel = PlayJournalViewModel()
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var selectedGame: PlaySessionGame?
    @State private var minutes = 60
    @State private var dayChoice: DayChoice = .today
    @State private var customDate = Date()
    @State private var notes = ""
    @State private var searchText = ""
    @State private var isSaving = false

    enum DayChoice: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case other = "Other"
    }

    private var playedOnDate: Date {
        switch dayChoice {
        case .today: return Date()
        case .yesterday: return Date().addingTimeInterval(-86400)
        case .other: return customDate
        }
    }

    /// Library games ordered by how likely they are to be logged:
    /// currently playing first, then recently logged, then the rest.
    private var candidates: [PlaySessionGame] {
        let recentGameIds = journalViewModel.sessions.prefix(30).map { $0.gameId }

        func rank(_ item: LibraryItem) -> (Int, Int) {
            if item.status == .PLAYING { return (0, 0) }
            if let index = recentGameIds.firstIndex(of: item.gameId) { return (1, index) }
            return (2, 0)
        }

        var items = libraryViewModel.libraryItems
        if !searchText.isEmpty {
            items = items.filter { $0.gameTitle.localizedCaseInsensitiveContains(searchText) }
        }

        return items
            .sorted { lhs, rhs in
                let l = rank(lhs)
                let r = rank(rhs)
                if l.0 != r.0 { return l.0 < r.0 }
                if l.1 != r.1 { return l.1 < r.1 }
                return lhs.gameTitle.localizedCaseInsensitiveCompare(rhs.gameTitle) == .orderedAscending
            }
            .map { item in
                PlaySessionGame(
                    id: item.gameId,
                    title: item.gameTitle,
                    coverUrl: item.gameCoverUrl,
                    platform: item.platformId.map {
                        Platform(id: $0, name: item.platformName ?? "", slug: item.platformSlug)
                    }
                )
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let game = preselectedGame ?? selectedGame, preselectedGame != nil {
                        // Fixed game (opened from a game's detail page)
                        HStack(spacing: 12) {
                            CachedImageFixed(url: game.coverUrl, width: 48, height: 64, cornerRadius: 6)
                            Text(game.title)
                                .font(.headline)
                            Spacer()
                        }
                    } else {
                        gamePicker
                    }

                    DurationPicker(minutes: $minutes)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("When")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Picker("When", selection: $dayChoice) {
                            ForEach(DayChoice.allCases, id: \.self) { choice in
                                Text(choice.rawValue).tag(choice)
                            }
                        }
                        .pickerStyle(.segmented)

                        if dayChoice == .other {
                            DatePicker(
                                "Date",
                                selection: $customDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        TextField("Beat the water temple... (optional)", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(10)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    if let error = journalViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Log \(formatPlayMinutes(minutes))")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                    .disabled(isSaving || (preselectedGame ?? selectedGame) == nil || minutes < 1)
                }
                .padding()
            }
            .navigationTitle("Log Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .task {
            if preselectedGame == nil {
                await libraryViewModel.fetchLibrary()
                await journalViewModel.fetch()
                if selectedGame == nil {
                    selectedGame = candidates.first
                }
            }
        }
    }

    private var gamePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Game")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            TextField("Search your library", text: $searchText)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .autocorrectionDisabled()

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(candidates) { game in
                        Button {
                            withAnimation(.snappy) {
                                selectedGame = game
                            }
                        } label: {
                            VStack(spacing: 5) {
                                CachedImageFixed(url: game.coverUrl, width: 64, height: 86, cornerRadius: 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selectedGame?.id == game.id ? Color.accentColor : .clear,
                                                lineWidth: 3
                                            )
                                    )
                                Text(game.title)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .foregroundStyle(selectedGame?.id == game.id ? Color.accentColor : .secondary)
                            }
                            .frame(width: 72)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(height: 116)
        }
    }

    private func save() {
        guard let game = preselectedGame ?? selectedGame else { return }
        isSaving = true
        Task {
            let success = await journalViewModel.log(
                gameId: game.id,
                playedOn: playedOnDate,
                minutes: minutes,
                notes: notes
            )
            isSaving = false
            if success {
                onLogged?()
                dismiss()
            }
        }
    }
}

// MARK: - Duration Picker

/// Chip-based duration input with a ±15 minute stepper — no keyboard needed.
struct DurationPicker: View {
    @Binding var minutes: Int

    private let presets = [15, 30, 45, 60, 90, 120, 180]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How Long")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack {
                Button {
                    minutes = max(15, minutes - 15)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(formatPlayMinutes(minutes))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: minutes)

                Spacer()

                Button {
                    minutes = min(1440, minutes + 15)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            withAnimation(.snappy) {
                                minutes = preset
                            }
                        } label: {
                            Text(formatPlayMinutes(preset))
                                .font(.subheadline.weight(minutes == preset ? .semibold : .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .foregroundStyle(minutes == preset ? Color.white : .primary)
                                .background(
                                    minutes == preset
                                        ? AnyShapeStyle(Color.accentColor)
                                        : AnyShapeStyle(.fill.secondary),
                                    in: .capsule
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Edit Play Session Sheet

struct EditPlaySessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let session: PlaySession
    @ObservedObject var viewModel: PlayJournalViewModel

    @State private var minutes: Int
    @State private var date: Date
    @State private var notes: String
    @State private var isSaving = false

    init(session: PlaySession, viewModel: PlayJournalViewModel) {
        self.session = session
        self.viewModel = viewModel
        _minutes = State(initialValue: session.minutes)
        _notes = State(initialValue: session.notes ?? "")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        _date = State(initialValue: formatter.date(from: session.dayKey) ?? Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        CachedImageFixed(url: session.game.coverUrl, width: 48, height: 64, cornerRadius: 6)
                        Text(session.game.title)
                            .font(.headline)
                        Spacer()
                    }

                    DurationPicker(minutes: $minutes)

                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button {
                        isSaving = true
                        Task {
                            if await viewModel.update(id: session.id, playedOn: date, minutes: minutes, notes: notes) {
                                dismiss()
                            }
                            isSaving = false
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Changes").fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                    .disabled(isSaving)
                }
                .padding()
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
