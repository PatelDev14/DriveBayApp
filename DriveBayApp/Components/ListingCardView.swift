import SwiftUI
struct ListingCardView: View {
    @State private var selectedListing: Listing? = nil
    
    let listing: Listing
    let isLoggedIn: Bool
    let onBook: () -> Void
    
    // Use a compact style for displaying within a list/carousel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. HEADER & DISTANCE
            HStack(spacing: 12) {
                Image(systemName: "car.side.fill")
                    .font(.title2)
                    .foregroundStyle(DriveBayTheme.accent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(listing.address)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(listing.city), \(listing.state) • \(formattedDistance)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Rate Tag (Prominent)
                Text("$\(String(format: "%.2f", listing.rate))/hr")
                    .font(.subheadline.bold())
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // 2. TIME & DESCRIPTION
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.purple)
                
                Text("\(listing.startTime) – \(listing.endTime)")
                    .font(.subheadline)
                    .foregroundColor(DriveBayTheme.accent)
                
                Spacer()
                
                Button {
                    onBook()
                    if isLoggedIn {
                            selectedListing = listing
                        }
                } label: {
                    HStack(spacing: 4) {
                        Text(isLoggedIn ? "Book" : "Log In")
                        Image(systemName: "arrow.forward.circle.fill")
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isLoggedIn ? DriveBayTheme.accent : Color.gray)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
                .disabled(!isLoggedIn)
                
            }
//            .sheet(item: $selectedListing) { listing in
//                BookingRequestView(listing: listing)
//            }
        }
        .padding(16)
        // Lighter background, no huge shadow or excessive padding
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.1)))
    }
    
    private var formattedDistance: String {
        guard let dist = listing.distanceFromUser else { return "Distance unknown" }
        return String(format: "%.1f km away", dist)
    }
}
