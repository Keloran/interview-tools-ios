//
//  APIServiceTests.swift
//  InterviewsTests
//
//  Created by keloran on 06/12/2025.
//

import Foundation
import Testing
@testable import Interviews

struct APIServiceTests {
    @Test func testAPIModelsDecoding() throws {
        let json = """
        {
            "id": 1,
            "jobTitle": "iOS Engineer",
            "interviewer": "Jane Smith",
            "company": {"id": 1, "name": "Apple"},
            "clientCompany": null,
            "stage": {"id": 1, "stage": "Phone Screen"},
            "stageMethod": {"id": 1, "method": "Video Call"},
            "applicationDate": "2025-12-01T00:00:00Z",
            "date": "2025-12-10T09:00:00Z",
            "deadline": null,
            "outcome": "SCHEDULED",
            "notes": null,
            "metadata": {"jobListing": "https://example.com/job"},
            "link": "https://zoom.us/j/123"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let interview = try decoder.decode(APIInterview.self, from: data)

        #expect(interview.id == 1)
        #expect(interview.jobTitle == "iOS Engineer")
        #expect(interview.interviewer == "Jane Smith")
        #expect(interview.company.name == "Apple")
        #expect(interview.stage?.stage == "Phone Screen")
        #expect(interview.stageMethod?.method == "Video Call")
        #expect(interview.outcome == "SCHEDULED")
        #expect(interview.link == "https://zoom.us/j/123")
    }

    @Test func testCreateInterviewRequestEncoding() throws {
        let request = CreateInterviewRequest(
            stage: "Phone Screen",
            companyName: "Google",
            clientCompany: nil,
            jobTitle: "Software Engineer",
            jobPostingLink: "https://careers.google.com/job1",
            date: "2025-12-15T10:00:00Z",
            deadline: nil,
            interviewer: "John Doe",
            locationType: "link",
            interviewLink: "https://meet.google.com/abc",
            notes: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(request)

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["stage"] as? String == "Phone Screen")
        #expect(json["companyName"] as? String == "Google")
        #expect(json["jobTitle"] as? String == "Software Engineer")
        #expect(json["interviewer"] as? String == "John Doe")
        #expect(json["locationType"] as? String == "link")
    }

    @Test func testAPIErrorTypes() throws {
        let unauthorizedError = APIError.unauthorized
        #expect(unauthorizedError.errorDescription == "Unauthorized. Please sign in.")

        let serverError = APIError.serverError("Not found")
        #expect(serverError.errorDescription == "Server error: Not found")

        let invalidResponse = APIError.invalidResponse
        #expect(invalidResponse.errorDescription == "Invalid response from server")
    }

    @Test func testAPICompanyDecoding() throws {
        let json = """
        {"id": 5, "name": "Meta"}
        """

        let data = json.data(using: .utf8)!
        let company = try JSONDecoder().decode(APICompany.self, from: data)

        #expect(company.id == 5)
        #expect(company.name == "Meta")
    }

    @Test func testAPIStageDecoding() throws {
        let json = """
        {"id": 2, "stage": "Technical Interview"}
        """

        let data = json.data(using: .utf8)!
        let stage = try JSONDecoder().decode(APIStage.self, from: data)

        #expect(stage.id == 2)
        #expect(stage.stage == "Technical Interview")
    }

    @Test func testAPIStageMethodDecoding() throws {
        let json = """
        {"id": 3, "method": "In Person"}
        """

        let data = json.data(using: .utf8)!
        let method = try JSONDecoder().decode(APIStageMethod.self, from: data)

        #expect(method.id == 3)
        #expect(method.method == "In Person")
    }

    @Test func testMetadataDecoding() throws {
        let json = """
        {"jobListing": "https://example.com/job", "location": "phone"}
        """

        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(APIMetadata.self, from: data)

        #expect(metadata.jobListing == "https://example.com/job")
        #expect(metadata.location == "phone")
    }

    @Test func testUpdateInterviewRequestEncoding() throws {
        let request = UpdateInterviewRequest(
            outcome: "PASSED",
            stage: nil,
            date: nil,
            deadline: nil,
            interviewer: nil,
            notes: nil,
            link: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["outcome"] as? String == "PASSED")
    }

    @Test func testInterviewWithNullableFields() throws {
        let json = """
        {
            "id": 1,
            "jobTitle": "Engineer",
            "interviewer": null,
            "company": {"id": 1, "name": "Company"},
            "clientCompany": null,
            "stage": null,
            "stageMethod": null,
            "applicationDate": "2025-12-01T00:00:00Z",
            "date": null,
            "deadline": null,
            "outcome": null,
            "notes": null,
            "metadata": null,
            "link": null
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let interview = try decoder.decode(APIInterview.self, from: data)

        #expect(interview.interviewer == nil)
        #expect(interview.clientCompany == nil)
        #expect(interview.stage == nil)
        #expect(interview.stageMethod == nil)
        #expect(interview.date == nil)
        #expect(interview.deadline == nil)
        #expect(interview.outcome == nil)
        #expect(interview.notes == nil)
        #expect(interview.metadata == nil)
        #expect(interview.link == nil)
    }
}
