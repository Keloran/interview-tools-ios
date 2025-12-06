//
//  AuthenticationManager.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import Foundation
import Security

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isAuthenticated = false
    @Published var authToken: String?

    private let keychainService = "com.interviews.app"
    private let keychainAccount = "auth-token"

    private init() {
        loadToken()
    }

    // MARK: - Public Methods

    func setToken(_ token: String) {
        authToken = token
        isAuthenticated = true
        saveTokenToKeychain(token)

        Task {
            await APIService.shared.setAuthToken(token)
        }
    }

    func signOut() {
        authToken = nil
        isAuthenticated = false
        deleteTokenFromKeychain()

        Task {
            await APIService.shared.setAuthToken(nil)
        }
    }

    // MARK: - Keychain Helpers

    private func saveTokenToKeychain(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Failed to save token to keychain: \(status)")
        }
    }

    private func loadToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            authToken = token
            isAuthenticated = true

            Task {
                await APIService.shared.setAuthToken(token)
            }
        }
    }

    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        SecItemDelete(query as CFDictionary)
    }
}
