//
//  InterviewsApp.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import SwiftUI
import SwiftData
import Clerk

@main
struct InterviewsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var modelContainer: ModelContainer?
    @State private var isInitialized = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isInitialized, let modelContainer {
                    ContentView()
                        .modelContainer(modelContainer)
                        .onOpenURL { url in
                            // Log the callback URL for debugging
                            print("Received URL callback: \(url)")

                            // Clerk should handle the OAuth callback automatically
                            // when it detects the matching URL scheme
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Show beautiful launch screen while initializing
                    LaunchScreenView()
                        .transition(.opacity)
                        .task {
                            // Create container on background thread to avoid blocking UI
                            await initializeModelContainer()
                        }
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isInitialized)
        }
    }
    
    @MainActor
    private func initializeModelContainer() async {
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

            // Set the container
            self.modelContainer = container
            
            // Seed default data in the background using a background context
            await Task.detached(priority: .medium) {
                let backgroundContext = ModelContext(container)
                await DataSeeder.seedDefaultData(context: backgroundContext)
            }.value
            
            // Add a minimum display time for the launch screen (feels more polished)
            // and ensures the animation is visible
            try? await Task.sleep(for: .milliseconds(800))
            
            // Mark as initialized - this will trigger the transition to ContentView
            withAnimation {
                isInitialized = true
            }
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
