import SwiftUI

// Stub — fully implemented in Task I3
struct WelcomeView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        VStack(spacing: 32) {
            Text("Welcome to BlakJaks")
                .font(.largeTitle.bold())
            Button("Sign In") {
                isAuthenticated = true
            }
            .padding()
            .background(Color("BrandGold"))
            .foregroundColor(.black)
            .cornerRadius(12)
        }
        .padding()
    }
}
