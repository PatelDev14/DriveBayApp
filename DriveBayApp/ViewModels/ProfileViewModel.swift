// ViewModels/ProfileViewModel.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import FirebaseStorage

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
    
    private let db = Firestore.firestore()
    
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
                
                if let urlString = data["photoURL"] as? String, !urlString.isEmpty {
                    self?.profileImageUrl = urlString
                } else {
                    self?.profileImageUrl = nil
                }
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
