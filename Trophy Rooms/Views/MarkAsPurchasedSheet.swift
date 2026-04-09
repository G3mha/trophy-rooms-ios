import SwiftUI

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
                        Picker("Platform", selection: $viewModel.selectedPlatformId) {
                            Text("No Platform").tag(nil as String?)
                            ForEach(viewModel.platforms, id: \.id) { platform in
                                Text(platform.name).tag(platform.id as String?)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.markAsPurchased(id: item.id)
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
    @Published var selectedPlatformId: String?
    @Published var platforms: [Platform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

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

    func markAsPurchased(id: String) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let mutation = """
        mutation MarkAsPurchased($id: ID!, $platformId: ID, $purchasePrice: Float, $purchasedAt: DateTime) {
            markAsPurchased(id: $id, platformId: $platformId, purchasePrice: $purchasePrice, purchasedAt: $purchasedAt) {
                success
            }
        }
        """

        var variables: [String: Any] = ["id": id]
        if let platformId = selectedPlatformId {
            variables["platformId"] = platformId
        }
        if let purchasePrice = purchasePrice, purchasePrice > 0 {
            variables["purchasePrice"] = purchasePrice
        }

        // Format date for GraphQL DateTime
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        variables["purchasedAt"] = formatter.string(from: purchasedAt)

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
