// AuthenticationClient.swift
import Foundation
import Combine

final class AuthenticationClient {
    static let shared = AuthenticationClient()
    
    private var currentUser: User?
    private let keychain = KeychainManager.shared
    private let backendService = BackendService.shared
    
    private init() {}
    
    func checkAuthentication() async -> Bool {
        // Check if we have a valid token
        guard let token = keychain.getToken() else {
            return false
        }
        
        // For now, if we have a token, consider user authenticated
        // In production, verify token with backend
        return true
    }
    
    func sendOTP(phoneNumber: String) async throws -> String {
        return try await backendService.sendOTP(phoneNumber: phoneNumber)
    }
    
    func verifyOTP(phoneNumber: String, code: String) async throws -> User {
        let user = try await backendService.verifyOTP(phoneNumber: phoneNumber, code: code)
        
        // Save token and user
        let token = "auth_token_\(user.id)"
        keychain.saveToken(token)
        self.currentUser = user
        
        return user
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func signOut() {
        currentUser = nil
        keychain.deleteToken()
    }
    
    private func verifyToken(_ token: String) async throws -> User {
        // In production, verify with backend
        // For now, return current user if token exists
        if let user = currentUser {
            return user
        }
        throw APIError.unauthorized
    }
}

// MARK: - Keychain Manager
final class KeychainManager {
    static let shared = KeychainManager()
    
    private let tokenKey = "com.communitycapital.authToken"
    
    private init() {}
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func deleteToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
