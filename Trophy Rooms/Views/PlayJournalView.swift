import SwiftUI

/// Daily play journal: day-grouped log of play sessions with streak and
/// weekly totals. Entry point for logging new sessions.
struct PlayJournalView: View {
    @StateObject private var viewModel = PlayJournalViewModel()
    @State private var showLogSheet = false
    @State private var editingSession: PlaySession?

    var body: some View {
        Group {
            if viewModel.isLoading && !viewModel.hasLoadedOnce {
                CabinetLoadingView("Loading journal...")
            } else if viewModel.sessions.isEmpty {
                ContentUnavailableView {
                    Label("No Play Sessions", systemImage: "gamecontroller")
                } description: {
                    Text("Log what you played and for how long — your gaming diary starts here.")
                } actions: {
                    Button("Log a Session") {
                        showLogSheet = true
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                }
            } else {
                journalList
            }
        }
        .cabinetCanvas()
        .navigationTitle("Play Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showLogSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Log a play session")
            }
        }
        .sheet(isPresented: $showLogSheet) {
            LogPlaySheet(preselectedGame: nil) {
                Task { await viewModel.fetch() }
            }
        }
        .sheet(item: $editingSession) { session in
            EditPlaySessionSheet(session: session, viewModel: viewModel)
        }
        .task {
            await viewModel.fetch()
        }
    }

    private var journalList: some View {
        List {
            if let stats = viewModel.stats {
                Section {
                    PlayStatsHeader(stats: stats)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }

            ForEach(viewModel.dayGroups) { group in
                Section {
                    ForEach(group.sessions) { session in
                        PlaySessionRow(session: session)
                            .listRowBackground(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingSession = session
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(id: session.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    editingSession = session
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text(group.label)
                        Spacer()
                        Text(formatPlayMinutes(group.totalMinutes))
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote.weight(.semibold))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, 40, for: .scrollContent)
        .refreshable {
            await viewModel.fetch()
        }
    }
}

private struct PlayStatsHeader: View {
    let stats: PlayStats

    var body: some View {
        HStack(spacing: 8) {
            statTile(
                value: "\(stats.currentStreakDays)",
                unit: stats.currentStreakDays == 1 ? "day" : "days",
                label: "Streak",
                icon: "flame.fill",
                tint: .orange
            )
            statTile(
                value: formatPlayMinutes(stats.thisWeekMinutes),
                unit: nil,
                label: "This Week",
                icon: "calendar",
                tint: .accentColor
            )
            statTile(
                value: formatPlayMinutes(stats.totalMinutes),
                unit: nil,
                label: "All Time",
                icon: "clock.fill",
                tint: .blue
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func statTile(value: String, unit: String?, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline)
                if let unit {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Cabinet.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct PlaySessionRow: View {
    let session: PlaySession

    var body: some View {
        HStack(spacing: 12) {
            CachedImageFixed(
                url: session.game.coverUrl,
                width: 40,
                height: 54,
                cornerRadius: 6
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(session.game.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    if let slug = session.game.platform?.slug {
                        PlatformIcon(slug: slug, size: 13)
                    }
                    if let notes = session.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Text(formatPlayMinutes(session.minutes))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        PlayJournalView()
    }
}
