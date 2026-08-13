import SwiftUI

struct BuylistButton: View {
    let isInBuylist: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Image(systemName: isInBuylist ? "cart.fill" : "cart")
                    .foregroundColor(isInBuylist ? .orange : .gray)
            }
        }
        .disabled(isLoading)
        .accessibilityLabel(isInBuylist ? "Remove from buylist" : "Add to buylist")
        .accessibilityValue(isLoading ? "Updating" : "")
    }
}

struct LargeBuylistButton: View {
    let isInBuylist: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: isInBuylist ? "cart.fill" : "cart")
                    Text(isInBuylist ? "In Buylist" : "Add to Buylist")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isInBuylist ? Color.orange.opacity(0.1) : Cabinet.card)
            .foregroundColor(isInBuylist ? .orange : .primary)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}
