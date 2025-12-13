//
//  ListingCarouselView.swift
//  DriveBayApp
//
//  Created by Dev Patel on 2025-12-12.
//

// Views/ListingCarouselView.swift
import SwiftUI

struct ListingCarouselView: View {
    let listings: [Listing]
    let isLoggedIn: Bool
    
    // NOTE: Replace this with your actual booking implementation
    let onBookAction: (Listing) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // Sub-header for the card block
            Text("Top \(listings.count) Results:")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 4)
            
            // Use a ScrollView for the stack of cards
            VStack(spacing: 12) {
                ForEach(listings) { listing in
                    // Use the simplified ListingCardView
                    ListingCardView(listing: listing, isLoggedIn: isLoggedIn) {
                        onBookAction(listing)
                    }
                    // Add a small divider/space between cards
                    // .padding(.bottom, 8)
                }
            }
            .padding(.top, 4)
        }
        // Give the entire block a slightly offset background for visual grouping
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
}
