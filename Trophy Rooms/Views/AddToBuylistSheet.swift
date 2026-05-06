import SwiftUI
import Combine

struct AddToBuylistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddToBuylistSheetViewModel()

    let gameId: String
    let gameTitle: String
    let versions: [GameVersion]
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

                    // Version (only show if multiple versions)
                    if versions.count > 1 {
                        Picker("Version", selection: $viewModel.gameVersionId) {
                            Text("Any Version").tag(nil as String?)
                            ForEach(versions, id: \.id) { version in
                                HStack {
                                    Text(version.name)
                                    if version.isDefault {
                                        Text("(Default)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(version.id as String?)
                            }
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
                            let success = await viewModel.addToBuylist(gameId: gameId)
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
            .navigationTitle(gameTitle)
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

class AddToBuylistSheetViewModel: ObservableObject {
    @Published var priority: BuylistPriority = .MEDIUM
    @Published var gameVersionId: String?
    @Published var estimatedPrice: Double?
    @Published var notes = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func addToBuylist(gameId: String) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

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
            "gameId": gameId,
            "priority": priority.rawValue
        ]
        if let gameVersionId = gameVersionId {
            input["gameVersionId"] = gameVersionId
        }
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
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return response.addToBuylist.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
}
