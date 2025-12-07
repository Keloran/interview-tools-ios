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
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let modelContainer {
                    ContentView()
                        .modelContainer(modelContainer)
                        .onOpenURL { url in
                            // Log the callback URL for debugging
                            print("Received URL callback: \(url)")

                            // Clerk should handle the OAuth callback automatically
                            // when it detects the matching URL scheme
                        }
                } else {
                    // Show loading screen while model container initializes
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .task {
                        // Create container on background thread to avoid blocking UI
                        await initializeModelContainer()
                    }
                }
            }
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

            // Set the container immediately so UI can show
            self.modelContainer = container
            
            // Seed default data in the background using a background context
            Task.detached(priority: .medium) {
                let backgroundContext = ModelContext(container)
                await DataSeeder.seedDefaultData(context: backgroundContext)
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
