import SwiftUI

struct ListingCarouselView: View {
    let listings: [Listing]
    let isLoggedIn: Bool
    
    let onBookAction: (Listing) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text("Top \(listings.count) Results:")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 4)
                
            VStack(spacing: 12) {
                ForEach(listings) { listing in
                    ListingCardView(listing: listing, isLoggedIn: isLoggedIn) {
                        onBookAction(listing)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
}
