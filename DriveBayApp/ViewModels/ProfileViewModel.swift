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
    @Published var profileImageUrl: String? = ""
    
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
    func uploadProfileImage(_ image: UIImage) async {
        isSaving = true
        guard let uid = Auth.auth().currentUser?.uid,
              let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        
        do {
            _ = try await storageRef.putDataAsync(imageData)
            let url = try await storageRef.downloadURL()
            self.profileImageUrl = url.absoluteString
            
            // Save the URL to the user's Firestore document
            try await Firestore.firestore().collection("users").document(uid).setData([
                "profileImageUrl": url.absoluteString
            ], merge: true)
            
            isSaving = false
        } catch {
            print("Error uploading image: \(error)")
            isSaving = false
        }
    }
}


