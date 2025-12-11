//
//  NetworkInterfacingTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 10/12/24.
//

import Foundation
import TestUtilities
import Testing
import HTTPTypes
@testable import PocketBase

struct Cat: Codable, Equatable, Sendable {
    var meows: Bool = true
}

@Suite("Network Interface")
struct NetworkInterfacingTests {

    /// Response type enum to avoid storing URLResponse directly in test parameters
    /// (URLResponse can cause Swift Testing crashes due to NSURL bridging issues)
    enum ResponseType: Sendable, CustomStringConvertible {
        case httpResponse(statusCode: Int, headers: [String: String]?)
        case plainResponse

        var description: String {
            switch self {
            case .httpResponse(let statusCode, _):
                return "HTTPURLResponse(statusCode: \(statusCode))"
            case .plainResponse:
                return "URLResponse"
            }
        }

        func makeResponse() -> URLResponse {
            switch self {
            case .httpResponse(let statusCode, let headers):
                return HTTPURLResponse(
                    url: URL.localhost,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: headers
                )!
            case .plainResponse:
                return URLResponse(
                    url: URL.localhost,
                    mimeType: nil,
                    expectedContentLength: 0,
                    textEncodingName: nil
                )
            }
        }
    }

    @Test(
        "Network Request Execution",
        arguments: zip(
            [
                (
                    url: URL.localhost,
                    method: HTTPRequest.Method.get,
                    path: "meow",
                    query: [] as [URLQueryItem],
                    headers: [:] as HTTPFields,
                    body: nil as Data?
                ),
                (
                    url: URL.localhost,
                    method: HTTPRequest.Method.post,
                    path: "meow",
                    query: [URLQueryItem(name: "rawr", value: "woof")] as [URLQueryItem],
                    headers: [.accept: "application/json"] as HTTPFields,
                    body: try! JSONEncoder().encode(Cat())
                ),
                (
                    url: URL.localhost,
                    method: HTTPRequest.Method.get,
                    path: "meow/rawr",
                    query: [URLQueryItem(name: "rawr", value: "woof")],
                    headers: [.accept: "application/json"] as HTTPFields,
                    body: nil as Data?
                ),
            ],
            [
                (
                    data: try! JSONEncoder().encode(Cat()),
                    responseType: ResponseType.httpResponse(statusCode: 200, headers: nil),
                    shouldThrow: false,
                    error: nil as Error?
                ),
                (
                    data: try! JSONEncoder().encode(Cat()),
                    responseType: ResponseType.plainResponse,
                    shouldThrow: false,
                    error: nil as Error?
                ),
                (
                    data: try! JSONEncoder().encode(Cat()),
                    responseType: ResponseType.httpResponse(statusCode: 500, headers: ["Accept": "application/json"]),
                    shouldThrow: false,
                    error: nil as Error?
                ),
            ]
        )
    )
    func execute(
        request: (
            url: URL,
            method: HTTPRequest.Method,
            path: String,
            query: [URLQueryItem],
            headers: HTTPFields,
            body: Data?
        ),
        response: (
            data: Data,
            responseType: ResponseType,
            shouldThrow: Bool,
            error: Error?
        )
    ) async throws {
        let urlResponse = response.responseType.makeResponse()
        let session = MockNetworkSession(
            data: response.data,
            response: urlResponse,
            shouldThrow: response.shouldThrow
        )
        let interface = MockNetworkInterface(
            baseURL: request.url,
            session: session
        )
        do {
            let responseData = try await interface.execute(
                method: request.method,
                path: request.path,
                query: request.query,
                headers: request.headers,
                body: request.body
            )

            let cat = try JSONDecoder().decode(Cat.self, from: responseData)
            #expect(cat == Cat())
        } catch {
            let networkError = try #require(error as? NetworkError)
            // Check if it's a non-HTTP URLResponse (should throw unknownResponse)
            if case .plainResponse = response.responseType {
                // Verify it's an unknownResponse error without comparing the URLResponse directly
                // to avoid Swift Testing crash when displaying URLResponse with nil URL
                if case .unknownResponse = networkError {
                    // Expected error type
                } else {
                    Issue.record("Expected unknownResponse error, got \(networkError)")
                }
            }
        }

        let lastRequest = try #require(session.lastRequest)

        // URL
        #expect(lastRequest.url == {
            var url = request.url
            url = url.appending(path: request.path)
            if !request.query.isEmpty {
                url = url.appending(queryItems: request.query)
            }
            return url
        }())

        // Method
        #expect(lastRequest.httpMethod == request.method.rawValue)

        // Headers
        let allHTTPHeaderFields = try #require(lastRequest.allHTTPHeaderFields)
        var headers = HTTPFields()
        for (key, value) in allHTTPHeaderFields {
            if let headerKey = HTTPField.Name(key) {
                headers[headerKey] = value
            }
        }
        #expect(headers == request.headers)

        #expect(lastRequest.httpBody == request.body)
    }

}
