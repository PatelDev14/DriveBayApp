// ViewModels/ProfileViewModel.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import FirebaseStorage
import FirebaseFunctions

enum PayoutStatus {
    case checking
    case verified
    case incomplete
    case notStarted
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var phoneNumber = ""
    @Published var email = ""
    
    @Published var isSaving = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var profileImageUrl: String? = nil
    @Published var stripeAccountId: String? = nil
    @Published var isLoading = false
    @Published var isStripeVerified = false
    @Published var payoutStatus: PayoutStatus = .checking
    
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    var displayName: String {
        if !firstName.isEmpty && !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        } else if !firstName.isEmpty {
            return firstName
        } else {
            return email.components(separatedBy: "@").first ?? "User"
        }
    }
    
    func loadProfile() {
        guard let user = Auth.auth().currentUser else { return }
        email = user.email ?? ""
        
        let ref = db.collection("users").document(user.uid)
        ref.getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                    return
                }
                
                guard let data = snapshot?.data() else { return }
                
                self?.firstName = data["firstName"] as? String ?? ""
                self?.lastName = data["lastName"] as? String ?? ""
                self?.phoneNumber = data["phoneNumber"] as? String ?? ""
                self?.stripeAccountId = data["stripeAccountId"] as? String
                
                if let id = self?.stripeAccountId, !id.isEmpty {
                                    self?.fetchStripeStatus()
                                }
                
                if let urlString = data["photoURL"] as? String, !urlString.isEmpty {
                    self?.profileImageUrl = urlString
                } else {
                    self?.profileImageUrl = nil
                }
            }
        }
    }
    
    func fetchStripeStatus() {
        guard let id = stripeAccountId, !id.isEmpty else {
            self.payoutStatus = .notStarted
            self.isStripeVerified = false
            print("fetchStripeStatus skipped – no ID")
            return
        }
        
        self.payoutStatus = .checking
        
        functions.httpsCallable("getStripeAccountStatus").call(["stripeAccountId": id]) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Stripe Status Error: \(error.localizedDescription)")
                    self?.payoutStatus = .incomplete
                    self?.isStripeVerified = false
                    self?.errorMessage = "Failed to check payout status"
                    return
                }
                
                guard let data = result?.data as? [String: Any] else {
                    print("Invalid response from getStripeAccountStatus")
                    self?.payoutStatus = .incomplete
                    self?.isStripeVerified = false
                    return
                }
                
                let verified = data["isEnabled"] as? Bool ?? false
                let detailsSubmitted = data["detailsSubmitted"] as? Bool ?? false
                
                let newStatus = (verified || detailsSubmitted) ? PayoutStatus.verified : .incomplete
                
                self?.isStripeVerified = verified || detailsSubmitted
                self?.payoutStatus = newStatus
                
                print("Stripe Sync - Enabled: \(verified), Submitted: \(detailsSubmitted), Status: \(newStatus)")
            }
        }
    }
 
    func saveProfile() {
        guard let user = Auth.auth().currentUser else { return }
        isSaving = true
        
        let data: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "firstName": firstName.isEmpty ? NSNull() : firstName,
            "lastName": lastName.isEmpty ? NSNull() : lastName,
            "phoneNumber": phoneNumber.isEmpty ? NSNull() : phoneNumber,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(user.uid).setData(data, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                } else {
                    self?.showSuccess = true
                }
            }
        }
    }
    
    func uploadProfilePhoto(_ data: Data) async {
        isSaving = true
        defer { isSaving = false }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }
        
        let storageRef = Storage.storage().reference().child("profilePhotos/\(uid).jpg")
        
        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = try await storageRef.putDataAsync(data, metadata: metadata)
            
            let url = try await storageRef.downloadURL()
            
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData(["photoURL": url.absoluteString], merge: true)
            
            self.profileImageUrl = url.absoluteString
            print("Photo uploaded successfully — will appear in a few seconds")
            
        } catch {
            print("Upload error: \(error)")
            errorMessage = "Failed to upload photo"
            showError = true
        }
    }
}
