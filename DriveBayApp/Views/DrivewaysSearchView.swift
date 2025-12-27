// Views/DrivewaysSearchView.swift
import SwiftUI
import FirebaseFirestore
import CoreLocation

struct DrivewaysSearchView: View {
    @StateObject private var viewModel = DrivewaysSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var navigationPath = NavigationPath()
    
    // Smart address input
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
                                
                                TextField("e.g. Miami Beach, FL or 50 Bison Dr, Winnipeg", text: $addressInput)
                                    .padding(18)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(18)
                                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DriveBayTheme.accent.opacity(0.6).gradient, lineWidth: 2))
                                    .shadow(color: DriveBayTheme.glow.opacity(0.6), radius: 14, y: 7)
                                    .foregroundColor(.white)
                                    .autocapitalization(.words)
                                    .onChange(of: addressInput) { newValue in
                                        debounceGeocode(newValue)
                                        if newValue.isEmpty {
                                            clearAllSearchFields()
                                        }
                                    }
                            }
                            
                            // Suggestions
                            if !addressSuggestions.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Suggestions")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal)
                                    
                                    ForEach(addressSuggestions, id: \.self) { placemark in
                                        Button {
                                            selectSuggestion(placemark)
                                        } label: {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(DriveBayTheme.accent)
                                                Text(placemark.formattedAddress)
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                Spacer()
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(18)
                                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DriveBayTheme.glassBorder.opacity(0.4)))
                                .padding(.horizontal)
                            }
                            
                            // Optional detailed fields (pre-filled from suggestion)
                            VStack(spacing: 16) {
                                GlassField(placeholder: "City", icon: "building.2.fill", text: $viewModel.city)
                                GlassField(placeholder: "State / Province", icon: "map.fill", text: $viewModel.state)
                                GlassField(placeholder: "Country", icon: "globe", text: $viewModel.country)
                                GlassField(placeholder: "Zip / Postal Code (optional)", icon: "envelope.fill", text: $viewModel.zipCode)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        
                        // Search Button
                        Button("Search Driveways") {
                            viewModel.address = addressInput
                            viewModel.searchDriveways()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(DriveBayTheme.accent)
                        .foregroundColor(.black)
                        .font(.title2.bold())
                        .cornerRadius(20)
                        .shadow(color: DriveBayTheme.glow, radius: 25, y: 12)
                        .padding(.horizontal, 40)
                        .disabled(viewModel.isLoading || addressInput.isEmpty)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                        }
                        
                        if viewModel.didSearch && viewModel.listings.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "car.2.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("No driveways found")
                                    .font(.title2.bold())
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Try a different location or check back later.")
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 40)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Search Driveways")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.white.opacity(0.9))
                        .fontWeight(.medium)
                }
            }
            .navigationDestination(for: SearchResultsWrapper.self) { wrapper in
                ResultsView(listings: wrapper.listings)
            }
            .onReceive(viewModel.$listings) { newListings in
                if !newListings.isEmpty {
                    navigationPath.append(SearchResultsWrapper(listings: newListings))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Clear all fields when main search is cleared
    private func clearAllSearchFields() {
        viewModel.city = ""
        viewModel.state = ""
        viewModel.country = ""
        viewModel.zipCode = ""
        addressSuggestions = []
    }
    
    // MARK: - Debounce Geocode
    private func debounceGeocode(_ query: String) {
        geocodeWorkItem?.cancel()
        
        guard query.count >= 3 else {
            addressSuggestions = []
            return
        }
        
        let workItem = DispatchWorkItem {
            autocompleteAddress(query)
        }
        geocodeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    // MARK: - Autocomplete Address (improved for Canada)
    private func autocompleteAddress(_ address: String) {
        var searchString = address
        
        // Add context to improve Canadian results
        if viewModel.country == "Canada" {
            searchString += ", Canada"
        } else if viewModel.country == "USA" {
            searchString += ", United States"
        }
        
        geocoder.geocodeAddressString(searchString) { placemarks, error in
            if let error = error {
                print("Geocode error: \(error.localizedDescription)")
                return
            }
            addressSuggestions = Array((placemarks ?? []).prefix(5))
        }
    }
    
    // MARK: - Select Suggestion (smarter fill)
    private func selectSuggestion(_ placemark: CLPlacemark) {
        let street = [placemark.subThoroughfare, placemark.thoroughfare].compactMap { $0 }.joined(separator: " ")
        addressInput = street.isEmpty ? (placemark.locality ?? placemark.name ?? "") : street
        
        viewModel.city = placemark.locality ?? placemark.subLocality ?? ""
        viewModel.state = placemark.administrativeArea ?? viewModel.state
        viewModel.zipCode = placemark.postalCode ?? ""
        viewModel.country = placemark.isoCountryCode == "US" ? "USA" :
                           placemark.isoCountryCode == "CA" ? "Canada" : viewModel.country
        
        addressSuggestions = []
    }
}

// MARK: - Wrapper for Navigation
private struct SearchResultsWrapper: Identifiable, Hashable {
    let id = UUID()
    let listings: [Listing]
    
    static func == (lhs: SearchResultsWrapper, rhs: SearchResultsWrapper) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Glass Field with Icon
private struct GlassField: View {
    let placeholder: String
    let icon: String?
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20)
            }
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                .foregroundColor(.white)
                .autocapitalization(.words)
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DriveBayTheme.glassBorder.opacity(0.6), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }
}

