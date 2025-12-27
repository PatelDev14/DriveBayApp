// Views/DrivewaysSearchView.swift
import SwiftUI
import FirebaseFirestore

struct DrivewaysSearchView: View {
    @StateObject private var viewModel = DrivewaysSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                
                VStack(spacing: 24) {
                    Text("Search Driveways")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(spacing: 14) {
                        GlassField(placeholder: "City", icon: "building.2.fill", text: $viewModel.city)
                        GlassField(placeholder: "State / Province", icon: "map.fill", text: $viewModel.state)
                        GlassField(placeholder: "Country", icon: "globe", text: $viewModel.country)
                        GlassField(placeholder: "Zip / Postal Code (optional)", icon: "envelope.fill", text: $viewModel.zipCode)
                    }
                    .padding(.horizontal, 24)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    Button("Search") {
                        viewModel.searchDriveways()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DriveBayTheme.accent)
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(20)
                    .shadow(color: DriveBayTheme.glow.opacity(0.7), radius: 16, y: 8)
                    .padding(.horizontal, 40)
                    .disabled(viewModel.isLoading)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                    
                    if viewModel.didSearch && viewModel.listings.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("No driveways found")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Try broadening your search or check back soon.")
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Driveways Search")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .fontWeight(.medium)
                }
            }
            .navigationDestination(for: SearchResultsWrapper.self) { wrapper in
                ResultsView(listings: wrapper.listings)
            }
            .onReceive(viewModel.$listings) { newListings in
                if !newListings.isEmpty {
                    navigationPath.append(SearchResultsWrapper(listings: newListings))
                }
            }
        }
    }
}

// MARK: - Wrapper for Navigation (uses UUID to avoid Hashable/Equatable on Listing)
private struct SearchResultsWrapper: Identifiable, Hashable {
    let id = UUID()
    let listings: [Listing]
    
    static func == (lhs: SearchResultsWrapper, rhs: SearchResultsWrapper) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Glass Field with Icon
private struct GlassField: View {
    let placeholder: String
    let icon: String?
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20)
            }
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                .foregroundColor(.white)
                .autocapitalization(.words)
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(DriveBayTheme.glassBorder.opacity(0.6), lineWidth: 1)
        )
    }
}
