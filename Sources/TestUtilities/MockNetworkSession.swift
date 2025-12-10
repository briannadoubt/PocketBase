//
//  MockNetworkSession.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/6/24.
//

import Foundation
import PocketBase

public enum MockNetworkError: Error {
    case youToldMeTo
    case missingStream
}

public final class MockNetworkSession: NSObject, NetworkSession, @unchecked Sendable {
    public var data: Data
    public var response: URLResponse
    public var shouldThrow: Bool
    
    public var stream: MockURLSessionDataStreamTask?
    
    public var lastRequest: URLRequest?
    
    public init(
        data: Data = Data(),
        response: URLResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8090")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!,
        shouldThrow: Bool = false,
        stream: MockURLSessionDataStreamTask? = nil
    ) {
        self.data = data
        self.response = response
        self.shouldThrow = shouldThrow
        self.stream = stream
    }
    
    public func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        self.lastRequest = request
        if shouldThrow {
            throw MockNetworkError.youToldMeTo
        }
        try? await Task.sleep(for: .milliseconds(100))
        return (data, response)
    }
    
    public func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> any DataSession {
        guard let stream else {
            completionHandler(nil, nil, MockNetworkError.missingStream)
            preconditionFailure("MockNetworkSession: dataTask called without stream")
        }
        return stream
    }
}

public final class MockURLSessionDataStreamTask: NSObject, DataSession, Sendable {
    public typealias Response = (data: Data?, response: URLResponse?, error: Error?)
    
    private let completionHandler: @Sendable (Data?, URLResponse?, Error?) -> Void
    private let responses: [Response]

    public init(
        responses: [Response],
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) {
        self.responses = responses
        self.completionHandler = completionHandler
    }

    public func resume() {
        // Call the completion handler with mock data after a short delay to simulate network latency
        Task {
            for response in responses {
                try? await Task.sleep(for: .milliseconds(100))
                self.completionHandler(response.data, response.response, response.error)
            }
        }
    }

    public func cancel() {
        // Handle cancellation logic if necessary
    }
}
