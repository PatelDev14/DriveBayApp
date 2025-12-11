//
//  ListingCardView.swift
//  DriveBayApp
//
//  Created by Dev Patel on 2025-12-10.
//

// Views/ListingCardView.swift
import SwiftUI

struct ListingCardView: View {
    let listing: Listing
    let isLoggedIn: Bool
    let onBook: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // MAIN CARD — LUXURY GLASS
            VStack(alignment: .leading, spacing: 16) {
                // Header: Location
                HStack(spacing: 12) {
                    Circle()
                        .fill(DriveBayTheme.accent.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundStyle(DriveBayTheme.accent)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Parking Spot")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        
                        Text("\(listing.address), \(listing.city), \(listing.state)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 8)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Description (if exists)
                if let desc = listing.description, !desc.isEmpty {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .italic()
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            Rectangle()
                                .frame(width: 4)
                                .foregroundStyle(DriveBayTheme.accent)
                        )
                        .padding(.horizontal, -4)
                }
                
                // Key Details
                VStack(spacing: 14) {
                    // RATE — HIGHLIGHTED LIKE REACT
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                        
                        Text("Hourly Rate")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", listing.rate))")
                            .font(.title2.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("/hr")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(16)
                    
                    // Date
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.cyan)
                        Text("Date:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Text(listing.formattedDate)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    // Time
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.purple)
                        Text("Available:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Text("\(listing.startTime) – \(listing.endTime)")
                            .font(.headline)
                            .foregroundStyle(DriveBayTheme.accent)
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color.white.opacity(0.08))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(DriveBayTheme.glassBorder.opacity(0.6)))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding(.horizontal)
            
            // GRADIENT BOOK BUTTON — EXACTLY LIKE REACT
            Button {
                onBook()
            } label: {
                Text(isLoggedIn ? "Request to Book" : "Log In to Book")
                    .font(.title3.bold())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [DriveBayTheme.accent, Color.indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: DriveBayTheme.glow, radius: 20, y: 10)
                    .scaleEffect(isLoggedIn ? 1.0 : 0.95)
                    .opacity(isLoggedIn ? 1.0 : 0.6)
            }
            .disabled(!isLoggedIn)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(Color.clear)
        .padding(.vertical, 8)
    }
}
