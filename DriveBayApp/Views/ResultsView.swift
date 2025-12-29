import SwiftUI

struct ResultsView: View {
    let listings: [Listing]
    @State private var selectedListing: Listing? = nil
    
    // MARK: - Filter States
    @State private var sortByPrice = false
    @State private var maxPrice: Double = 100.0
    @State private var selectedCity: String = "All"
    @State private var showingFilterSheet = false

    // MARK: - Logic
    var availableCities: [String] {
        let cities = Set(listings.map { $0.city })
        return ["All"] + cities.sorted()
    }

    var filteredListings: [Listing] {
        var result = listings.filter { listing in
            let priceMatch = listing.rate <= maxPrice
            let cityMatch = selectedCity == "All" || listing.city == selectedCity
            return priceMatch && cityMatch
        }
        
        if sortByPrice {
            result.sort { $0.rate < $1.rate }
        }
        return result
    }

    // Helper to reset everything
    private func resetFilters() {
        sortByPrice = false
        maxPrice = 100.0
        selectedCity = "All"
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: { showingFilterSheet = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .padding(10)
                                .background(DriveBayTheme.accent)
                                .foregroundColor(.black)
                                .clipShape(Circle())
                        }
                        
                        // Clear Button (Only shows if filters are active)
                        if selectedCity != "All" || maxPrice < 100 || sortByPrice {
                            Button(action: resetFilters) {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Clear")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(20)
                            }
                        }

                        FilterTag(label: "Cheapest First", isActive: sortByPrice) {
                            sortByPrice.toggle()
                        }
                        
                        FilterTag(label: selectedCity, isActive: selectedCity != "All") {
                            showingFilterSheet = true
                        }
                    }
                    .padding()
                }
                
                // MARK: - List View
                if filteredListings.isEmpty {
                    emptyStateWithReset
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredListings) { listing in
                                ListingCardView(listing: listing, isLoggedIn: true) {
                                    self.selectedListing = listing
                                }
                                .padding(.horizontal)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .sheet(item: $selectedListing) { listing in
                                        BookingRequestView(listing: listing)
                                    }
                }
            }
        }
        .navigationTitle("Find a Spot")
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView(
                maxPrice: $maxPrice,
                selectedCity: $selectedCity,
                cities: availableCities,
                sortByPrice: $sortByPrice,
                onReset: resetFilters
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Empty State with integrated Reset
    private var emptyStateWithReset: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 70))
                .foregroundColor(.white.opacity(0.2))
            
            VStack(spacing: 8) {
                Text("No results found")
                    .font(.headline).foregroundColor(.white)
                Text("Try adjusting your filters to find more spots.")
                    .font(.subheadline).foregroundColor(.white.opacity(0.5))
            }

            Button(action: resetFilters) {
                Text("Clear All Filters")
                    .font(.subheadline.bold())
                    .foregroundColor(DriveBayTheme.accent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(DriveBayTheme.accent.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Filter Sheet with Reset
struct FilterSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var maxPrice: Double
    @Binding var selectedCity: String
    let cities: [String]
    @Binding var sortByPrice: Bool
    var onReset: () -> Void
    
    var body: some View {
        ZStack {
            Color("121212").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 30) {
                HStack {
                    Text("Refine Search")
                        .font(.title2.bold())
                    Spacer()
                    Button("Reset") {
                        onReset()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                }
                .foregroundColor(.white)
                
                // City Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.headline).foregroundColor(.white.opacity(0.7))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(cities, id: \.self) { city in
                                Button(action: { selectedCity = city }) {
                                    Text(city)
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(selectedCity == city ? DriveBayTheme.accent : Color.white.opacity(0.1))
                                        .foregroundColor(selectedCity == city ? .black : .white)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                
                // Price Slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Budget (Hourly)")
                            .font(.headline).foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("Up to $\(Int(maxPrice))")
                            .foregroundColor(DriveBayTheme.accent).bold()
                    }
                    Slider(value: $maxPrice, in: 1...30, step: 2)
                        .tint(DriveBayTheme.accent)
                }
                
                Toggle("Sort by Lowest Price First", isOn: $sortByPrice)
                    .tint(DriveBayTheme.accent)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Apply Filters")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DriveBayTheme.accent)
                        .cornerRadius(16)
                }
            }
            .padding(30)
        }
    }
}

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
