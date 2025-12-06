//
//  AuthenticationManager.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import Foundation
import Combine
// TODO: Uncomment when Clerk package is added
// import Clerk

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isAuthenticated = false
    @Published var sessionToken: String?
    @Published var userId: String?
    @Published var userEmail: String?

    private init() {
        // TODO: Initialize Clerk when SDK is added
        // Task {
        //     await checkAuthStatus()
        // }
    }

    // MARK: - Public Methods

    func signIn() async throws {
        // TODO: Implement Clerk sign-in
        // This will show Clerk's pre-built sign-in UI
        // Example:
        // try await Clerk.shared.signIn()
        // await updateAuthState()

        // Temporary placeholder
        throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Clerk SDK not yet integrated. Add the Clerk package first."
        ])
    }

    func signOut() async {
        // TODO: Implement Clerk sign-out
        // Example:
        // await Clerk.shared.signOut()

        isAuthenticated = false
        sessionToken = nil
        userId = nil
        userEmail = nil

        Task {
            await APIService.shared.setAuthToken(nil)
        }
    }

    func getSessionToken() async -> String? {
        // TODO: Get fresh session token from Clerk
        // Example:
        // let session = await Clerk.shared.session
        // return session?.getToken()

        return sessionToken
    }

    // MARK: - Private Methods

    private func checkAuthStatus() async {
        // TODO: Check if user is already signed in
        // Example:
        // if let session = await Clerk.shared.session,
        //    let user = await Clerk.shared.user {
        //     isAuthenticated = true
        //     userId = user.id
        //     userEmail = user.primaryEmailAddress?.emailAddress
        //     sessionToken = session.getToken()
        //
        //     await APIService.shared.setAuthToken(sessionToken)
        // }
    }

    private func updateAuthState() async {
        // TODO: Update state from Clerk session
        // Example:
        // guard let session = await Clerk.shared.session,
        //       let user = await Clerk.shared.user else {
        //     isAuthenticated = false
        //     return
        // }
        //
        // isAuthenticated = true
        // userId = user.id
        // userEmail = user.primaryEmailAddress?.emailAddress
        // sessionToken = session.getToken()
        //
        // await APIService.shared.setAuthToken(sessionToken)
    }
}

// MARK: - Temporary Mock for Development

extension AuthenticationManager {
    /// Temporary method for development/testing without Clerk
    func mockSignIn(email: String) {
        isAuthenticated = true
        userId = "mock_user_id"
        userEmail = email
        sessionToken = "mock_session_token"

        Task {
            await APIService.shared.setAuthToken(sessionToken)
        }
    }
}
