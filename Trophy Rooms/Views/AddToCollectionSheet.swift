import SwiftUI
import Combine
import ClerkKit

struct AddToCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddToCollectionViewModel()
    @StateObject private var platformsViewModel = PlatformsViewModel.shared

    let gameId: String
    let gameTitle: String
    let existingItems: [CollectionItem]
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                // Existing collection items
                if !existingItems.isEmpty {
                    Section("In Your Collection") {
                        ForEach(existingItems) { item in
                            CollectionItemSummaryRow(item: item)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let item = existingItems[index]
                                Task {
                                    await viewModel.removeFromCollection(id: item.id)
                                    onSave()
                                }
                            }
                        }
                    }
                }

                // Add new item form
                Section("Add New Copy") {
                    // Platform
                    Picker("Platform", selection: $viewModel.platformId) {
                        Text("No Platform").tag(nil as String?)
                        ForEach(platformsViewModel.platforms) { platform in
                            Text(platform.name).tag(platform.id as String?)
                        }
                    }

                    // Region
                    Picker("Region", selection: $viewModel.region) {
                        ForEach(GameRegion.allCases, id: \.self) { region in
                            Text(region.displayName).tag(region)
                        }
                    }

                    // Condition toggles
                    Toggle("Has Disc", isOn: $viewModel.hasDisc)
                    Toggle("Has Box", isOn: $viewModel.hasBox)
                    Toggle("Has Manual", isOn: $viewModel.hasManual)
                    Toggle("Has Extras", isOn: $viewModel.hasExtras)
                    Toggle("Sealed", isOn: $viewModel.isSealed)

                    // Notes
                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.addToCollection(gameId: gameId)
                            if success {
                                onSave()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Add to Collection")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(gameTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await platformsViewModel.fetchPlatforms()
            }
        }
    }
}

private struct CollectionItemSummaryRow: View {
    let item: CollectionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.region.displayName)
                    .font(.headline)
                if item.isSealed {
                    Text("Sealed")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
                if item.isComplete {
                    Text("Complete")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }

            HStack(spacing: 8) {
                if item.hasDisc {
                    Label("Disc", systemImage: "opticaldisc")
                        .font(.caption)
                }
                if item.hasBox {
                    Label("Box", systemImage: "shippingbox")
                        .font(.caption)
                }
                if item.hasManual {
                    Label("Manual", systemImage: "book.closed")
                        .font(.caption)
                }
                if item.hasExtras {
                    Label("Extras", systemImage: "gift")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)

            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

class AddToCollectionViewModel: ObservableObject {
    @Published var region: GameRegion = .NTSC_U
    @Published var platformId: String?
    @Published var hasDisc = true
    @Published var hasBox = true
    @Published var hasManual = true
    @Published var hasExtras = false
    @Published var isSealed = false
    @Published var notes = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func addToCollection(gameId: String) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let mutation = """
        mutation AddToCollection($input: AddToCollectionInput!) {
            addToCollection(input: $input) {
                success
                collectionItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "gameId": gameId,
            "hasDisc": hasDisc,
            "hasBox": hasBox,
            "hasManual": hasManual,
            "hasExtras": hasExtras,
            "isSealed": isSealed,
            "region": region.rawValue,
            "notes": notes.isEmpty ? NSNull() : notes
        ]
        if let platformId = platformId {
            input["platformId"] = platformId
        }

        do {
            let response: AddToCollectionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return response.addToCollection.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }

    func removeFromCollection(id: String) async -> Bool {
        let mutation = """
        mutation RemoveFromCollection($id: ID!) {
            removeFromCollection(id: $id) {
                success
            }
        }
        """

        do {
            let response: RemoveFromCollectionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            return response.removeFromCollection.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}
