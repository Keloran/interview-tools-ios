//
//  DataSeeder.swift
//  Interviews
//
//  Created by keloran on 05/12/2025.
//

import Foundation
import SwiftData

struct DataSeeder {
    @MainActor
    static func seedDefaultData(context: ModelContext) {
        // Check if data already exists
        let stageDescriptor = FetchDescriptor<Stage>()
        let methodDescriptor = FetchDescriptor<StageMethod>()

        do {
            let existingStages = try context.fetch(stageDescriptor)
            let existingMethods = try context.fetch(methodDescriptor)

            // Only seed if no data exists
            if existingStages.isEmpty {
//                print("📦 Seeding default stages...")
                seedStages(context: context)
            } else {
                print("✅ Stages already exist, skipping seed")
            }

            if existingMethods.isEmpty {
//                print("📦 Seeding default methods...")
                seedStageMethods(context: context)
            } else {
                print("✅ Methods already exist, skipping seed")
            }

            try context.save()
//            print("✅ Default data seeding complete")
        } catch {
            print("❌ Error seeding data: \(error)")
        }
    }

    private static func seedStages(context: ModelContext) {
        let defaultStages = [
            "Applied",
            "Phone Screen",
            "First Stage",
            "Second Stage",
            "Technical Test",
            "Technical Interview",
            "Third Stage",
            "Fourth Stage",
            "Final Stage"
        ]

        for stageName in defaultStages {
            let stage = Stage(stage: stageName)
            context.insert(stage)
        }
    }

    private static func seedStageMethods(context: ModelContext) {
        let defaultMethods = [
            "Video Call",
            "Phone",
            "In Person",
            "Take Home Test",
            "Live Coding"
        ]

        for methodName in defaultMethods {
            let method = StageMethod(method: methodName)
            context.insert(method)
        }
    }
}
