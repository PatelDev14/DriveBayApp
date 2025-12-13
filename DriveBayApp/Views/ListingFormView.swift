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

    // MARK: - Location Section
    private var locationSection: some View {
        SectionView(title: "Location Details", icon: "mappin.and.ellipse") {
            VStack(spacing: 20) {
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

