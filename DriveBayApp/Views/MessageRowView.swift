import SwiftUI

struct MessageRowView: View {
    let message: ChatMessage
    let isLoggedIn: Bool
    // 1. Add this closure to handle the booking action
    var onBookListing: (Listing) -> Void
    
    private var isUser: Bool { message.role == .user }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                if let listings = message.listings, !listings.isEmpty {
                    Text("Found \(listings.count) nearby driveways:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                    
                    ForEach(listings) { listing in
                        ListingCardView(
                            listing: listing,
                            isLoggedIn: isLoggedIn,
                            onBook: {
                                // 2. Call the closure when the button is tapped
                                onBookListing(listing)
                            }
                        )
                        .padding(.vertical, 4)
                    }
                } else {
                    // Regular Text bubble
                    Text(message.content)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(isUser ? DriveBayTheme.accent.opacity(0.8) : Color.gray.opacity(0.25))
                        .foregroundColor(.white)
                        .cornerRadius(18, corners: isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                }
            }
            if !isUser { Spacer() }
        }
    }
}
