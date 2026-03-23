import SwiftUI

/// A composite view that handles loading, error, empty, and content states
struct AsyncContentView<Content: View, EmptyContent: View>: View {
    let isLoading: Bool
    let errorMessage: String?
    let isEmpty: Bool
    let loadingMessage: String?
    let retryAction: (() -> Void)?
    @ViewBuilder let emptyContent: () -> EmptyContent
    @ViewBuilder let content: () -> Content

    init(
        isLoading: Bool,
        errorMessage: String?,
        isEmpty: Bool,
        loadingMessage: String? = nil,
        retryAction: (() -> Void)? = nil,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.isEmpty = isEmpty
        self.loadingMessage = loadingMessage
        self.retryAction = retryAction
        self.emptyContent = emptyContent
        self.content = content
    }

    var body: some View {
        if isLoading {
            LoadingStateView(loadingMessage)
        } else if let errorMessage = errorMessage {
            ErrorStateView(errorMessage, retryAction: retryAction)
        } else if isEmpty {
            emptyContent()
        } else {
            content()
        }
    }
}

/// Convenience initializer when using standard EmptyStateView
extension AsyncContentView where EmptyContent == EmptyStateView {
    init(
        isLoading: Bool,
        errorMessage: String?,
        isEmpty: Bool,
        loadingMessage: String? = nil,
        emptyIcon: String,
        emptyTitle: String,
        emptySubtitle: String? = nil,
        emptyActionTitle: String? = nil,
        emptyAction: (() -> Void)? = nil,
        retryAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.isEmpty = isEmpty
        self.loadingMessage = loadingMessage
        self.retryAction = retryAction
        self.emptyContent = {
            EmptyStateView(
                icon: emptyIcon,
                title: emptyTitle,
                subtitle: emptySubtitle,
                actionTitle: emptyActionTitle,
                action: emptyAction
            )
        }
        self.content = content
    }
}

#Preview("Loading") {
    AsyncContentView(
        isLoading: true,
        errorMessage: nil,
        isEmpty: false,
        loadingMessage: "Loading games...",
        emptyIcon: "gamecontroller",
        emptyTitle: "No games"
    ) {
        Text("Content")
    }
}

#Preview("Error") {
    AsyncContentView(
        isLoading: false,
        errorMessage: "Network error",
        isEmpty: false,
        retryAction: {}
    ) {
        EmptyStateView(icon: "gamecontroller", title: "No games")
    } content: {
        Text("Content")
    }
}

#Preview("Empty") {
    AsyncContentView(
        isLoading: false,
        errorMessage: nil,
        isEmpty: true,
        emptyIcon: "gamecontroller",
        emptyTitle: "No games found",
        emptySubtitle: "Add some games to get started"
    ) {
        Text("Content")
    }
}

#Preview("Content") {
    AsyncContentView(
        isLoading: false,
        errorMessage: nil,
        isEmpty: false,
        emptyIcon: "gamecontroller",
        emptyTitle: "No games"
    ) {
        List {
            Text("Game 1")
            Text("Game 2")
            Text("Game 3")
        }
    }
}
