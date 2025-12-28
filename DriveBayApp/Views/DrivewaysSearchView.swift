import SwiftUI
import FirebaseFirestore
import CoreLocation
import MapKit

struct DrivewaysSearchView: View {
    @StateObject private var viewModel = DrivewaysSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var navigationPath = NavigationPath()
    
    // UI Local State
    @State private var addressInput: String = ""
    @State private var addressSuggestions: [CLPlacemark] = []
    private let geocoder = CLGeocoder()
    @State private var geocodeWorkItem: DispatchWorkItem?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // MARK: - Header
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(DriveBayTheme.accent)
                                .shadow(color: DriveBayTheme.glow, radius: 30, y: 12)
                            
                            VStack(spacing: 8) {
                                Text("Find Parking")
                                    .font(.system(size: 42, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Search available private driveways near you")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 40)
                        
                        // MARK: - Smart Search Bar
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Search Area")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                TextField("e.g. Oshawa, ON or 50 Bison Dr", text: $addressInput)
                                    .padding(18)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(18)
                                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DriveBayTheme.accent.opacity(0.6).gradient, lineWidth: 2))
                                    .shadow(color: DriveBayTheme.glow.opacity(0.6), radius: 14, y: 7)
                                    .foregroundColor(.white)
                                    .autocorrectionDisabled()
                                    .onChange(of: addressInput) { _, newValue in
                                        debounceGeocode(newValue)
                                    }
                            }
                            
                            // Suggestions Dropdown
                            if !addressSuggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(addressSuggestions, id: \.self) { placemark in
                                        Button {
                                            selectSuggestion(placemark)
                                        } label: {
                                            HStack {
                                                Image(systemName: "mappin.and.ellipse")
                                                    .foregroundColor(DriveBayTheme.accent)
                                                Text(placemark.formattedAddress)
                                                    .font(.subheadline)
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color.white.opacity(0.05))
                                        }
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding()
                        }
                        
                        // Search Button
                        Button(action: {
                            viewModel.searchQuery = addressInput
                            viewModel.searchDriveways()
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("Search Driveways")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(DriveBayTheme.accent)
                            .foregroundColor(.black)
                            .font(.title2.bold())
                            .cornerRadius(20)
                            .shadow(color: DriveBayTheme.glow, radius: 25, y: 12)
                        }
                        .disabled(viewModel.isLoading || addressInput.isEmpty)
                        .padding(.horizontal, 40)
                        
                        // Empty State
                        if viewModel.didSearch && viewModel.listings.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 16) {
                                Image(systemName: "car.2.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("No driveways found nearby")
                                    .font(.title2.bold())
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 40)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }.foregroundColor(.white)
                }
            }
            // Navigate to results when listings are found
            .navigationDestination(for: SearchResultsWrapper.self) { wrapper in
                ResultsView(listings: wrapper.listings)
            }
            .onReceive(viewModel.$listings) { newListings in
                if !newListings.isEmpty {
                    navigationPath.append(SearchResultsWrapper(listings: newListings))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func debounceGeocode(_ query: String) {
        geocodeWorkItem?.cancel()
        guard query.count >= 3 else {
            addressSuggestions = []
            return
        }
        
        let workItem = DispatchWorkItem {
            geocoder.geocodeAddressString(query) { placemarks, _ in
                self.addressSuggestions = Array((placemarks ?? []).prefix(3))
            }
        }
        geocodeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
    }
    
    private func selectSuggestion(_ placemark: CLPlacemark) {
        addressInput = placemark.formattedAddress
        addressSuggestions = []
        // Immediately trigger search
        viewModel.searchQuery = addressInput
        viewModel.searchDriveways()
    }
}

// MARK: - Wrapper for Navigation
struct SearchResultsWrapper: Identifiable, Hashable {
    let id = UUID()
    let listings: [Listing]
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SearchResultsWrapper, rhs: SearchResultsWrapper) -> Bool { lhs.id == rhs.id }
}
