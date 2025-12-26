//
//  InterviewsApp.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import SwiftData
import Clerk
import FlagsGG

@main
struct InterviewsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var modelContainer: ModelContainer?
    @State private var showLaunchScreen = true
    private let flagsClient: Flags?
    
    init() {
        do {
            flagsClient = try Flags.builder().withAuth(Auth(
                projectId: "198ba0bd-e7e1-4219-beee-9bd82de0e03c",
                agentId: "8b98066c-9017-460f-8c0f-beb92392eb14",
                environmentId: "07a3b112-3bdc-4b1f-a096-ae2bdf21ad67"
            )).build()
        } catch {
            #if DEBUG
            print("Failed to initialize Flags client: \(error)")
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
                        .modelContainer(modelContainer)
                        .onOpenURL { url in
                            // Log the callback URL for debugging
                            print("Received URL callback: \(url)")

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
                // Initialize container immediately (doesn't block launch screen)
                await initializeModelContainer()
            }
        }
    }
    
    @MainActor
    private func initializeModelContainer() async {
        // Quick initialization - just create the container
        let schema = Schema([
            Interview.self,
            Company.self,
            Stage.self,
            StageMethod.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try await Task.detached(priority: .high) {
                try ModelContainer(for: schema, configurations: [modelConfiguration])
            }.value

            // Set the container - this will show the main UI
            self.modelContainer = container
            
            // Seed default data synchronously before showing UI
            // This ensures stages and methods are available immediately
            let mainContext = container.mainContext
            DataSeeder.seedDefaultData(context: mainContext)
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
