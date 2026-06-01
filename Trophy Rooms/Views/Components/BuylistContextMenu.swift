import SwiftUI

// MARK: - View Extension for Buylist Context Menu

extension View {
    /// Adds a buylist context menu with mark as purchased and remove actions
    func buylistContextMenu(
        item: BuylistItem,
        selectedItemForPurchase: Binding<BuylistItem?>,
        onRemove: @escaping () async -> Void
    ) -> some View {
        self
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    selectedItemForPurchase.wrappedValue = item
                } label: {
                    Label("Mark as Purchased", systemImage: "checkmark.circle")
                }

                Divider()

                Button(role: .destructive) {
                    Task {
                        await onRemove()
                    }
                } label: {
                    Label("Remove from Buylist", systemImage: "trash")
                }
            }
    }
}
