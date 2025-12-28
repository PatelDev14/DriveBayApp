// Views/ListingCarouselView.swift
import SwiftUI

struct ListingCarouselView: View {
    let listings: [Listing]
    let isLoggedIn: Bool
    let onBookAction: (Listing) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Results")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(listings.count) spots")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(listings) { listing in
                        ListingCardView(
                            listing: listing,
                            isLoggedIn: isLoggedIn,
                            onBook: {
                                onBookAction(listing)
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.15))
        .cornerRadius(28)
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(DriveBayTheme.glassBorder.opacity(0.3)))
        .padding(.horizontal, 8)
    }
}
