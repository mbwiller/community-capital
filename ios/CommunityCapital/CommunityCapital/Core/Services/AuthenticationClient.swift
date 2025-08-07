//
//  AuthenticationClient.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import Foundation

class AuthenticationClient {
    static let shared = AuthenticationClient()
    
    func checkAuthentication() async -> Bool {
        // Check if token exists in keychain
        return KeychainManager.shared.getToken() != nil
    }
}
