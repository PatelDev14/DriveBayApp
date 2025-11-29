// Views/ListingFormView.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Header
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.indigo)
                        .shadow(color: .indigo.opacity(0.3), radius: 20, y: 10)

                    VStack(spacing: 8) {
                        Text("List Your Driveway")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)

                        Text("Earn money by renting out your parking spot")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)

                // MARK: - Error Banner
                if let error = viewModel.validationError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(16)
                    .background(.red.opacity(0.15))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.red.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }

                // MARK: - Sections
                locationSection
                availabilitySection
                detailsSection

                // MARK: - Submit Button
                Button {
                    viewModel.submit()
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text(viewModel.isLoading ? "Submitting..." : "Add My Driveway")
                            .font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(color: .purple.opacity(0.5), radius: 20, y: 10)
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 20)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("List Your Driveway")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .fontWeight(.medium)
                .foregroundColor(.indigo)
            }
        }
        .onAppear {
            viewModel.onSuccess = { dismiss() }
        }
    }

    // MARK: - Location Section
    private var locationSection: some View {
        SectionView(title: "Location Details", icon: "mappin.and.ellipse") {
            VStack(spacing: 16) {
                InputField(title: "Street Address*", placeholder: "123 Ocean Drive", text: $viewModel.address)
                InputField(title: "City*", placeholder: "Miami", text: $viewModel.city)

                HStack(spacing: 16) {
                    InputField(title: "State*", placeholder: "FL", text: $viewModel.state)
                    InputField(title: "Zip Code*", placeholder: "33139", text: $viewModel.zipCode)
                }

                Picker("Country", selection: $viewModel.country) {
                    Text("USA").tag("USA")
                    Text("Canada").tag("Canada")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Availability Section
//    private var availabilitySection: some View {
//        SectionView(title: "Availability & Pricing", icon: "calendar.badge.clock") {
//            VStack(spacing: 20) {
//                HStack(spacing: 16) {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Date")
//                            .font(.subheadline.bold())
//                        DatePicker("", selection: $viewModel.date, displayedComponents: .date)
//                            .datePickerStyle(.compact)
//                            .labelsHidden()
//                            .padding(12)
//                            .background(.ultraThinMaterial)
//                            .cornerRadius(14)
//                    }
//
//                    InputField(title: "Start Time*", placeholder: "09:00", text: $viewModel.startTime)
//                        .keyboardType(.numbersAndPunctuation)
//
//                    InputField(title: "End Time*", placeholder: "18:00", text: $viewModel.endTime)
//                        .keyboardType(.numbersAndPunctuation)
//                }
//
//                VStack(alignment: .leading, spacing: 12) {
//                    HStack {
//                        Image(systemName: "dollarsign.circle.fill")
//                            .foregroundColor(.green)
//                            .font(.title2)
//                        Text("Rate per Hour")
//                            .font(.headline)
//                    }
//
//                    HStack {
//                        TextField("$10.00", text: $viewModel.rate)
//                            .keyboardType(.decimalPad)
//                            .frame(width: 120)
//                            .padding(14)
//                            .background(.ultraThinMaterial)
//                            .cornerRadius(14)
//                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary))
//
//                        Spacer()
//
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 12) {
//                                ForEach(ListingFormViewModel.presetRates, id: \.self) { rate in
//                                    Button("$\(rate)") {
//                                        viewModel.rate = String(rate) + ".00"
//                                    }
//                                    .font(.caption.bold())
//                                    .padding(.horizontal, 20)
//                                    .padding(.vertical, 12)
//                                    .background(
//                                        viewModel.rate.hasPrefix(String(rate)) ?
//                                        Color.indigo : Color(.systemGray5)
//                                    )
//                                    .foregroundColor(.white)
//                                    .cornerRadius(14)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    private var availabilitySection: some View {
        SectionView(title: "Availability & Pricing", icon: "calendar.badge.clock") {
            VStack(spacing: 24) {
                
                // MARK: - Date Picker (Full Width)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.subheadline.bold())
                    DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                }

//                // MARK: - Start & End Time (Side by Side)
//                HStack(spacing: 16) {
//                    InputField(title: "Start Time*", placeholder: "09:00", text: $viewModel.startTime)
//                        .keyboardType(.numbersAndPunctuation)
//
//                    InputField(title: "End Time*", placeholder: "18:00", text: $viewModel.endTime)
//                        .keyboardType(.numbersAndPunctuation)
//                }
                
                // MARK: - Start & End Time with Gorgeous 24-Hour Clock Picker
                HStack(spacing: 20) {
                    ClockPicker(title: "Start Time", selection: $viewModel.startTime)
                    ClockPicker(title: "End Time", selection: $viewModel.endTime)
                }
                .padding(.horizontal, 4)

                // MARK: - Rate per Hour
                VStack(alignment: .leading, spacing: 10) {
                    Text("Rate per Hour")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))

                    Menu {
                        ForEach(ListingFormViewModel.presetRates, id: \.self) { rate in
                            Button("$\(rate)") {
                                viewModel.rate = "\(rate).00"
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.rate.isEmpty ? "Select rate" : "$\(viewModel.rate)")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.2))
                        )
                    }
                }

            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        SectionView(title: "Details & Contact", icon: "info.circle.fill") {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.headline)

                    TextEditor(text: $viewModel.description)
                        .frame(height: 110)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary))

                    HStack {
                        Spacer()
                        Text("\(viewModel.description.count)/200")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                InputField(title: "Contact Email*", placeholder: "you@example.com", text: $viewModel.contactEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Used only for booking notifications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Reusable Components
    @ViewBuilder
    private func SectionView<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.indigo)
                Text(title)
                    .font(.title3.bold())
            }
            .padding(.horizontal, 4)

            VStack(spacing: 16) {
                content()
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
            .padding(.horizontal, 4)
        }
    }

    private func InputField(title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary))
        }
    }
}

#Preview {
    NavigationStack {
        ListingFormView()
    }
}
