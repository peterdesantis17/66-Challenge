import Foundation
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    private let client = SupabaseService.shared
    
    init() {
        // Check for existing session
        Task {
            do {
                let session = try await client.auth.session
                isAuthenticated = session != nil
            } catch {
                print("No existing session")
            }
        }
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            try await client.auth.signUp(email: email, password: password)
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            try await client.auth.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        error = nil
        
        do {
            try await client.auth.signOut()
            isAuthenticated = false
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
} 