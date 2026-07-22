import SwiftUI

struct AdminInlineToolbarMenuContent: View {
    let entity: AdminContextEntity
    let onEditGame: () -> Void
    let onCloneGame: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Group {
            Section {
                Label {
                    VStack(alignment: .leading) {
                        Text(entity.title)
                        if let platformName = entity.platformName {
                            Text(platformName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: iconName(for: entity.type))
                }
            }

            Section {
                switch entity.type {
                case .game:
                    Button(action: onEditGame) {
                        Label("Edit Game", systemImage: "pencil")
                    }

                    Button(action: onCloneGame) {
                        Label("Clone to Platform", systemImage: "doc.on.doc")
                    }
                case .bundle:
                    Button {
                        // TODO: Implement bundle edit
                    } label: {
                        Label("Edit Bundle", systemImage: "pencil")
                    }
                case .dlc:
                    Button {
                        // TODO: Implement DLC edit
                    } label: {
                        Label("Edit DLC", systemImage: "pencil")
                    }
                case .achievementSet:
                    Button {
                        // TODO: Implement achievement set edit
                    } label: {
                        Label("Edit Set", systemImage: "pencil")
                    }
                }
            }

            Section {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func iconName(for type: AdminEntityType) -> String {
        switch type {
        case .game: return "gamecontroller.fill"
        case .bundle: return "shippingbox.fill"
        case .dlc: return "puzzlepiece.extension.fill"
        case .achievementSet: return "star.fill"
        }
    }
}

struct AdminInlineToolbarLabel: View {
    var body: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 56, height: 56)
            .glassEffect(.regular.tint(.blue.opacity(0.3)))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct AdminGameFormSheetWrapper: View {
    let gameId: String
    @ObservedObject var viewModel: AdminGamesViewModel
    var onSave: (() -> Void)?

    @State private var gameToEdit: AdminGameItem?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading game...")
            } else if let game = gameToEdit {
                AdminGameFormSheet(
                    viewModel: viewModel,
                    game: game,
                    onSave: onSave
                )
            } else {
                Text("Game not found")
            }
        }
        .task {
            await loadGame()
        }
    }

    private func loadGame() async {
        await viewModel.fetchGame(id: gameId)
        await MainActor.run {
            gameToEdit = viewModel.gameToEdit
            isLoading = false
        }
    }
}
