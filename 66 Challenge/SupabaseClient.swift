import Foundation
import Supabase

enum SupabaseService {
    static let shared = SupabaseClient(
        supabaseURL: URL(string: "https://ygaksdnnlehqhtjkrftk.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlnYWtzZG5ubGVocWh0amtyZnRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg4NzAxNTUsImV4cCI6MjA1NDQ0NjE1NX0.qLz475TZ6ylK5N7M0BqLUlh4x8wJywo7HH5wm0iAuOM",
        options: SupabaseClientOptions(
            auth: .init(
                flowType: .implicit,
                autoRefreshToken: true
            )
        )
    )
} 
