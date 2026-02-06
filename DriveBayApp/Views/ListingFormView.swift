// Views/ListingFormView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation  // For CLGeocoder autocomplete

struct ListingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ListingFormViewModel()
    
    init(editingListing: Listing? = nil) {
        let vm = ListingFormViewModel()
        if let listing = editingListing {
            vm.loadListing(listing)
        }
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    // For smarter address autocomplete
    @State private var addressSuggestions: [CLPlacemark] = []
    private let geocoder = CLGeocoder()
    @State private var geocodeWorkItem: DispatchWorkItem?
    @State private var isFillingFromSuggestion = false
    
    // States/Provinces with full names
    private let usStates: [(code: String, name: String)] = [
        ("AL", "Alabama"), ("AK", "Alaska"), ("AZ", "Arizona"), ("AR", "Arkansas"),
        ("CA", "California"), ("CO", "Colorado"), ("CT", "Connecticut"), ("DE", "Delaware"),
        ("FL", "Florida"), ("GA", "Georgia"), ("HI", "Hawaii"), ("ID", "Idaho"),
        ("IL", "Illinois"), ("IN", "Indiana"), ("IA", "Iowa"), ("KS", "Kansas"),
        ("KY", "Kentucky"), ("LA", "Louisiana"), ("ME", "Maine"), ("MD", "Maryland"),
        ("MA", "Massachusetts"), ("MI", "Michigan"), ("MN", "Minnesota"), ("MS", "Mississippi"),
        ("MO", "Missouri"), ("MT", "Montana"), ("NE", "Nebraska"), ("NV", "Nevada"),
        ("NH", "New Hampshire"), ("NJ", "New Jersey"), ("NM", "New Mexico"), ("NY", "New York"),
        ("NC", "North Carolina"), ("ND", "North Dakota"), ("OH", "Ohio"), ("OK", "Oklahoma"),
        ("OR", "Oregon"), ("PA", "Pennsylvania"), ("RI", "Rhode Island"), ("SC", "South Carolina"),
        ("SD", "South Dakota"), ("TN", "Tennessee"), ("TX", "Texas"), ("UT", "Utah"),
        ("VT", "Vermont"), ("VA", "Virginia"), ("WA", "Washington"), ("WV", "West Virginia"),
        ("WI", "Wisconsin"), ("WY", "Wyoming")
    ].sorted { $0.name < $1.name }
    
    private let canadaProvinces: [(code: String, name: String)] = [
        ("AB", "Alberta"), ("BC", "British Columbia"), ("MB", "Manitoba"),
        ("NB", "New Brunswick"), ("NL", "Newfoundland and Labrador"),
        ("NS", "Nova Scotia"), ("NT", "Northwest Territories"), ("NU", "Nunavut"),
        ("ON", "Ontario"), ("PE", "Prince Edward Island"), ("QC", "Quebec"),
        ("SK", "Saskatchewan"), ("YT", "Yukon")
    ].sorted { $0.name < $1.name }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // MARK: - Header
                        VStack(spacing: 16) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 70))
                                .foregroundStyle(DriveBayTheme.accent)
                                .shadow(color: DriveBayTheme.glow, radius: 25, y: 12)
                            
                            VStack(spacing: 8) {
                                Text("List Your Driveway")
                                    .font(.system(size: 38, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Earn money by renting out your parking spot")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 30)
                        
                        // MARK: - Error Banner
                        if let error = viewModel.validationError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(16)
                            .background(.red.opacity(0.25))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.red.opacity(0.5)))
                            .padding(.horizontal)
                        }
                        
                        // MARK: - Location Section (reorganized)
                        locationSection
                        
                        // MARK: - Availability Section
                        availabilitySection
                        
                        // MARK: - Details Section
                        detailsSection
                        
                        // MARK: - Submit Button
                        Button {
                            viewModel.submit()
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title2)
                                }
                                Text(viewModel.isLoading ? "Submitting..." : "Add My Driveway")
                                    .font(.title2.bold())
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(DriveBayTheme.accent)
                            .cornerRadius(20)
                            .shadow(color: DriveBayTheme.glow, radius: 25, y: 12)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 60)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("List Your Driveway")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .onAppear {
                viewModel.onSuccess = { dismiss() }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Location Section (reorganized + smart placeholders)
    private var locationSection: some View {
        SectionView(title: "Location Details", icon: "mappin.and.ellipse") {
            VStack(spacing: 20) {

                // MARK: - Country Picker (Dropdown)
                Picker("Country*", selection: $viewModel.country) {
                    Text("Select Country").tag("")
                    Text("United States").tag("USA")
                    Text("Canada").tag("Canada")
                }
                .pickerStyle(.menu)
                .padding(18)
                .background(Color.white.opacity(0.08))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            DriveBayTheme.accent.opacity(0.6).gradient,
                            lineWidth: 2
                        )
                )
                .shadow(color: DriveBayTheme.glow.opacity(0.6), radius: 14, y: 7)
                .onChange(of: viewModel.country) { _ in
                    // Reset dependent fields when country changes
                    viewModel.state = ""
                    resetLocationFields()
                }

                // MARK: - State / Province Picker (Dynamic)
                if !viewModel.country.isEmpty {
                    Picker(
                        viewModel.country == "USA"
                            ? "State*"
                            : "Province*",
                        selection: $viewModel.state
                    ) {
                        Text(
                            viewModel.country == "USA"
                                ? "Select State"
                                : "Select Province"
                        ).tag("")

                        let regions = viewModel.country == "USA"
                            ? usStates
                            : canadaProvinces

                        ForEach(regions, id: \.code) { region in
                            Text(region.name).tag(region.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(18)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                DriveBayTheme.accent.opacity(0.6).gradient,
                                lineWidth: 2
                            )
                    )
                    .shadow(color: DriveBayTheme.glow.opacity(0.6), radius: 14, y: 7)
                    .onChange(of: viewModel.state) { _ in
                        resetLocationFields()
                    }
                }

                // MARK: - Street Address
                InputField(
                    title: "Street Address*",
                    placeholder: "123 Ocean Drive",
                    text: $viewModel.address
                )
                .onChange(of: viewModel.address) { newValue in
                    guard !isFillingFromSuggestion else {
                            isFillingFromSuggestion = false
                            return
                        }
                    debounceGeocode(newValue)
                }

                // MARK: - Address Suggestions
                if !addressSuggestions.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Suggestions")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        ForEach(addressSuggestions, id: \.self) { placemark in
                            Button {
                                fillFromPlacemark(placemark)
                            } label: {
                                Text(placemark.formattedAddress)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal)
                }

                // MARK: - City & Zip (Only after country selected)
                if !viewModel.country.isEmpty {
                    InputField(
                        title: "City*",
                        placeholder: viewModel.country == "Canada" ? "Winnipeg" : "Miami",
                        text: $viewModel.city
                    )

                    InputField(
                        title: viewModel.country == "Canada"
                            ? "Postal Code*"
                            : "Zip Code*",
                        placeholder: viewModel.country == "Canada" ? "R3T 4Z5" : "33139",
                        text: $viewModel.zipCode
                    )
                }

            }
        }
    }

    
    // MARK: - Clear fields when country or state changes
    private func resetLocationFields() {
        viewModel.address = ""
        viewModel.city = ""
        viewModel.zipCode = ""
        addressSuggestions = []
    }
    
    // MARK: - Autocomplete Address (with debounce)
    private func debounceGeocode(_ address: String) {
        geocodeWorkItem?.cancel()
        
        let workItem = DispatchWorkItem {
            autocompleteAddress(address)
        }
        geocodeWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func autocompleteAddress(_ address: String) {
        guard !address.isEmpty, address.count >= 3 else {
            addressSuggestions = []
            return
        }
        
        var searchString = address
        if !viewModel.city.isEmpty {
            searchString += ", \(viewModel.city)"
        }
        if !viewModel.state.isEmpty {
            searchString += ", \(viewModel.state)"
        }
        searchString += ", \(viewModel.country == "USA" ? "United States" : "Canada")"
        
        geocoder.geocodeAddressString(searchString) { placemarks, error in
            if let error = error {
                print("Geocode error: \(error.localizedDescription)")
                return
            }
            addressSuggestions = Array((placemarks ?? []).prefix(5))
        }
    }
    
    // MARK: - Fill fields from selected suggestion
    private func fillFromPlacemark(_ placemark: CLPlacemark) {
        isFillingFromSuggestion = true
        let streetNumber = placemark.subThoroughfare ?? ""
        let streetName = placemark.thoroughfare ?? ""
        viewModel.address = [streetNumber, streetName].filter { !$0.isEmpty }.joined(separator: " ")
        
        viewModel.city = placemark.locality ?? viewModel.city
        viewModel.state = placemark.administrativeArea ?? viewModel.state
        viewModel.zipCode = placemark.postalCode ?? viewModel.zipCode
        viewModel.country = placemark.isoCountryCode == "US" ? "USA" :
                           placemark.isoCountryCode == "CA" ? "Canada" : viewModel.country
        
        addressSuggestions = []
    }
    
    // MARK: - Availability Section (unchanged)
    private var availabilitySection: some View {
        SectionView(title: "Availability & Pricing", icon: "calendar.badge.clock") {
            VStack(spacing: 28) {
                // Date Picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Date")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(18)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DriveBayTheme.accent.opacity(0.6).gradient, lineWidth: 2))
                        .shadow(color: DriveBayTheme.glow.opacity(0.6), radius: 14, y: 7)
                }
                
                // Time Pickers
                HStack(spacing: 16) {
                    ClockPicker(title: "Start Time", selection: $viewModel.startTime)
                    ClockPicker(title: "End Time", selection: $viewModel.endTime)
                }
                
                // Rate per Hour — YOUR FAVORITE
                VStack(alignment: .leading, spacing: 10) {
                    Text("Rate per Hour")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: 0) {
                        Text("$")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(DriveBayTheme.accent)
                        
                        TextField("0", text: $viewModel.rate)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        
                        Text("/hr")
                            .font(.title3.bold())
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.leading, 4)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(height: 60)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DriveBayTheme.accent.opacity(0.8).gradient, lineWidth: 2.5))
                    .shadow(color: DriveBayTheme.glow.opacity(0.7), radius: 16, y: 8)
                    
                    Text("Tap to enter any amount • e.g. 12.50, 8.99, 25.00")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        SectionView(title: "Details & Contact", icon: "info.circle.fill") {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Description (Optional)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    TextEditor(text: $viewModel.description)
                        .frame(height: 110)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DriveBayTheme.accent.opacity(0.4).gradient, lineWidth: 1.5))
                        .shadow(color: DriveBayTheme.glow.opacity(0.4), radius: 12, y: 6)
                    
                    HStack {
                        Spacer()
                        Text("\(viewModel.description.count)/200")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                InputField(title: "Contact Email*", placeholder: "you@example.com", text: $viewModel.contactEmail, keyboardType: .emailAddress)
                    .textContentType(.emailAddress)
                
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Used only for booking notifications")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Reusable Components
    @ViewBuilder
    private func SectionView<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2.bold())
                    .foregroundStyle(DriveBayTheme.accent)
                    .shadow(color: DriveBayTheme.glow, radius: 10)
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            GlassCard {
                content()
                    .padding(20)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func InputField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(18)
                .background(Color.white.opacity(0.08))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(DriveBayTheme.accent.opacity(0.6).gradient, lineWidth: 2)
                )
                .shadow(color: DriveBayTheme.glow.opacity(0.6), radius: 14, y: 7)
        }
    }
}

// MARK: - Extension for nicer address display
extension CLPlacemark {
    var formattedAddress: String {
        var parts = [String]()
        if let subThoroughfare = subThoroughfare { parts.append(subThoroughfare) }
        if let thoroughfare = thoroughfare { parts.append(thoroughfare) }
        if let locality = locality { parts.append(locality) }
        if let administrativeArea = administrativeArea { parts.append(administrativeArea) }
        if let postalCode = postalCode { parts.append(postalCode) }
        return parts.joined(separator: ", ")
    }
}
