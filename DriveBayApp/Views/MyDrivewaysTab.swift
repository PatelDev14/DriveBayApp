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
    @State private var showingRequests = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()

                if listings.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) { 
                            ForEach(listings) { listing in
                                drivewayCard(listing)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("My Driveways")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedListing = nil
                        showingEditForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DriveBayTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingEditForm) {
                ListingFormView(editingListing: selectedListing)
                    .id(selectedListing?.id ?? "new")
            }
            .sheet(isPresented: $showingRequests) {
                if let listing = selectedListing {
                    RequestsView(listing: listing)
                }
            }
            .alert("Delete Driveway?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let listing = listingToDelete {
                        deleteListingFromFirebase(listing)
                    }
                }
            } message: {
                Text("This driveway and all its data will be permanently removed.")
            }
            .onAppear(perform: loadMyListings)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Standardized Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(DriveBayTheme.glow.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Image(systemName: "house.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(colors: [DriveBayTheme.accent, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: DriveBayTheme.glow.opacity(0.5), radius: 20)
            }

            VStack(spacing: 8) {
                Text("No Driveways Listed")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("Tap the plus icon to start earning from your empty spot.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
        }
    }

    // MARK: - Refined Driveway Card
    @ViewBuilder
    private func drivewayCard(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.address)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(listing.city), \(listing.state)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Refined Action Buttons (Matching Requests Style)
                HStack(spacing: 10) {
                    Button {
                        selectedListing = listing
                        showingEditForm = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        listingToDelete = listing
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.7))
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }

            // Availability Info
            HStack {
                Label(listing.formattedDate, systemImage: "calendar")
                Spacer()
                Label("\(listing.startTime) – \(listing.endTime)", systemImage: "clock.fill")
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(DriveBayTheme.accent)

            Divider().background(Color.white.opacity(0.1))

            // Footer: Rate & Requests Action
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hourly Rate")
                        .font(.system(size: 10, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundColor(.white.opacity(0.4))
                    Text("$\(String(format: "%.2f", listing.rate))")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // IMPORTANT: Quick access to requests for THIS specific driveway
                Button {
                    selectedListing = listing
                    showingRequests = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text("Requests")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(DriveBayTheme.accent.opacity(0.15))
                    .foregroundColor(DriveBayTheme.accent)
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(LinearGradient(colors: [DriveBayTheme.glassBorder.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Logic
    private func deleteListingFromFirebase(_ listing: Listing) {
        // 1. Safely unwrap the optional ID
        guard let docId = listing.id else {
            print("Error: Listing has no document ID")
            return
        }

        // 2. Use the unwrapped 'docId' for Firestore
        Firestore.firestore().collection("listings").document(docId).delete { error in
            if let error = error {
                print("Error removing document: \(error.localizedDescription)")
            } else {
                // 3. Update UI on success
                DispatchQueue.main.async {
                    withAnimation {
                        listings.removeAll { $0.id == listing.id }
                    }
                }
            }
        }
    }

    private func loadMyListings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("listings")
            .whereField("ownerId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                self.listings = snapshot?.documents.compactMap { try? $0.data(as: Listing.self) } ?? []
            }
    }
}
