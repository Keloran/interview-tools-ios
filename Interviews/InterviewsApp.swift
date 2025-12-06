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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Interview.self,
            Company.self,
            Stage.self,
            StageMethod.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Seed default data on first launch
            DataSeeder.seedDefaultData(context: container.mainContext)

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Log the callback URL for debugging
                    print("Received URL callback: \(url)")

                    // Clerk should handle the OAuth callback automatically
                    // when it detects the matching URL scheme
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
