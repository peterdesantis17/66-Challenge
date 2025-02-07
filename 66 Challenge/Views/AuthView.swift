import SwiftUI

struct AuthView: View {
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isLogin ? "Login" : "Sign Up")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
            if authManager.error != nil {
                Text(authManager.error!)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    if isLogin {
                        await authManager.signIn(email: email, password: password)
                    } else {
                        await authManager.signUp(email: email, password: password)
                    }
                }
            }) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text(isLogin ? "Login" : "Sign Up")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
            
            Button(isLogin ? "Need an account? Sign Up" : "Have an account? Login") {
                isLogin.toggle()
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
} 