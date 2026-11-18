import SwiftUI
import PhotosUI

/// Picture, name, bio, social handles and pinned games; the iOS side of the
/// web /profile page
struct EditProfileView: View {
    @StateObject private var viewModel = EditProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var pickingFor: ShowcaseList?
    @State private var confirmDiscard = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                CabinetLoadingView("Loading profile")
            } else if let loadError = viewModel.loadError {
                ContentUnavailableView(
                    "Couldn't Load Profile",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else {
                form
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        // Unsaved edits swap the back button for one that asks first
        .navigationBarBackButtonHidden(viewModel.hasChanges)
        .toolbar {
            if viewModel.hasChanges {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { confirmDiscard = true }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Save") { Task { await viewModel.save() } }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.hasChanges)
                }
            }
            if let userId = viewModel.userId {
                ToolbarItem(placement: .secondaryAction) {
                    NavigationLink("View Profile") {
                        UserProfileView(userId: userId, userName: viewModel.name)
                    }
                }
            }
        }
        .task { await viewModel.load() }
        .onChange(of: photoItem) {
            guard let item = photoItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.uploadAvatar(data)
                } else {
                    viewModel.avatarError = "Couldn't read that photo."
                }
                photoItem = nil
            }
        }
        .sheet(item: $pickingFor) { list in
            ShowcaseGamePicker(list: list, viewModel: viewModel)
        }
        .confirmationDialog("Discard your changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard Changes", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        }
    }

    private var form: some View {
        List {
            Section {
                VStack(spacing: 14) {
                    ProfileAvatar(
                        url: viewModel.avatarUrl,
                        name: viewModel.name,
                        userId: viewModel.userId ?? "",
                        size: 104,
                        framed: true
                    )
                    if viewModel.avatarBusy {
                        ProgressView()
                            .frame(height: 22)
                    } else {
                        HStack(spacing: 20) {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Text(viewModel.avatarUrl == nil ? "Upload Picture" : "Change Picture")
                            }
                            if viewModel.avatarUrl != nil {
                                Button("Remove", role: .destructive) {
                                    Task { await viewModel.removeAvatar() }
                                }
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.borderless)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
            } footer: {
                if let avatarError = viewModel.avatarError {
                    Text(avatarError)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                }
            }

            Section {
                TextField("Display name", text: $viewModel.name)
                    .textContentType(.nickname)
                    .onChange(of: viewModel.name) {
                        viewModel.name = String(viewModel.name.prefix(EditProfileViewModel.nameMaxLength))
                    }
                TextField("Bio", text: $viewModel.bio, axis: .vertical)
                    .lineLimit(3...6)
                    .onChange(of: viewModel.bio) {
                        viewModel.bio = String(viewModel.bio.prefix(EditProfileViewModel.bioMaxLength))
                    }
            } header: {
                Text("Profile")
            } footer: {
                Text("\(viewModel.bio.count)/\(EditProfileViewModel.bioMaxLength)")
            }

            Section("Social Networks") {
                ForEach(SocialNetwork.allCases) { network in
                    LabeledContent(network.label) {
                        TextField(network.placeholder, text: handleBinding(network))
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
            }

            ForEach(ShowcaseList.allCases) { list in
                showcaseSection(list)
            }

            if let saveError = viewModel.saveError {
                Section {
                    Text(saveError).foregroundStyle(.red)
                }
            } else if viewModel.saved && !viewModel.hasChanges {
                Section {
                    Label("Profile saved", systemImage: "checkmark.circle")
                        .foregroundStyle(Cabinet.Tint.positive)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .cabinetCanvas()
        .disabled(viewModel.isSaving)
        .sensoryFeedback(.success, trigger: viewModel.saved) { _, saved in saved }
    }

    private func showcaseSection(_ list: ShowcaseList) -> some View {
        let games = viewModel.lists[list] ?? []
        return Section {
            ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(Cabinet.display(15))
                        .foregroundColor(Cabinet.brass)
                        .frame(width: 22, alignment: .trailing)
                    RemoteImage(url: game.coverUrl) { Cabinet.card }
                        .frame(width: 30, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .background(Rectangle().fill(Cabinet.ink).offset(x: 3, y: 3))
                    Text(game.title)
                        .lineLimit(2)
                }
            }
            .onMove { from, to in viewModel.lists[list]?.move(fromOffsets: from, toOffset: to) }
            .onDelete { offsets in viewModel.lists[list]?.remove(atOffsets: offsets) }

            if games.count < ShowcaseList.maxGames {
                Button {
                    pickingFor = list
                } label: {
                    Label("Add Game", systemImage: "plus")
                }
            }
        } header: {
            HStack {
                Text(list.title)
                Spacer()
                Text("\(games.count)/\(ShowcaseList.maxGames)")
            }
        } footer: {
            if games.count > 1 {
                Text("Touch and hold a game to reorder it. Swipe to remove.")
            }
        }
    }

    private func handleBinding(_ network: SocialNetwork) -> Binding<String> {
        Binding(
            get: { viewModel.handles[network] ?? "" },
            set: { viewModel.handles[network] = String($0.prefix(64)) }
        )
    }
}

/// Pick a game for one list: any catalog game for all-time favorites, or
/// the user's own Platinums or collection games
private struct ShowcaseGamePicker: View {
    let list: ShowcaseList
    @ObservedObject var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var results: [ProfileGame] = []
    @State private var searching = false

    private var pickedIds: Set<String> { Set((viewModel.lists[list] ?? []).map(\.id)) }

    private var shown: [ProfileGame] {
        let pool: [ProfileGame]
        if list == .allTime {
            pool = results
        } else {
            let term = search.trimmingCharacters(in: .whitespaces)
            pool = (viewModel.candidates[list] ?? []).filter {
                term.isEmpty || $0.title.localizedCaseInsensitiveContains(term)
            }
        }
        return pool.filter { !pickedIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List(shown) { game in
                Button {
                    viewModel.lists[list, default: []].append(game)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        RemoteImage(url: game.coverUrl) { Cabinet.card }
                            .frame(width: 36, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Text(game.title)
                            .foregroundColor(.primary)
                    }
                }
            }
            .overlay {
                if searching {
                    ProgressView()
                } else if shown.isEmpty {
                    if list == .allTime && search.trimmingCharacters(in: .whitespaces).isEmpty {
                        ContentUnavailableView("Search for a Game", systemImage: "magnifyingglass")
                    } else {
                        ContentUnavailableView("Nothing to Add", systemImage: "gamecontroller", description: Text(list.emptyCandidatesText))
                    }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(list.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task(id: search) {
                guard list == .allTime else { return }
                let term = search.trimmingCharacters(in: .whitespaces)
                guard !term.isEmpty else {
                    results = []
                    return
                }
                // Debounce: a newer keystroke cancels this task
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                searching = true
                defer { searching = false }
                let found = await viewModel.search(term)
                guard !Task.isCancelled else { return }
                results = found
            }
        }
    }
}
