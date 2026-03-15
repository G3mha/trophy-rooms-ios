import SwiftUI

struct WishlistButton: View {
    let isInWishlist: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Image(systemName: isInWishlist ? "heart.fill" : "heart")
                    .foregroundColor(isInWishlist ? .red : .gray)
            }
        }
        .disabled(isLoading)
    }
}

struct LargeWishlistButton: View {
    let isInWishlist: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: isInWishlist ? "heart.fill" : "heart")
                    Text(isInWishlist ? "In Wishlist" : "Add to Wishlist")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isInWishlist ? Color.red.opacity(0.1) : Color(.secondarySystemBackground))
            .foregroundColor(isInWishlist ? .red : .primary)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}
