// Views/MessageRowView.swift (or placed inside ChatView)
import SwiftUI
import UIKit


struct MessageRowView: View {
    @ObservedObject var viewModel: ChatViewModel // Or pass dependencies like isLoggedIn
    let message: ChatMessage
    
    // You'll need access to the current logged-in state to handle the button logic
    @Binding var isLoggedIn: Bool
    
    // Determine alignment (User = trailing, Model/System = leading)
    private var isUser: Bool { message.role == .user }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                
                // 💡 THE CRITICAL LOGIC: Check for listings
                if let listings = message.listings, !listings.isEmpty {
                    
                    // --- A. RENDER LISTING CARDS (New Logic) ---
                    // Display an initial greeting if needed
                    Text("Found \(listings.count) nearby driveways! Check these out:")
                        .font(.subheadline)
                        .foregroundColor(isUser ? .white.opacity(0.8) : .gray)
                        .padding(.horizontal, 16)
                    
                    // Display the list of cards
                    ForEach(listings) { listing in
                        ListingCardView(
                            listing: listing,
                            isLoggedIn: isLoggedIn,
                            onBook: {
                                // TODO: Handle the booking action, e.g., navigate to a booking screen
                                print("Attempting to book: \(listing.address)")
                            }
                        )
                        // This padding helps stack the cards nicely
                        .padding(.vertical, 4)
                    }
                    
                } else {
                    
                    // --- B. RENDER REGULAR TEXT MESSAGE (Old Logic) ---
                    Text(message.content)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            isUser
                                ? DriveBayTheme.accent.opacity(0.8) // User bubble color
                                : Color.gray.opacity(0.25) // Model/System bubble color
                        )
                        .foregroundColor(.white)
                        .cornerRadius(18, corners: isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                }
            }
            
            if !isUser { Spacer() }
        }
    }
}
