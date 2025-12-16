//
//  ClerkConfiguration.swift
//  Interviews
//
//  Created by keloran on 06/12/2025.
//

import Foundation

struct ClerkConfiguration {
    static let publishableKey = "pk_live_Y2xlcmsuaW50ZXJ2aWV3cy50b29scyQ"

    // This should match the domain where interviews.tools is hosted
    static let frontendAPI = "interviews.tools"

    // Use the same OAuth callback URL as the web app
    static let redirectURL = "https://clerk.interviews.tools/v1/oauth_callback"
}
