import SwiftUI

/// The app's single pagination control (see .claude/skills/trophy-cabinet-design).
///
/// Replaces three near-duplicate implementations. Chevrons sit in circular
/// walnut wells matching the app's toolbar buttons, and the page indicator is
/// a tappable brass-edged capsule rather than a plain label, so it reads as
/// the control it is.
struct PaginationBar: View {
    let currentPage: Int
    let totalPages: Int
    let totalCount: Int?
    /// Noun for the total ("games", "bundles") - omitted when totalCount is nil
    let itemNoun: String
    let isLoading: Bool
    /// Adds first/last jumps - useful for admin data management, noise on browse
    let showsEndJumps: Bool
    let onGoToPage: (Int) -> Void

    @State private var showJumpSheet = false

    init(
        currentPage: Int,
        totalPages: Int,
        totalCount: Int? = nil,
        itemNoun: String = "items",
        isLoading: Bool = false,
        showsEndJumps: Bool = false,
        onGoToPage: @escaping (Int) -> Void
    ) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.totalCount = totalCount
        self.itemNoun = itemNoun
        self.isLoading = isLoading
        self.showsEndJumps = showsEndJumps
        self.onGoToPage = onGoToPage
    }

    private var canGoBack: Bool { currentPage > 1 && !isLoading }
    private var canGoForward: Bool { currentPage < totalPages && !isLoading }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                if showsEndJumps {
                    stepButton("chevron.backward.2", enabled: canGoBack) { onGoToPage(1) }
                }
                stepButton("chevron.backward", enabled: canGoBack) { onGoToPage(currentPage - 1) }

                Spacer(minLength: 8)

                pageIndicator

                Spacer(minLength: 8)

                stepButton("chevron.forward", enabled: canGoForward) { onGoToPage(currentPage + 1) }
                if showsEndJumps {
                    stepButton("chevron.forward.2", enabled: canGoForward) { onGoToPage(totalPages) }
                }
            }

            if let totalCount {
                Text("\(totalCount.formatted()) \(itemNoun)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(alignment: .top) {
            // A hairline instead of a material bar, so the control sits on the
            // cabinet canvas rather than floating on a foreign surface
            Rectangle()
                .fill(Cabinet.brass.opacity(0.16))
                .frame(height: 1)
        }
        .sheet(isPresented: $showJumpSheet) {
            PageJumpSheet(currentPage: currentPage, totalPages: totalPages) { page in
                showJumpSheet = false
                onGoToPage(page)
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(enabled ? Cabinet.brass : Cabinet.brass.opacity(0.25))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Cabinet.card))
                .overlay(
                    Circle().stroke(Cabinet.brass.opacity(enabled ? 0.3 : 0.12), lineWidth: 1)
                )
        }
        .disabled(!enabled)
        .accessibilityLabel(accessibilityLabel(for: symbol))
    }

    private var pageIndicator: some View {
        Button {
            showJumpSheet = true
        } label: {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("PAGE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Cabinet.brass.opacity(0.75))

                    Text("\(currentPage)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Cabinet.bone)

                    Text("/ \(totalPages.formatted())")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Cabinet.card))
            .overlay(Capsule().stroke(Cabinet.brass.opacity(0.28), lineWidth: 1))
        }
        .disabled(isLoading || totalPages <= 1)
        .accessibilityLabel("Page \(currentPage) of \(totalPages). Tap to jump to a page.")
    }

    private func accessibilityLabel(for symbol: String) -> String {
        switch symbol {
        case "chevron.backward.2": return "First page"
        case "chevron.backward": return "Previous page"
        case "chevron.forward": return "Next page"
        default: return "Last page"
        }
    }
}

// MARK: - Jump sheet

/// Type a destination instead of spinning a wheel - a catalog can run to
/// thousands of pages, where a wheel picker is unusable.
private struct PageJumpSheet: View {
    let currentPage: Int
    let totalPages: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var entry: String
    @FocusState private var fieldFocused: Bool

    init(currentPage: Int, totalPages: Int, onSelect: @escaping (Int) -> Void) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.onSelect = onSelect
        self._entry = State(initialValue: "\(currentPage)")
    }

    private var parsedPage: Int? {
        guard let value = Int(entry), value >= 1, value <= totalPages else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                TextField("", text: $entry)
                    .font(Cabinet.display(40))
                    .foregroundStyle(Cabinet.bone)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($fieldFocused)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Cabinet.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Cabinet.brass.opacity(parsedPage == nil ? 0.5 : 0.28), lineWidth: 1)
                    )

                Text("1 – \(totalPages.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button("First") { onSelect(1) }
                        .buttonStyle(.bordered)
                    Button("Last") { onSelect(totalPages) }
                        .buttonStyle(.bordered)
                }
                .tint(Cabinet.brass)

                Spacer()
            }
            .padding(20)
            .cabinetCanvas()
            .navigationTitle("Jump to Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Go") {
                        if let page = parsedPage { onSelect(page) }
                    }
                    .fontWeight(.semibold)
                    .disabled(parsedPage == nil)
                }
            }
        }
        .onAppear { fieldFocused = true }
    }
}

#Preview {
    VStack {
        Spacer()
        PaginationBar(currentPage: 1, totalPages: 1905, totalCount: 47612, itemNoun: "games") { _ in }
        PaginationBar(currentPage: 47, totalPages: 1905, totalCount: 47612, itemNoun: "games", showsEndJumps: true) { _ in }
    }
    .background(Cabinet.canvas)
}
