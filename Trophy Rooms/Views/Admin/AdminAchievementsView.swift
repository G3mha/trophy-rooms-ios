import SwiftUI

struct AdminAchievementsView: View {
    @StateObject private var viewModel = AdminAchievementsViewModel()
    @State private var showingSetPicker = false
    @State private var showingCreateSheet = false
    @State private var showingCSVImportSheet = false
    @State private var achievementToEdit: AdminAchievement?
    @State private var achievementToDelete: AdminAchievement?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Set selector
            Button {
                showingSetPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Achievement Set")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.currentSetTitle.isEmpty ? "Select a set..." : viewModel.currentSetTitle)
                            .font(.headline)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .buttonStyle(.plain)

            if viewModel.selectedSetId.isEmpty {
                ContentUnavailableView(
                    "No Set Selected",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Select an achievement set to view and manage achievements")
                )
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.achievements.isEmpty {
                ContentUnavailableView(
                    "No Achievements",
                    systemImage: "star",
                    description: Text("This set has no achievements yet. Add some!")
                )
            } else {
                List {
                    ForEach(viewModel.achievements) { achievement in
                        HStack(spacing: 12) {
                            if isSelecting {
                                Image(systemName: selectedIds.contains(achievement.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIds.contains(achievement.id) ? .blue : .gray)
                                    .onTapGesture {
                                        toggleSelection(achievement.id)
                                    }
                            }
                            AsyncImage(url: achievement.iconUrl.flatMap { URL(string: $0) }) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(tierColor(achievement.tier))
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(achievement.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                if let description = achievement.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                HStack(spacing: 8) {
                                    Text("\(achievement.points) pts")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                    if let tier = achievement.tier {
                                        Text(tier.rawValue)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(tierColor(tier).opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isSelecting {
                                toggleSelection(achievement.id)
                            } else {
                                achievementToEdit = achievement
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if !isSelecting {
                                Button(role: .destructive) {
                                    achievementToDelete = achievement
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    achievementToEdit = achievement
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Achievements")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isSelecting {
                    Button("Done") {
                        isSelecting = false
                        selectedIds.removeAll()
                    }
                } else {
                    Menu {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("Add Achievement", systemImage: "plus")
                        }
                        .disabled(viewModel.selectedSetId.isEmpty)

                        Button {
                            showingCSVImportSheet = true
                        } label: {
                            Label("Import CSV", systemImage: "doc.badge.plus")
                        }
                        .disabled(viewModel.selectedSetId.isEmpty)

                        Button {
                            isSelecting = true
                        } label: {
                            Label("Select", systemImage: "checkmark.circle")
                        }
                        .disabled(viewModel.selectedSetId.isEmpty || viewModel.achievements.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting && !selectedIds.isEmpty {
                Button(role: .destructive) {
                    showingBulkDeleteConfirmation = true
                } label: {
                    Label("Delete \(selectedIds.count)", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding()
                .background(.bar)
            }
        }
        .task {
            await viewModel.fetchAchievementSets()
        }
        .sheet(isPresented: $showingSetPicker) {
            SetPickerSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCreateSheet) {
            AdminAchievementFormSheet(viewModel: viewModel, achievement: nil)
        }
        .sheet(item: $achievementToEdit) { achievement in
            AdminAchievementFormSheet(viewModel: viewModel, achievement: achievement)
        }
        .sheet(isPresented: $showingCSVImportSheet) {
            AdminCSVImportSheet(viewModel: viewModel)
        }
        .alert("Delete Achievement", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                achievementToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let achievement = achievementToDelete {
                    Task {
                        _ = await viewModel.deleteAchievement(id: achievement.id)
                        achievementToDelete = nil
                    }
                }
            }
        } message: {
            if let achievement = achievementToDelete {
                Text("Are you sure you want to delete \"\(achievement.title)\"? This action cannot be undone.")
            }
        }
        .alert("Delete \(selectedIds.count) Achievements", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.bulkDeleteAchievements(ids: Array(selectedIds))
                    selectedIds.removeAll()
                    isSelecting = false
                }
            }
        } message: {
            Text("Are you sure you want to delete \(selectedIds.count) achievement(s)? This action cannot be undone.")
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    private func tierColor(_ tier: AchievementTier?) -> Color {
        guard let tier = tier else { return .gray }
        switch tier {
        case .BRONZE: return .brown
        case .SILVER: return .gray
        case .GOLD: return .yellow
        }
    }
}

struct SetPickerSheet: View {
    @ObservedObject var viewModel: AdminAchievementsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredSets: [AdminAchievementSet] {
        if searchText.isEmpty {
            return viewModel.achievementSets
        }
        return viewModel.achievementSets.filter { set in
            set.title.localizedCaseInsensitiveContains(searchText) ||
            (set.game?.title.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredSets) { set in
                Button {
                    Task {
                        await viewModel.fetchAchievements(setId: set.id)
                        dismiss()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(set.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let game = set.game {
                            Text(game.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let count = set.achievementCount {
                            Text("\(count) achievements")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search sets")
            .navigationTitle("Select Set")
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

#Preview {
    NavigationStack {
        AdminAchievementsView()
    }
}
