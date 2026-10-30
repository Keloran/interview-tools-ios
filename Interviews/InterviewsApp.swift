//
//  InterviewsApp.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import OSLog
import SwiftData
import ClerkKit
import FlagsGG
import Bugfixes

@main
struct InterviewsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var modelContainer: ModelContainer?
    /// Whose store is open: a Clerk user id, or nil for guest mode
    @State private var storeOwner: String?
    @State private var showLaunchScreen = true
    private let flagsClient: Flags?
    
    init() {
        // First, so a crash during the rest of startup is still caught. The key is public; empty keeps reporting off
        Bugfixes.start(key: "", environment: "production")
        // Once, before anything reads Clerk.shared; it restores the saved session and loads by itself
        Clerk.configure(publishableKey: ClerkConfiguration.publishableKey)
        do {
            flagsClient = try Flags.builder().withAuth(Auth(
                projectId: "198ba0bd-e7e1-4219-beee-9bd82de0e03c",
                agentId: "8b98066c-9017-460f-8c0f-beb92392eb14",
                environmentId: "07a3b112-3bdc-4b1f-a096-ae2bdf21ad67"
            )).build()
        } catch {
            #if DEBUG
            appLog.error("Failed to initialize Flags client: \(String(describing: error))")
            #endif
            flagsClient = nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app - always present after launch screen
                if let modelContainer {
                    ContentView()
                        // A new account gets a fresh view tree, so nothing from the last one lingers
                        .id(storeOwner ?? "guest")
                        .modelContainer(modelContainer)
                        .environment(Clerk.shared)
                        .onOpenURL { url in
                            // Log the callback URL for debugging
                            appLog.notice("Received URL callback: \(url)")

                            // Clerk should handle the OAuth callback automatically
                            // when it detects the matching URL scheme
                        }
                        .appUpdateAlertOnLaunch()
                        .modifier(FlagsAgentModifier(client: flagsClient))
                        .task {
                            // no-op; initialization handled below
                        }
                }
                
                // Launch screen overlay - dismisses quickly
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1) // Ensure it's on top
                        .task {
                            // Show launch screen for minimum time
                            try? await Task.sleep(for: .milliseconds(1200))
                            
                            withAnimation(.easeOut(duration: 0.5)) {
                                showLaunchScreen = false
                            }
                        }
                }
            }
            .task {
                // The saved session (if any) picks the store; a sign-in that lands later swaps it below
                openStore(for: Clerk.shared.user?.id)
            }
            .onChange(of: Clerk.shared.user?.id) { _, userId in
                guard modelContainer != nil else { return }
                openStore(for: userId)
            }
        }
    }
    
    @MainActor
    private func openStore(for userId: String?) {
        guard modelContainer == nil || userId != storeOwner else { return }
        do {
            modelContainer = try AccountStore.container(for: userId)
            storeOwner = userId
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

// MARK: - App Delegate for Orientation Lock
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // Lock to portrait orientation only
        return .portrait
    }
}
private extension View {
    @ViewBuilder
    func ifLet<T>(_ value: T?, transform: (Self, T) -> some View) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}

private struct FlagsAgentModifier: ViewModifier {
    let client: FlagsClient?
    func body(content: Content) -> some View {
        if let client {
            content.flagsAgent(client)
        } else {
            content
        }
    }
}
