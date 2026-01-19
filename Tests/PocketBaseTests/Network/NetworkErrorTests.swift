//
//  NetworkErrorTests.swift
//  PocketBase
//
//  Created by Claude on 2026-01-18.
//

import Foundation
import Testing
import TestUtilities
@testable import PocketBase

@Suite("NetworkError")
struct NetworkErrorTests {

    // MARK: - Invalid Request Errors

    @Suite("Invalid Request Reasons")
    struct InvalidRequestReasonTests {

        @Test("Each reason has a description")
        func reasonDescriptions() {
            let reasons: [NetworkError.InvalidRequestReason] = [
                .missingURL,
                .missingMethod,
                .getRequestWithBody,
                .missingParameters,
                .missingHeaders,
                .invalidJSONBody,
                .invalidURLRequest
            ]

            for reason in reasons {
                #expect(reason.errorDescription != nil)
                #expect(!reason.errorDescription!.isEmpty)
            }
        }

        @Test("InvalidRequest error description includes reason")
        func invalidRequestDescription() {
            let error = NetworkError.invalidRequest(reason: .missingURL)
            let description = error.errorDescription

            #expect(description != nil)
            #expect(description!.contains("Missing URL"))
        }
    }

    // MARK: - Invalid Response Errors

    @Suite("Invalid Response Reasons")
    struct InvalidResponseReasonTests {

        @Test("Each reason has a description")
        func reasonDescriptions() {
            let reasons: [NetworkError.InvalidResponseReason] = [
                .failedToParseInvalidFilterErrorResponse,
                .failedToParseUnauthorizedErrorResponse,
                .failedToParseNotFoundErrorResponse,
                .unexpectedStatusCode(500)
            ]

            for reason in reasons {
                #expect(reason.errorDescription != nil)
                #expect(!reason.errorDescription!.isEmpty)
            }
        }

        @Test("Unexpected status code includes code in description")
        func unexpectedStatusCodeDescription() {
            let reason = NetworkError.InvalidResponseReason.unexpectedStatusCode(503)
            let description = reason.errorDescription

            #expect(description != nil)
            #expect(description!.contains("503"))
        }
    }

    // MARK: - Error Description Tests

    @Suite("Error Descriptions")
    struct ErrorDescriptionTests {

        @Test("Unknown response has description")
        func unknownResponseDescription() {
            let response = URLResponse(
                url: .localhost,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            let error = NetworkError.unknownResponse(response)

            #expect(error.errorDescription != nil)
            #expect(error.errorDescription!.contains("Unknown response"))
        }

        @Test("Invalid response parses PocketBase error")
        func invalidResponseParsesPocketBaseError() throws {
            // Manually create JSON data since PocketBaseErrorResponse is Decodable only
            let json = """
            {
                "code": 400,
                "message": "Validation failed",
                "data": {
                    "email": {
                        "code": "validation_invalid_email",
                        "message": "Invalid email format"
                    }
                }
            }
            """
            let data = json.data(using: .utf8)!
            let httpResponse = HTTPURLResponse(
                url: .localhost,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!

            let error = NetworkError.invalidResponse(
                reason: .unexpectedStatusCode(400),
                statusCode: 400,
                data: data,
                response: httpResponse
            )

            let description = error.errorDescription
            #expect(description != nil)
            #expect(description!.contains("400"))
            #expect(description!.contains("Validation failed"))
        }

        @Test("Invalid response uses raw string when JSON parsing fails")
        func invalidResponseUsesRawString() {
            let data = "Raw error message".data(using: .utf8)!
            let httpResponse = HTTPURLResponse(
                url: .localhost,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!

            let error = NetworkError.invalidResponse(
                reason: .unexpectedStatusCode(500),
                statusCode: 500,
                data: data,
                response: httpResponse
            )

            let description = error.errorDescription
            #expect(description != nil)
            #expect(description!.contains("500"))
            #expect(description!.contains("Raw error message"))
        }

        @Test("Invalid filter error includes message")
        func invalidFilterDescription() {
            let response = PocketBaseErrorResponse(code: 400, message: "Invalid filter syntax", data: [:])
            let error = NetworkError.invalidFilter(response)

            let description = error.errorDescription
            #expect(description != nil)
            #expect(description!.contains("Invalid filter syntax"))
        }

        @Test("Unauthorized error includes message")
        func unauthorizedDescription() {
            let response = PocketBaseErrorResponse(code: 401, message: "Token expired", data: [:])
            let error = NetworkError.unauthorized(response)

            let description = error.errorDescription
            #expect(description != nil)
            #expect(description!.contains("Token expired"))
        }

        @Test("Not found error includes message")
        func notFoundDescription() {
            let response = PocketBaseErrorResponse(code: 404, message: "Record not found", data: [:])
            let error = NetworkError.notFound(response)

            let description = error.errorDescription
            #expect(description != nil)
            #expect(description!.contains("Record not found"))
        }
    }

    // MARK: - Equatable Tests

    @Suite("Equatable Conformance")
    struct EquatableTests {

        @Test("Same errors are equal")
        func sameErrorsEqual() {
            let error1 = NetworkError.invalidRequest(reason: .missingURL)
            let error2 = NetworkError.invalidRequest(reason: .missingURL)

            #expect(error1 == error2)
        }

        @Test("Different errors are not equal")
        func differentErrorsNotEqual() {
            let error1 = NetworkError.invalidRequest(reason: .missingURL)
            let error2 = NetworkError.invalidRequest(reason: .missingMethod)

            #expect(error1 != error2)
        }
    }
}

// MARK: - RealtimeError Tests

@Suite("RealtimeError")
struct RealtimeErrorTests {

    @Test("NoClientId has description")
    func noClientIdDescription() {
        let error = RealtimeError.noClientId
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("client ID"))
    }

    @Test("ConnectionTimeout has description")
    func connectionTimeoutDescription() {
        let error = RealtimeError.connectionTimeout
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("Timed out"))
    }

    @Test("SubscriptionFailed includes topic")
    func subscriptionFailedDescription() {
        let error = RealtimeError.subscriptionFailed(topic: "posts")
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("posts"))
    }
}

// MARK: - PocketBaseError Tests

@Suite("PocketBaseError")
struct PocketBaseErrorTests {

    @Test("All cases exist")
    func allCasesExist() {
        _ = PocketBaseError.alreadyAuthenticated
        _ = PocketBaseError.notImplemented
        _ = PocketBaseError.invalidRecordData
    }
}
