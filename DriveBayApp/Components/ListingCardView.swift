// Components/ListingCardView.swift
import SwiftUI

struct ListingCardView: View {
    let listing: Listing
    let isLoggedIn: Bool
    let onBook: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            Divider().background(Color.white.opacity(0.1))
            timeAndDescriptionSection
            bookButtonSection
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(DriveBayTheme.glassBorder.opacity(0.6), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.address)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(listing.city), \(listing.state)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("$\(String(format: "%.2f", listing.rate))")
                    .font(.title3.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("/hr")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.15))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.green.opacity(0.4)))
        }
    }
    
    private var timeAndDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.purple)
                
                Text("\(listing.startTime) – \(listing.endTime)")
                    .font(.subheadline)
                    .foregroundStyle(DriveBayTheme.accent)
                
                Spacer()
                
                if let distance = listing.distanceFromUser {
                    Text(String(format: "%.1f km away", distance))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            if let description = listing.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
    }
    
    private var bookButtonSection: some View {
        BookButton(isLoggedIn: isLoggedIn, action: onBook)
    }
}

// MARK: - Book Button (Inside ListingCardView.swift)
// Inside ListingCardView.swift
private struct BookButton: View {
    let isLoggedIn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            print("Triggering booking for listing...") // Debug console check
            action()
        }) {
            HStack {
                Text(isLoggedIn ? "Request to Book" : "Log In to Book")
                    .font(.headline)
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isLoggedIn ? DriveBayTheme.accent : Color.gray
            )
            .cornerRadius(16)
        }
        .contentShape(Rectangle())
        .disabled(!isLoggedIn)
    }
}
