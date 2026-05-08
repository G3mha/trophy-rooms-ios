import SwiftUI
import Combine

struct AddBundleToBuylistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddBundleToBuylistViewModel()

    let bundleId: String
    let bundleName: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Priority
                    Picker("Priority", selection: $viewModel.priority) {
                        ForEach(BuylistPriority.allCases, id: \.self) { priority in
                            HStack {
                                Text(priorityMarker(for: priority))
                                    .fontWeight(.bold)
                                    .foregroundColor(priorityColor(for: priority))
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }

                    // Estimated Price
                    HStack {
                        Text("Est. Price")
                        Spacer()
                        TextField("0.00", value: $viewModel.estimatedPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    // Notes
                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.addToBuylist(bundleId: bundleId)
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
                                Text("Add to Buylist")
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
            .navigationTitle(bundleName)
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

    func priorityColor(for priority: BuylistPriority) -> Color {
        switch priority {
        case .HIGH: return .red
        case .MEDIUM: return .orange
        case .LOW: return .green
        }
    }

    func priorityMarker(for priority: BuylistPriority) -> String {
        switch priority {
        case .HIGH: return "!!!"
        case .MEDIUM: return "!!"
        case .LOW: return "!"
        }
    }
}

@MainActor
class AddBundleToBuylistViewModel: ObservableObject {
    @Published var priority: BuylistPriority = .MEDIUM
    @Published var estimatedPrice: Double?
    @Published var notes = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func addToBuylist(bundleId: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        let mutation = """
        mutation AddToBuylist($input: AddToBuylistInput!) {
            addToBuylist(input: $input) {
                success
                buylistItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "bundleId": bundleId,
            "priority": priority.rawValue
        ]
        if let estimatedPrice = estimatedPrice, estimatedPrice > 0 {
            input["estimatedPrice"] = estimatedPrice
        }
        if !notes.isEmpty {
            input["notes"] = notes
        }

        do {
            let response: AddToBuylistResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            isLoading = false
            return response.addToBuylist.success
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
