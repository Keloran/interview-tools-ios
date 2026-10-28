//
//  CSVImportTests.swift
//  InterviewsTests
//

import Foundation
import Testing
@testable import Interviews

@MainActor
struct CSVImportTests {

    @Test("Headers honour quotes, a BOM and Windows line endings")
    func testHeaders() {
        #expect(CSVImport.headers("\u{FEFF}Company,\"Job, title\",Date applied\r\nAcme,iOS,2026-10-01") == ["Company", "Job, title", "Date applied"])
        #expect(CSVImport.headers("\"Say \"\"hi\"\"\",Role\nx,y") == ["Say \"hi\"", "Role"])
        #expect(CSVImport.headers("\"Multi\nline\",Role\nx,y") == ["Multi\nline", "Role"])
        #expect(CSVImport.headers("").isEmpty)
    }

    @Test("Columns are guessed like the website does")
    func testGuess() {
        let mapping = CSVImport.guess(["Employer", "Role", "Date Applied", "URL", "Status", "End client", "Notes"])
        #expect(mapping == ImportMapping(company: 0, jobTitle: 1, applicationDate: 2, jobPostingLink: 3, outcome: 4, clientCompany: 5))
        #expect(CSVImport.requiredMapped(mapping))
        #expect(!CSVImport.requiredMapped(CSVImport.guess(["Employer", "Notes"])))
    }

    @Test("Unmapped columns are sent as null, as the server requires")
    func testMappingEncoding() throws {
        let body = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ImportRequest(csv: "a", mapping: ImportMapping(company: 0, jobTitle: 1, applicationDate: 2), action: "preview"))) as? [String: Any]
        let mapping = body?["mapping"] as? [String: Any]
        #expect(mapping?["company"] as? Int == 0)
        #expect(mapping?["outcome"] is NSNull)
        #expect(mapping?.count == 6)
        #expect(body?["action"] as? String == "preview")
    }

    @Test("The preview decodes with its counts")
    func testPlanDecode() throws {
        let json = #"{"rows": [{"line": 2, "company": "Acme", "jobTitle": "iOS", "applicationDate": "2026-10-01", "status": "duplicate", "reason": "Already recorded"}], "ready": 3, "duplicates": 1, "errors": 0, "imported": 0}"#
        let plan = try JSONDecoder().decode(APIImportPlan.self, from: Data(json.utf8))
        #expect(plan.ready == 3 && plan.rows.first?.reason == "Already recorded")
    }
}
