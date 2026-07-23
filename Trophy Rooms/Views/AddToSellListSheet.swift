import SwiftUI
import Combine

struct AddToSellListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddToSellListSheetViewModel()

    let collectionItemId: String
    let itemTitle: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Condition
                    Picker("Condition", selection: $viewModel.condition) {
                        ForEach(ItemCondition.allCases, id: \.self) { condition in
                            HStack {
                                Text(condition.shortName)
                                    .fontWeight(.bold)
                                    .foregroundColor(conditionColor(for: condition))
                                Text(condition.displayName)
                            }
                            .tag(condition)
                        }
                    }

                    // Asking Price
                    HStack {
                        Text("Asking Price")
                        Spacer()
                        TextField("0.00", value: $viewModel.askingPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    // Condition Notes
                    TextField("Condition Notes (optional)", text: $viewModel.conditionNotes, axis: .vertical)
                        .lineLimit(2...4)

                    // Listing URL
                    TextField("Listing URL (optional)", text: $viewModel.listingUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    // Notes
                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.addToSellList(collectionItemId: collectionItemId)
                            if success {
                                Haptics.success()
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
                                Text("Add to Sell List")
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
            .navigationTitle(itemTitle)
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

    func conditionColor(for condition: ItemCondition) -> Color {
        switch condition {
        case .MINT: return .green
        case .NEAR_MINT: return .teal
        case .VERY_GOOD: return .blue
        case .GOOD: return .orange
        case .FAIR: return .red
        case .POOR: return .gray
        }
    }
}

class AddToSellListSheetViewModel: ObservableObject {
    @Published var condition: ItemCondition = .GOOD
    @Published var askingPrice: Double?
    @Published var conditionNotes = ""
    @Published var listingUrl = ""
    @Published var notes = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func addToSellList(collectionItemId: String) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let mutation = """
        mutation AddToSellList($input: AddToSellListInput!) {
            addToSellList(input: $input) {
                success
                sellListItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "collectionItemId": collectionItemId,
            "condition": condition.rawValue
        ]
        if let askingPrice = askingPrice, askingPrice > 0 {
            input["askingPrice"] = askingPrice
        }
        if !conditionNotes.isEmpty {
            input["conditionNotes"] = conditionNotes
        }
        if !listingUrl.isEmpty {
            input["listingUrl"] = listingUrl
        }
        if !notes.isEmpty {
            input["notes"] = notes
        }

        do {
            let response: AddToSellListResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return response.addToSellList.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
}
