// Views/MyBookingsTab.swift
import SwiftUI

struct MyBookingsTab: View {
    @Environment(\.dismiss) private var dismiss  // ← THIS MAKES THE BACK BUTTON WORK
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(DriveBayTheme.accent)
                        .shadow(color: DriveBayTheme.glow, radius: 30)
                    
                    Text("My Bookings")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your upcoming and past bookings will appear here.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()  // ← GOES BACK TO CHATVIEW PERFECTLY
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .fontWeight(.medium)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
