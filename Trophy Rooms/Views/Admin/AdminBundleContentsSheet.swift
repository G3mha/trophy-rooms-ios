import SwiftUI

struct AdminBundleContentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminBundlesViewModel
    let bundle: AppBundle

    @State private var showGamePicker = false
    @State private var showDLCPicker = false

    var body: some View {
        NavigationStack {
            List {
                // Games Section
                Section {
                    if let games = bundle.games, !games.isEmpty {
                        ForEach(games, id: \.id) { game in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(game.title)
                                        .font(.headline)
                                }
                                Spacer()
                                Button {
                                    Task {
                                        await viewModel.removeGameFromBundle(
                                            gameId: game.id,
                                            bundleId: bundle.id
                                        )
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    } else {
                        Text("No games in this bundle")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showGamePicker = true
                    } label: {
                        Label("Add Game", systemImage: "plus.circle")
                    }
                } header: {
                    HStack {
                        Text("Games")
                        Spacer()
                        Text("\(bundle.games?.count ?? 0)")
                            .foregroundStyle(.secondary)
                    }
                }

                // DLCs Section
                Section {
                    if let dlcs = bundle.dlcs, !dlcs.isEmpty {
                        ForEach(dlcs, id: \.id) { dlc in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(dlc.name)
                                        .font(.headline)
                                    if let game = dlc.game {
                                        Text(game.title)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button {
                                    Task {
                                        await viewModel.removeDLCFromBundle(
                                            dlcId: dlc.id,
                                            bundleId: bundle.id
                                        )
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    } else {
                        Text("No DLCs in this bundle")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showDLCPicker = true
                    } label: {
                        Label("Add DLC", systemImage: "plus.circle")
                    }
                } header: {
                    HStack {
                        Text("DLCs")
                        Spacer()
                        Text("\(bundle.dlcs?.count ?? 0)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Bundle Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showGamePicker) {
                GamePickerSheet(
                    title: "Add Game to Bundle",
                    excludedGameIds: Set(bundle.games?.map(\.id) ?? [])
                ) { selectedGame in
                    Task {
                        await viewModel.addGameToBundle(
                            gameId: selectedGame.id,
                            bundleId: bundle.id
                        )
                    }
                }
            }
            .sheet(isPresented: $showDLCPicker) {
                DLCPickerSheet(
                    viewModel: viewModel,
                    bundleId: bundle.id,
                    excludedDLCIds: Set(bundle.dlcs?.map(\.id) ?? [])
                )
            }
            .task {
                await viewModel.fetchAvailableDLCs()
            }
        }
    }
}

// MARK: - DLC Picker Sheet

private struct DLCPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminBundlesViewModel
    let bundleId: String
    let excludedDLCIds: Set<String>

    @State private var searchText = ""

    var filteredDLCs: [DLCPickerItem] {
        let available = viewModel.availableDLCs.filter { !excludedDLCIds.contains($0.id) }
        if searchText.isEmpty {
            return available
        }
        return available.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.game?.title.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredDLCs.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if filteredDLCs.isEmpty {
                    ContentUnavailableView {
                        Label("No DLCs", systemImage: "puzzlepiece.extension")
                    } description: {
                        Text("No DLCs available to add")
                    }
                } else {
                    ForEach(filteredDLCs, id: \.id) { dlc in
                        Button {
                            Task {
                                let success = await viewModel.addDLCToBundle(
                                    dlcId: dlc.id,
                                    bundleId: bundleId
                                )
                                if success {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                if let coverUrl = dlc.coverUrl, let url = URL(string: coverUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
                                    }
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            Image(systemName: "puzzlepiece.extension")
                                                .foregroundStyle(.gray)
                                        }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dlc.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let game = dlc.game {
                                        Text(game.title)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                DLCTypeBadge(type: dlc.type)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search DLCs")
            .navigationTitle("Add DLC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
