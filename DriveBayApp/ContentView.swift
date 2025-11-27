import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
            Text("Welcome to DriveBay!")
                .font(.largeTitle)
            Button("Sign Out") {
                try? authService.signOut()
            }
            .padding()
        }
    }
}
