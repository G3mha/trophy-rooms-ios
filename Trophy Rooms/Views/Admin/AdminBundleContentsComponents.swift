import SwiftUI

struct AdminBundleGamesSection: View {
    @ObservedObject var viewModel: AdminBundlesViewModel
    let bundleId: String
    let bundle: AppBundle
    let onAddGame: () -> Void

    var body: some View {
        Section {
            if let games = bundle.gameFamilies, !games.isEmpty {
                ForEach(games, id: \.id) { game in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(game.title)
                                .font(.headline)
                        }
                        Spacer()
                        Button {
                            Task {
                                await viewModel.removeGameFamilyFromBundle(
                                    gameFamilyId: game.id,
                                    bundleId: bundleId
                                )
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            } else {
                Text("No games in this bundle")
                    .foregroundStyle(.secondary)
            }

            Button(action: onAddGame) {
                Label("Add Game", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("Games")
                Spacer()
                Text("\(bundle.gameFamilies?.count ?? 0)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AdminBundleDLCsSection: View {
    @ObservedObject var viewModel: AdminBundlesViewModel
    let bundleId: String
    let bundle: AppBundle
    let onAddDLC: () -> Void

    var body: some View {
        Section {
            if let dlcs = bundle.dlcs, !dlcs.isEmpty {
                ForEach(dlcs, id: \.id) { dlc in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(dlc.name)
                                .font(.headline)
                            if let game = dlc.gameFamily {
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
                                    bundleId: bundleId
                                )
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            } else {
                Text("No DLCs in this bundle")
                    .foregroundStyle(.secondary)
            }

            Button(action: onAddDLC) {
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
}

struct BundleDLCPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminBundlesViewModel
    let bundleId: String
    let excludedDLCIds: Set<String>

    @State private var searchText = ""

    private var filteredDLCs: [DLCPickerItem] {
        let available = viewModel.availableDLCs.filter { !excludedDLCIds.contains($0.id) }
        if searchText.isEmpty {
            return available
        }
        return available.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.gameFamily?.title.localizedCaseInsensitiveContains(searchText) ?? false)
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
                                    if let game = dlc.gameFamily {
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
