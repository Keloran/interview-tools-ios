//
//  AccountStore.swift
//  Interviews
//

import Foundation
import SwiftData
import Clerk

/// One SwiftData store per signed-in account, plus the guest store, so one account's cached history can never
/// show up under another account or in guest mode.
@MainActor
enum AccountStore {
    static let schema = Schema([Interview.self, Company.self, Stage.self, StageMethod.self])

    /// Guest mode keeps the original default store, so data people already have on the phone stays where it is
    static func configuration(for userId: String?) -> ModelConfiguration {
        guard let userId else { return ModelConfiguration(schema: schema) }
        let safeId = String(userId.filter { $0.isLetter || $0.isNumber || $0 == "_" })
        return ModelConfiguration(schema: schema, url: URL.applicationSupportDirectory.appending(path: "account-\(safeId).store"))
    }

    static func container(for userId: String?) throws -> ModelContainer {
        let container = try ModelContainer(for: schema, configurations: [configuration(for: userId)])
        if userId == nil {
            // Before stores were per account, the default store also cached whoever was signed in.
            // That's server data (it has an id), so it goes; guest data stays.
            try? DatabaseCleanup.removeSyncedData(context: container.mainContext)
        }
        DataSeeder.seedDefaultData(context: container.mainContext)
        return container
    }

    /// Interviews added in guest mode that haven't been added to an account
    static func guestInterviewCount() -> Int {
        guard let guest = try? ModelContainer(for: schema, configurations: [configuration(for: nil)]) else { return 0 }
        return (try? guest.mainContext.fetchCount(FetchDescriptor<Interview>(predicate: #Predicate { $0.id == nil }))) ?? 0
    }

    /// Only when the person chooses to: send guest interviews to the signed-in account, then remove them from
    /// the guest store. Returns how many failed; those stay in guest mode to try again.
    static func importGuestInterviews(using syncService: SyncService) async -> Int {
        guard let guest = try? ModelContainer(for: schema, configurations: [configuration(for: nil)]) else { return 0 }
        let context = guest.mainContext
        let interviews = (try? context.fetch(FetchDescriptor<Interview>(predicate: #Predicate { $0.id == nil }))) ?? []
        var failed = 0
        for interview in interviews {
            do {
                _ = try await syncService.pushInterview(interview)
                context.delete(interview)
                try context.save()
            } catch {
                failed += 1
            }
        }
        return failed
    }
}

/// The signed-in session's token, fetched per request so a long-lived screen never sends an expired one
/// and nothing is sent after sign-out
@MainActor
enum AuthToken {
    static func current() async -> String? {
        try? await Clerk.shared.session?.getToken()?.jwt
    }
}
