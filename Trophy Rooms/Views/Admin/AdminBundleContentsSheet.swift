import SwiftUI

struct AdminBundleContentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminBundlesViewModel
    let bundle: AppBundle

    @State private var isLoadingGames = false
    @State private var isLoadingDLCs = false
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
                    viewModel: viewModel,
                    bundleId: bundle.id,
                    excludedGameIds: Set(bundle.games?.map(\.id) ?? [])
                )
            }
            .sheet(isPresented: $showDLCPicker) {
                DLCPickerSheet(
                    viewModel: viewModel,
                    bundleId: bundle.id,
                    excludedDLCIds: Set(bundle.dlcs?.map(\.id) ?? [])
                )
            }
            .task {
                await viewModel.fetchAvailableGames()
                await viewModel.fetchAvailableDLCs()
            }
        }
    }
}

// MARK: - Game Picker Sheet

private struct GamePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminBundlesViewModel
    let bundleId: String
    let excludedGameIds: Set<String>

    @State private var searchText = ""

    var filteredGames: [GameSummary] {
        let available = viewModel.availableGames.filter { !excludedGameIds.contains($0.id) }
        if searchText.isEmpty {
            return available
        }
        return available.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGames) { game in
                    Button {
                        Task {
                            let success = await viewModel.addGameToBundle(
                                gameId: game.id,
                                bundleId: bundleId
                            )
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if let coverUrl = game.coverUrl, let url = URL(string: coverUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 40, height: 40)
                                .cornerRadius(6)
                            }

                            VStack(alignment: .leading) {
                                Text(game.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                if let platform = game.platform {
                                    Text(platform.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search games")
            .navigationTitle("Add Game")
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

// MARK: - DLC Picker Sheet

private struct DLCPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminBundlesViewModel
    let bundleId: String
    let excludedDLCIds: Set<String>

    @State private var searchText = ""

    var filteredDLCs: [DLC] {
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
                        HStack {
                            if let coverUrl = dlc.coverUrl, let url = URL(string: coverUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 40, height: 40)
                                .cornerRadius(6)
                            }

                            VStack(alignment: .leading) {
                                Text(dlc.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                if let game = dlc.game {
                                    Text(game.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            DLCTypeBadge(type: dlc.type)
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
