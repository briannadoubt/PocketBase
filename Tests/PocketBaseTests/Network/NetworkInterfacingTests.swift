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
                    response: HTTPURLResponse(
                        url: URL.localhost,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!,
                    shouldThrow: false,
                    error: nil as Error?
                ),
                (
                    data: try! JSONEncoder().encode(Cat()),
                    response: URLResponse(
                        url: URL.localhost,
                        mimeType: nil,
                        expectedContentLength: 0,
                        textEncodingName: nil
                    ),
                    shouldThrow: false,
                    error: nil as Error?
                ),
                (
                    data: try! JSONEncoder().encode(Cat()),
                    response: HTTPURLResponse(
                        url: URL.localhost,
                        statusCode: 500,
                        httpVersion: "2",
                        headerFields: ["Accept": "application/json"]
                    )!,
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
            response: Data?
        ),
        response: (
            data: Data,
            response: URLResponse,
            shouldThrow: Bool,
            error: Error?
        )
    ) async throws {
        let session = MockNetworkSession(
            data: response.0,
            response: response.1,
            shouldThrow: response.2
        )
        let interface = MockNetworkInterface(
            baseURL: request.0,
            session: session
        )
        do {
            let responseData = try await interface.execute(
                method: request.1,
                path: request.2,
                query: request.3,
                headers: request.4,
                body: request.5
            )
        
            let cat = try JSONDecoder().decode(Cat.self, from: responseData)
            #expect(cat == Cat())
        } catch {
            let networkError = try #require(error as? NetworkError)
            // Check if it's a non-HTTP URLResponse (should throw unknownResponse)
            if !(response.response is HTTPURLResponse) {
                #expect(networkError == .unknownResponse(response.response))
            }
        }
        
        let lastRequest = try #require(session.lastRequest)
        
        // URL
        #expect(lastRequest.url == {
            var url = request.0
            url = url.appending(path: request.2)
            if !request.3.isEmpty {
                url = url.appending(queryItems: request.3)
            }
            return url
        }())
        
        // Method
        #expect(lastRequest.httpMethod == request.1.rawValue)
        
        // Headers
        let allHTTPHeaderFields = try #require(lastRequest.allHTTPHeaderFields)
        var headers = HTTPFields()
        for (key, value) in allHTTPHeaderFields {
            if let headerKey = HTTPField.Name(key) {
                headers[headerKey] = value
            }
        }
        #expect(headers == request.4)
        
        #expect(lastRequest.httpBody == request.5)
    }

}
