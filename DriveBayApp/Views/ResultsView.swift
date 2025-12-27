// Views/ResultsView.swift
import SwiftUI

struct ResultsView: View {
    let listings: [Listing]
    @State private var selectedListing: Listing? = nil
    
    // Filtering States
    @State private var sortByPrice = false
    @State private var maxPrice: Double = 100.0
    
    var filteredListings: [Listing] {
        var result = listings.filter { $0.rate <= maxPrice }
        if sortByPrice {
            result.sort { $0.rate < $1.rate }
        }
        return result
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterTag(label: "Cheapest First", isActive: sortByPrice) {
                            sortByPrice.toggle()
                        }
                        
                        Menu {
                            Button("Under $5/hr") { maxPrice = 5 }
                            Button("Under $10/hr") { maxPrice = 10 }
                            Button("All Prices") { maxPrice = 100 }
                        } label: {
                            FilterTag(label: maxPrice < 100 ? "Under $\(Int(maxPrice))" : "Price", isActive: maxPrice < 100)
                        }
                    }
                    .padding()
                }
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(filteredListings) { listing in
                            ListingCardView(listing: listing, isLoggedIn: true) {
                                selectedListing = listing
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle("Driveways")
        .sheet(item: $selectedListing) { listing in
            BookingRequestView(listing: listing)
        }
    }
}

// Simple reusable filter UI
struct FilterTag: View {
    let label: String
    let isActive: Bool
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? DriveBayTheme.accent : Color.white.opacity(0.1))
                .foregroundColor(isActive ? .black : .white)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
    }
}
