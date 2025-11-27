// Views/ListingFormView.swift
import SwiftUI
import FirebaseFirestore
import Combine
import FirebaseAuth

struct ListingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ListingFormViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    header
                    
                    // Validation Error
                    if let error = viewModel.validationError {
                        errorBanner(error: error)
                    }
                    
                    // Section 1: Location Details
                    locationSection
                    
                    // Section 2: Availability & Pricing
                    availabilitySection
                    
                    // Section 3: Details & Contact
                    detailsSection
                    
                    // Submit Button
                    submitButton
                }
                .padding(24)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemGray6), .white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("List Your Driveway")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(.indigo)
                Text("List Your Driveway")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            }
            
            Text("Provide all necessary information to list your spot on DriveBay.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Error Banner
    private func errorBanner(error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red.opacity(0.9))
            Spacer()
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Section 1: Location Details
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader(title: "Location Details", icon: "mappin.and.ellipse")
            
            // Row 1: Address + City
            HStack(spacing: 16) {
                glassTextField(
                    title: "Street Address*",
                    icon: "mappin.circle.fill",
                    text: $viewModel.address,
                    placeholder: "e.g., 123 Main St"
                )
                .frame(maxWidth: .infinity)
                
                glassTextField(
                    title: "City*",
                    text: $viewModel.city,
                    placeholder: "e.g., Anytown"
                )
                .frame(maxWidth: .infinity)
            }
            
            // Row 2: State + Zip + Country
            HStack(spacing: 16) {
                glassTextField(
                    title: "State / Province*",
                    text: $viewModel.state,
                    placeholder: "e.g., CA / ON"
                )
                .frame(maxWidth: .infinity)
                
                glassTextField(
                    title: "Zip / Postal Code*",
                    text: $viewModel.zipCode,
                    placeholder: "e.g., 90210"
                )
                .frame(maxWidth: .infinity)
                
                Picker("Country*", selection: $viewModel.country) {
                    Text("USA").tag("USA")
                    Text("Canada").tag("Canada")
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Section 2: Availability & Pricing
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader(title: "Availability & Pricing", icon: "calendar.badge.clock")
            
            // Date + Times Row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date*")
                        .font(.subheadline.bold())
                    DatePicker("", selection: $viewModel.date, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Time*")
                        .font(.subheadline.bold())
                    TextField("09:00", text: $viewModel.startTime)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("End Time*")
                        .font(.subheadline.bold())
                    TextField("17:30", text: $viewModel.endTime)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Rate
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Rate per Hour ($)*")
                        .font(.subheadline.bold())
                }
                
                HStack {
                    TextField("6.50", text: $viewModel.rate)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 100)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ForEach(ListingFormViewModel.presetRates, id: \.self) { rate in
                            Button {
                                viewModel.rate = "\(rate).00"
                            } label: {
                                Text("$\(rate)")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewModel.rate == "\(rate).00" ?
                                        Color.green :
                                        Color.gray.opacity(0.2)
                                    )
                                    .foregroundColor(
                                        viewModel.rate == "\(rate).00" ? .white : .primary
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Section 3: Details & Contact
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader(title: "Details & Contact", icon: "info.circle")
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.subheadline.bold())
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 100, maxHeight: 120)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                HStack {
                    Spacer()
                    Text("\(viewModel.description.count)/200")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Contact Email
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                    Text("Contact Email*")
                        .font(.subheadline.bold())
                }
                TextField("owner@driveway.com", text: $viewModel.contactEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("This email is used for booking notifications only.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: viewModel.submit) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
                Text(viewModel.isLoading ? "Submitting..." : "Add My Driveway")
                    .font(.headline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.indigo],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
        }
        .disabled(viewModel.isLoading)
        .padding(.top, 20)
    }
    
    // MARK: - Helpers
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.indigo)
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.primary)
        }
    }
    
    private func glassTextField(
        title: String = "",
        icon: String = "",
        text: Binding<String>,
        placeholder: String = ""
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                HStack(spacing: 8) {
                    if !icon.isEmpty {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
            }
            TextField(placeholder, text: text)
                .padding(14)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

class ListingFormViewModel: ObservableObject {
    
    static let presetRates = [1, 3, 5, 7, 10]
    
    @Published var address = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipCode = ""
    @Published var country = "USA"
    @Published var description = ""
    @Published var rate = "5.00"
    @Published var date = Date()
    @Published var startTime = "09:00"
    @Published var endTime = "17:30"
    @Published var contactEmail = ""
    
    @Published var isLoading = false
    @Published var validationError: String?
    
    // Add this callback so the View can dismiss itself
    var onSuccess: (() -> Void)?
    
    func submit() {
        validationError = nil
        
        // 1. Basic validation
        guard !address.isEmpty, !city.isEmpty, !state.isEmpty, !zipCode.isEmpty,
              !rate.isEmpty, !startTime.isEmpty, !endTime.isEmpty, !contactEmail.isEmpty else {
            validationError = "Please fill out all required fields."
            return
        }
        
        // 2. Rate validation
        guard let rateValue = Double(rate), rateValue > 0 else {
            validationError = "Rate must be a positive number."
            return
        }
        
        // 3. Time validation
        guard validateTime(startTime) && validateTime(endTime) else {
            validationError = "Please enter times in valid HH:MM format (e.g., 09:00)."
            return
        }
        
        guard timeToMinutes(startTime) < timeToMinutes(endTime) else {
            validationError = "End time must be after start time."
            return
        }
        
        // Submit
        isLoading = true
        
        Task { @MainActor in
            do {
                try await saveToFirebase(rate: rateValue)
                // Success → tell the View to dismiss
                onSuccess?()
            } catch {
                validationError = "Failed to save: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func validateTime(_ time: String) -> Bool {
        let components = time.split(separator: ":")
        guard components.count == 2,
              let hours = Int(components[0]), hours >= 0 && hours <= 23,
              let minutes = Int(components[1]), minutes >= 0 && minutes <= 59 else {
            return false
        }
        return true
    }
    
    private func timeToMinutes(_ time: String) -> Int {
        let components = time.split(separator: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else {
            return -1
        }
        return hours * 60 + minutes
    }
    
    private func saveToFirebase(rate: Double) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "You must be logged in"])
        }
        
        let listing: [String: Any] = [
            "ownerId": user.uid,
            "address": address,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "country": country,
            "description": description,
            "rate": rate,
            "date": Timestamp(date: date),
            "startTime": startTime,
            "endTime": endTime,
            "contactEmail": contactEmail,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        let db = Firestore.firestore()
        _ = try await db.collection("listings").addDocument(data: listing)
    }
}
