import SwiftUI

struct AdminBundleContentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminBundlesViewModel
    @StateObject private var state = AdminBundleContentsState()
    let bundleId: String

    /// Computed property to always get the latest bundle from the ViewModel
    private var bundle: AppBundle? {
        viewModel.bundles.first { $0.id == bundleId }
    }

    var body: some View {
        NavigationStack {
            if let bundle = bundle {
                List {
                    AdminBundleGamesSection(
                        viewModel: viewModel,
                        bundleId: bundleId,
                        bundle: bundle,
                        onAddGame: { state.showGamePicker = true }
                    )
                    AdminBundleDLCsSection(
                        viewModel: viewModel,
                        bundleId: bundleId,
                        bundle: bundle,
                        onAddDLC: { state.showDLCPicker = true }
                    )
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
                .sheet(isPresented: $state.showGamePicker) {
                    GamePickerSheet(
                        title: "Add Game to Bundle",
                        excludedGameIds: Set(bundle.gameFamilies?.map(\.id) ?? [])
                    ) { selectedGame in
                        Task {
                            if let gameFamilyId = selectedGame.gameFamilyId {
                                _ = await viewModel.addGameFamilyToBundle(
                                    gameFamilyId: gameFamilyId,
                                    bundleId: bundleId
                                )
                            }
                        }
                    }
                }
                .sheet(isPresented: $state.showDLCPicker) {
                    BundleDLCPickerSheet(
                        viewModel: viewModel,
                        bundleId: bundleId,
                        excludedDLCIds: Set(bundle.dlcs?.map(\.id) ?? [])
                    )
                }
            } else {
                ContentUnavailableView(
                    "Bundle Not Found",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .task {
            await viewModel.fetchAvailableDLCs()
        }
    }
}
