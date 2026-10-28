//
//  AccountStoreTests.swift
//  InterviewsTests
//

import Foundation
import Testing
import SwiftData
@testable import Interviews

@MainActor
struct AccountStoreTests {

    @Test("Each account gets its own store, separate from guest mode")
    func testStoresArePerAccount() {
        let guest = AccountStore.configuration(for: nil).url
        let a = AccountStore.configuration(for: "user_A1").url
        let b = AccountStore.configuration(for: "user_B2").url

        #expect(a != b)
        #expect(a != guest && b != guest)
        #expect(a.lastPathComponent == "account-user_A1.store")
        // The same account always reopens the same store, e.g. after an offline relaunch
        #expect(AccountStore.configuration(for: "user_A1").url == a)
    }

    @Test("A user id can't escape the store folder")
    func testUserIdIsSanitised() {
        let url = AccountStore.configuration(for: "../../evil/user_X").url
        #expect(url.lastPathComponent == "account-eviluser_X.store")
        #expect(url.deletingLastPathComponent() == AccountStore.configuration(for: "user_A1").url.deletingLastPathComponent())
    }

    @Test("A sync started for one account drops its results after a switch")
    func testSyncDropsResultsForAnotherAccount() throws {
        let container = try ModelContainer(for: AccountStore.schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let syncService = SyncService(modelContext: container.mainContext)

        // Started signed out (as tests run); still signed out: carry on
        syncService.currentOwner = { nil }
        #expect(throws: Never.self) { try syncService.ensureSameAccount() }

        // Someone signed in meanwhile: nothing from this sync is saved
        syncService.currentOwner = { "user_B2" }
        #expect(throws: CancellationError.self) { try syncService.ensureSameAccount() }
    }
}
