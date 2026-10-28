//
//  SyncPagingTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

@MainActor
struct SyncPagingTests {

    private struct PageFailed: Error {}

    private static func interview(_ id: Int) throws -> APIInterview {
        let json = """
        {"id": \(id), "jobTitle": "Role \(id)", "company": {"id": 1, "name": "Co"}, "applicationDate": "2026-01-01T00:00:00.000Z"}
        """
        return try JSONDecoder().decode(APIInterview.self, from: Data(json.utf8))
    }

    /// A server holding `count` stages, answering take/skip like /api/interviews
    private static func server(_ count: Int) throws -> [APIInterview] {
        try (0..<count).map { try interview($0 + 1) }
    }

    private static func page(_ rows: [APIInterview], _ skip: Int, _ take: Int) -> [APIInterview] {
        Array(rows.dropFirst(skip).prefix(take))
    }

    @Test("Fetches past the old 200 limit", arguments: [201, 2_000, 2_001])
    func testFetchesEveryPage(count: Int) async throws {
        let rows = try Self.server(count)
        let all = try await SyncService.fetchAllInterviews(pageSize: 200) { Self.page(rows, $0, $1) }
        #expect(all.count == count)
        #expect(Set(all.map(\.id)).count == count)
    }

    @Test("Exact page multiple asks for one empty page and stops")
    func testExactMultiple() async throws {
        let rows = try Self.server(400)
        var calls = 0
        let all = try await SyncService.fetchAllInterviews(pageSize: 200) { skip, take in
            calls += 1
            return Self.page(rows, skip, take)
        }
        #expect(all.count == 400)
        #expect(calls == 3)
    }

    @Test("A row repeated across a page boundary is only kept once")
    func testDeduplicates() async throws {
        let rows = try Self.server(5)
        let all = try await SyncService.fetchAllInterviews(pageSize: 3) { skip, take in
            // the second page starts one row early, as if a row shifted
            Self.page(rows, skip == 0 ? 0 : skip - 1, take)
        }
        #expect(all.map(\.id) == [1, 2, 3, 4, 5])
    }

    @Test("A failed later page throws instead of returning a partial list")
    func testFailedPageThrows() async throws {
        let rows = try Self.server(450)
        await #expect(throws: PageFailed.self) {
            _ = try await SyncService.fetchAllInterviews(pageSize: 200) { skip, take in
                if skip > 0 { throw PageFailed() }
                return Self.page(rows, skip, take)
            }
        }
    }

    @Test("Cancellation stops before the next page")
    func testCancellation() async throws {
        let rows = try Self.server(1_000)
        let task = Task {
            try await SyncService.fetchAllInterviews(pageSize: 100) { skip, take in
                if skip > 0 { withUnsafeCurrentTask { $0?.cancel() } }
                return Self.page(rows, skip, take)
            }
        }
        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
    }
}
