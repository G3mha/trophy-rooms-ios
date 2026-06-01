import SwiftUI

// MARK: - View Extension for Buylist Context Menu

extension View {
    /// Adds a buylist context menu with mark as purchased, add to collection, and remove actions
    func buylistContextMenu(
        item: BuylistItem,
        showPurchasedSheet: Binding<Bool>,
        showCollectionSheet: Binding<Bool>,
        selectedItemForPurchase: Binding<BuylistItem?>,
        selectedItemForCollection: Binding<BuylistItem?>,
        onRemove: @escaping () async -> Void
    ) -> some View {
        self
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    selectedItemForPurchase.wrappedValue = item
                    showPurchasedSheet.wrappedValue = true
                } label: {
                    Label("Mark as Purchased", systemImage: "checkmark.circle")
                }

                // Collection action only for GAME items
                if item.itemType == .GAME {
                    Button {
                        selectedItemForCollection.wrappedValue = item
                        showCollectionSheet.wrappedValue = true
                    } label: {
                        Label("Add to Collection", systemImage: "tray.full")
                    }
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
