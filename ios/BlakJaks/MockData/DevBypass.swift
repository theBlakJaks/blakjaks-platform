// DevBypass.swift
// LOCAL DEVELOPMENT ONLY — never ships to production
// Gated by DEBUG flag so it is compiled out of Release/Staging/Production builds

#if DEBUG
enum DevBypass {
    static let enabled  = true
    static let email    = "admin@blakjaks.dev"
    static let password = "devpass123"
}
#endif
