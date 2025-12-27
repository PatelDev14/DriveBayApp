//
//  DrivewaysSearchViewModel.swift
//  DriveBayApp
//
//  Created by Dev Patel on 2025-12-26.
//

import Foundation
import Combine
import FirebaseFirestore

class DrivewaysSearchViewModel: ObservableObject {
    @Published var city = ""
    @Published var state = ""
    @Published var country = ""
    @Published var zipCode = ""
    
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSearch = false
    
    func searchDriveways() {
        // At least one field must be filled
        guard !(city.isEmpty && state.isEmpty && country.isEmpty && zipCode.isEmpty) else {
            errorMessage = "Please enter at least one search field."
            return
        }
        
        errorMessage = nil
        isLoading = true
        didSearch = true
        
        let db = Firestore.firestore()
        var query: Query = db.collection("listings")
            .whereField("isActive", isEqualTo: true)
        
        if !city.isEmpty {
            query = query.whereField("city", isEqualTo: city.trimmingCharacters(in: .whitespaces).capitalized)
        }
        if !state.isEmpty {
            query = query.whereField("state", isEqualTo: state.trimmingCharacters(in: .whitespaces).uppercased())
        }
        if !country.isEmpty {
            query = query.whereField("country", isEqualTo: country.trimmingCharacters(in: .whitespaces).uppercased())
        }
        if !zipCode.isEmpty {
            query = query.whereField("zipCode", isEqualTo: zipCode.trimmingCharacters(in: .whitespaces))
        }
        
        Task {
            do {
                let snapshot = try await query
                    .order(by: "createdAt", descending: true)
                    .limit(to: 50)
                    .getDocuments()
                
                let results = snapshot.documents.compactMap { document in
                    try? document.data(as: Listing.self)
                }
                
                await MainActor.run {
                    self.listings = results
                    self.isLoading = false
                    
                    if results.isEmpty {
                        self.errorMessage = "No driveways found in that area."
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Search failed. Try again."
                    self.isLoading = false
                    print("Search error: \(error)")
                }
            }
        }
    }
}
