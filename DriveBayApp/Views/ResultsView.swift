// Views/ResultsView.swift
import SwiftUI

struct ResultsView: View {
    let listings: [Listing]
    
    @State private var selectedListing: Listing? = nil
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(listings) { listing in
                        ListingCardView(listing: listing, isLoggedIn: true) {
                            selectedListing = listing
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Available Driveways (\(listings.count))")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedListing) { listing in
            BookingRequestView(listing: listing)
        }
        .preferredColorScheme(.dark)
    }
}
