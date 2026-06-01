import SwiftUI
import Combine

struct MarkAsPurchasedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MarkAsPurchasedSheetViewModel()

    let item: BuylistItem
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Purchase Price
                    HStack {
                        Text("Purchase Price")
                        Spacer()
                        TextField("0.00", value: $viewModel.purchasePrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    // Purchase Date
                    DatePicker(
                        "Purchase Date",
                        selection: $viewModel.purchasedAt,
                        displayedComponents: [.date]
                    )
                }

                // Platform selector (only for games)
                if item.itemType == .GAME {
                    Section {
                        PlatformSelectionField(
                            platforms: viewModel.platforms,
                            selectedPlatformIds: $viewModel.selectedPlatformIds,
                            allowsMultipleSelection: false,
                            isDisabled: false
                        )
                    } header: {
                        Text("Platform")
                    } footer: {
                        Text("Optional - select a platform for this game")
                    }

                    Section {
                        Picker("Region", selection: $viewModel.region) {
                            ForEach(GameRegion.allCases, id: \.self) { region in
                                Text(region.displayName).tag(region)
                            }
                        }

                        Toggle("Digital Copy", isOn: $viewModel.isDigital)
                    }

                    if !viewModel.isDigital {
                        Section("Physical Condition") {
                            Toggle("Has Disc", isOn: $viewModel.hasDisc)
                            Toggle("Has Box", isOn: $viewModel.hasBox)
                            Toggle("Has Manual", isOn: $viewModel.hasManual)
                            Toggle("Has Extras", isOn: $viewModel.hasExtras)
                            Toggle("Sealed", isOn: $viewModel.isSealed)
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.markAsPurchased(id: item.id, isGame: item.itemType == .GAME)
                            if success {
                                onComplete()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Mark as Purchased")
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
            .navigationTitle(item.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-fill with estimated price if available
                if let estimatedPrice = item.estimatedPrice {
                    viewModel.purchasePrice = estimatedPrice
                }
                Task {
                    await viewModel.fetchPlatforms()
                }
            }
        }
    }
}

class MarkAsPurchasedSheetViewModel: ObservableObject {
    @Published var purchasePrice: Double?
    @Published var purchasedAt: Date = Date()
    @Published var selectedPlatformIds: Set<String> = []
    @Published var platforms: [Platform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Collection fields
    @Published var region: GameRegion = .NTSC_U
    @Published var isDigital: Bool = false
    @Published var hasDisc: Bool = true
    @Published var hasBox: Bool = true
    @Published var hasManual: Bool = true
    @Published var hasExtras: Bool = false
    @Published var isSealed: Bool = false

    func fetchPlatforms() async {
        let query = """
        query GetPlatforms {
            platforms {
                id
                name
                slug
            }
        }
        """

        do {
            let response: PlatformsResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.platforms = response.platforms
            }
        } catch {
            // Silently fail - platforms are optional
        }
    }

    func markAsPurchased(id: String, isGame: Bool) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let mutation = """
        mutation MarkAsPurchased($id: ID!, $platformId: ID, $purchasePrice: Float, $purchasedAt: DateTime, $region: GameRegion, $isDigital: Boolean, $hasDisc: Boolean, $hasBox: Boolean, $hasManual: Boolean, $hasExtras: Boolean, $isSealed: Boolean) {
            markAsPurchased(id: $id, platformId: $platformId, purchasePrice: $purchasePrice, purchasedAt: $purchasedAt, region: $region, isDigital: $isDigital, hasDisc: $hasDisc, hasBox: $hasBox, hasManual: $hasManual, hasExtras: $hasExtras, isSealed: $isSealed) {
                success
            }
        }
        """

        var variables: [String: Any] = ["id": id]
        if let platformId = selectedPlatformIds.first {
            variables["platformId"] = platformId
        }
        if let purchasePrice = purchasePrice, purchasePrice > 0 {
            variables["purchasePrice"] = purchasePrice
        }

        // Format date for GraphQL DateTime
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        variables["purchasedAt"] = formatter.string(from: purchasedAt)

        // Add collection fields for games
        if isGame {
            variables["region"] = region.rawValue
            variables["isDigital"] = isDigital
            if !isDigital {
                variables["hasDisc"] = hasDisc
                variables["hasBox"] = hasBox
                variables["hasManual"] = hasManual
                variables["hasExtras"] = hasExtras
                variables["isSealed"] = isSealed
            }
        }

        do {
            let response: MarkAsPurchasedResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return response.markAsPurchased.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
}
