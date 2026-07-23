import SwiftUI
import Combine

struct MarkAsSoldSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MarkAsSoldSheetViewModel()

    let item: SellListItem
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Sale Price (required)
                    HStack {
                        Text("Sale Price")
                        Spacer()
                        TextField("0.00", value: $viewModel.salePrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    // Sale Date
                    DatePicker(
                        "Sale Date",
                        selection: $viewModel.soldAt,
                        displayedComponents: [.date]
                    )
                }

                Section {
                    // Mark as Sold (keep in collection)
                    Button {
                        Task {
                            let success = await viewModel.markAsSold(id: item.id, removeFromCollection: false)
                            if success {
                                Haptics.success()
                                onComplete()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading && !viewModel.isRemovingFromCollection {
                                ProgressView()
                            } else {
                                VStack(spacing: 4) {
                                    Text("Mark as Sold")
                                        .fontWeight(.semibold)
                                    Text("Keep in collection")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.salePrice == nil || viewModel.salePrice == 0)
                }

                Section {
                    // Mark as Sold AND Remove from Collection
                    Button(role: .destructive) {
                        Task {
                            let success = await viewModel.markAsSold(id: item.id, removeFromCollection: true)
                            if success {
                                Haptics.success()
                                onComplete()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading && viewModel.isRemovingFromCollection {
                                ProgressView()
                            } else {
                                VStack(spacing: 4) {
                                    Text("Mark as Sold & Remove")
                                        .fontWeight(.semibold)
                                    Text("Remove from collection")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.salePrice == nil || viewModel.salePrice == 0)
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
                // Pre-fill with asking price if available
                if let askingPrice = item.askingPrice {
                    viewModel.salePrice = askingPrice
                }
            }
        }
    }
}

class MarkAsSoldSheetViewModel: ObservableObject {
    @Published var salePrice: Double?
    @Published var soldAt: Date = Date()
    @Published var isLoading = false
    @Published var isRemovingFromCollection = false
    @Published var errorMessage: String?

    func markAsSold(id: String, removeFromCollection: Bool) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.isRemovingFromCollection = removeFromCollection
            self.errorMessage = nil
        }

        guard let salePrice = salePrice, salePrice > 0 else {
            DispatchQueue.main.async {
                self.errorMessage = "Sale price is required"
                self.isLoading = false
            }
            return false
        }

        let mutationName = removeFromCollection ? "markAsSoldAndRemoveFromCollection" : "markAsSold"
        let mutation = """
        mutation MarkAsSold($id: ID!, $input: MarkAsSoldInput!) {
            \(mutationName)(id: $id, input: $input) {
                success
            }
        }
        """

        // Format date for GraphQL DateTime
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let input: [String: Any] = [
            "salePrice": salePrice,
            "soldAt": formatter.string(from: soldAt)
        ]

        do {
            if removeFromCollection {
                let response: MarkAsSoldAndRemoveFromCollectionResponse = try await NetworkService.shared.fetch(
                    query: mutation,
                    variables: ["id": id, "input": input]
                )
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return response.markAsSoldAndRemoveFromCollection.success
            } else {
                let response: MarkAsSoldResponse = try await NetworkService.shared.fetch(
                    query: mutation,
                    variables: ["id": id, "input": input]
                )
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return response.markAsSold.success
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
}
