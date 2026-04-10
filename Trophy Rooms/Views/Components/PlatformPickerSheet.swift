//
//  PlatformPickerSheet.swift
//  Trophy Rooms
//
//  A searchable, grouped platform picker for selecting one or more platforms.
//

import SwiftUI

struct PlatformPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let platforms: [Platform]
    @Binding var selectedPlatformIds: Set<String>
    let allowsMultipleSelection: Bool

    @State private var searchText = ""

    init(
        platforms: [Platform],
        selectedPlatformIds: Binding<Set<String>>,
        allowsMultipleSelection: Bool = true
    ) {
        self.platforms = platforms
        self._selectedPlatformIds = selectedPlatformIds
        self.allowsMultipleSelection = allowsMultipleSelection
    }

    // Group platforms by manufacturer
    private var groupedPlatforms: [(String, [Platform])] {
        let groups: [(String, [String])] = [
            ("Nintendo", ["nes", "snes", "n64", "gamecube", "wii", "wii-u", "switch", "game-boy", "game-boy-color", "game-boy-advance", "nintendo-ds", "nintendo-3ds", "virtual-boy"]),
            ("Sony", ["playstation", "ps2", "ps3", "ps4", "ps5", "psp", "ps-vita"]),
            ("Microsoft", ["xbox", "xbox-360", "xbox-one", "xbox-series-x"]),
            ("Sega", ["master-system", "genesis", "mega-drive", "saturn", "dreamcast", "game-gear", "sega-cd", "sega-32x"]),
            ("Atari", ["atari-2600", "atari-5200", "atari-7800", "atari-lynx", "atari-jaguar"]),
            ("PC & Mobile", ["pc", "mac", "linux", "android", "ios"]),
            ("Digital Storefronts", ["steam", "epic-games", "gog", "itch-io", "humble-bundle"]),
        ]

        var result: [(String, [Platform])] = []
        var usedPlatformIds = Set<String>()

        for (groupName, slugs) in groups {
            let matchingPlatforms = platforms.filter { platform in
                guard let slug = platform.slug else { return false }
                return slugs.contains(slug.lowercased())
            }.sorted { $0.name < $1.name }

            if !matchingPlatforms.isEmpty {
                result.append((groupName, matchingPlatforms))
                usedPlatformIds.formUnion(matchingPlatforms.map(\.id))
            }
        }

        // Add "Other" group for any platforms not categorized
        let otherPlatforms = platforms.filter { !usedPlatformIds.contains($0.id) }
            .sorted { $0.name < $1.name }
        if !otherPlatforms.isEmpty {
            result.append(("Other", otherPlatforms))
        }

        return result
    }

    private var filteredGroupedPlatforms: [(String, [Platform])] {
        if searchText.isEmpty {
            return groupedPlatforms
        }

        return groupedPlatforms.compactMap { (groupName, platforms) in
            let filtered = platforms.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            return filtered.isEmpty ? nil : (groupName, filtered)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGroupedPlatforms, id: \.0) { groupName, platforms in
                    Section(groupName) {
                        ForEach(platforms) { platform in
                            Button {
                                togglePlatform(platform)
                            } label: {
                                HStack {
                                    if let slug = platform.slug {
                                        PlatformIcon(slug: slug, size: 20)
                                    }
                                    Text(platform.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedPlatformIds.contains(platform.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.accentColor)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search platforms")
            .navigationTitle("Select Platforms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !selectedPlatformIds.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        Text("\(selectedPlatformIds.count) selected")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func togglePlatform(_ platform: Platform) {
        if selectedPlatformIds.contains(platform.id) {
            selectedPlatformIds.remove(platform.id)
        } else {
            if allowsMultipleSelection {
                selectedPlatformIds.insert(platform.id)
            } else {
                selectedPlatformIds = [platform.id]
            }
        }
    }
}

// MARK: - Platform Selection Field

/// A field that displays selected platforms as chips and opens a picker sheet
struct PlatformSelectionField: View {
    let platforms: [Platform]
    @Binding var selectedPlatformIds: Set<String>
    let allowsMultipleSelection: Bool
    let isDisabled: Bool

    @State private var showPicker = false

    init(
        platforms: [Platform],
        selectedPlatformIds: Binding<Set<String>>,
        allowsMultipleSelection: Bool = true,
        isDisabled: Bool = false
    ) {
        self.platforms = platforms
        self._selectedPlatformIds = selectedPlatformIds
        self.allowsMultipleSelection = allowsMultipleSelection
        self.isDisabled = isDisabled
    }

    private var selectedPlatforms: [Platform] {
        platforms.filter { selectedPlatformIds.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Selected platforms as chips
            if !selectedPlatforms.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(selectedPlatforms) { platform in
                        PlatformChip(
                            platform: platform,
                            onRemove: isDisabled ? nil : {
                                selectedPlatformIds.remove(platform.id)
                            }
                        )
                    }
                }
            }

            // Add/Select button
            if !isDisabled {
                Button {
                    showPicker = true
                } label: {
                    HStack {
                        Image(systemName: selectedPlatforms.isEmpty ? "plus.circle" : "pencil")
                        Text(selectedPlatforms.isEmpty ? "Select Platforms" : "Edit Platforms")
                    }
                    .font(.subheadline)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            PlatformPickerSheet(
                platforms: platforms,
                selectedPlatformIds: $selectedPlatformIds,
                allowsMultipleSelection: allowsMultipleSelection
            )
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Platform Chip

private struct PlatformChip: View {
    let platform: Platform
    let onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            if let slug = platform.slug {
                PlatformIcon(slug: slug, size: 14)
            }
            Text(platform.name)
                .font(.subheadline)

            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Flow Layout

/// A layout that arranges views in a flowing manner, wrapping to new lines as needed
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let maxContainerWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxContainerWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (
            size: CGSize(width: maxWidth, height: currentY + lineHeight),
            positions: positions,
            sizes: sizes
        )
    }
}

#Preview("Platform Selection Field") {
    struct PreviewWrapper: View {
        @State var selectedIds: Set<String> = ["1", "2"]

        var body: some View {
            Form {
                Section("Platforms") {
                    PlatformSelectionField(
                        platforms: [
                            Platform(id: "1", name: "Nintendo Switch", slug: "switch"),
                            Platform(id: "2", name: "PlayStation 5", slug: "ps5"),
                            Platform(id: "3", name: "Xbox Series X", slug: "xbox-series-x"),
                            Platform(id: "4", name: "PC", slug: "pc"),
                        ],
                        selectedPlatformIds: $selectedIds
                    )
                }
            }
        }
    }

    return PreviewWrapper()
}
