// Views/MyDrivewaysTab.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MyDrivewaysTab: View {
    @Environment(\.dismiss) private var dismiss
    @State private var listings: [Listing] = []
    @State private var selectedListing: Listing?
    @State private var showingEditForm = false
    @State private var listingToDelete: Listing?
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()

                if listings.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(listings) { listing in
                                drivewayCard(listing)
                                    .onTapGesture {
                                        selectedListing = listing
                                        showingEditForm = true
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Driveways")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.white.opacity(0.9))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedListing = nil
                        showingEditForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(DriveBayTheme.accent)
                            .shadow(color: DriveBayTheme.glow, radius: 12)
                    }
                }
            }
            .sheet(isPresented: $showingEditForm) {
                ListingFormView(editingListing: selectedListing)
                    .id(selectedListing?.id ?? "new")
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .alert("Delete Driveway?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let listing = listingToDelete {
                        deleteListingFromFirebase(listing)
                    }
                }
            } message: {
                Text("This driveway will be permanently removed.")
            }
            .onAppear {
                loadMyListings()
            }
            .onChange(of: showingEditForm) { _, closed in
                if !closed { loadMyListings() }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "car.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))

            VStack(spacing: 12) {
                Text("No driveways listed yet")
                    .font(.title2.bold())
                    .foregroundColor(.white.opacity(0.8))

                Text("Tap + to list your first spot and start earning!")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Driveway Card WITH DELETE BUTTON
    @ViewBuilder
    private func drivewayCard(_ listing: Listing) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header with Edit + Delete buttons
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.address)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text("\(listing.city), \(listing.state)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    HStack(spacing: 16) {
                        // Edit Button
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(DriveBayTheme.accent)
                            .shadow(color: DriveBayTheme.glow, radius: 10)

                        // DELETE BUTTON — GORGEOUS & DANGEROUS
                        Button {
                            listingToDelete = listing
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                                .shadow(color: .red.opacity(0.6), radius: 12)
                        }
                    }
                }

                // Date & Time
                HStack {
                    Label(listing.formattedDate, systemImage: "calendar")
                        .font(.subheadline.bold())
                        .foregroundColor(.cyan)

                    Spacer()

                    Label("\(listing.startTime) – \(listing.endTime)", systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                // Rate
                HStack {
                    Text("$\(String(format: "%.2f", listing.rate))/hour")
                        .font(.title2.bold())
                        .foregroundColor(.green)

                    Spacer()

                    Text("Available")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.3))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }

                // Description
                if let desc = listing.description, !desc.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(3)
                }

                // Contact
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.white.opacity(0.6))
                    Text(listing.contactEmail)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            }
            .padding(20)
        }
        .padding(.horizontal)
    }

    // MARK: - Delete from Firebase
    private func deleteListingFromFirebase(_ listing: Listing) {
        let id = listing.id

        Firestore.firestore()
            .collection("listings")
            .document(id)
            .delete { error in
                if let error = error {
                    print("Delete failed: \(error)")
                } else {
                    withAnimation {
                        listings.removeAll { $0.id == id }
                    }
                }
            }
    }

    // MARK: - Load Listings
    private func loadMyListings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("listings")
            .whereField("ownerId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self.listings = docs.compactMap { try? $0.data(as: Listing.self) }
            }
    }
}

#Preview {
    MyDrivewaysTab()
}
