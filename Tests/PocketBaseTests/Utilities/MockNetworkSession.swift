//
//  MockNetworkSession.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/6/24.
//

import Foundation
import PocketBase

enum MockNetworkError: Error {
    case youToldMeTo
    case missingStream
}

final class MockNetworkSession: NSObject, NetworkSession, @unchecked Sendable {
    var data: Data
    var response: URLResponse
    var shouldThrow: Bool
    
    var stream: MockURLSessionDataStreamTask?
    
    var lastRequest: URLRequest?
    
    init(
        data: Data = Data(),
        response: URLResponse = HTTPURLResponse(),
        shouldThrow: Bool = false,
        stream: MockURLSessionDataStreamTask? = nil
    ) {
        self.data = data
        self.response = response
        self.shouldThrow = shouldThrow
        self.stream = stream
    }
    
    func data(
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
    
    func dataTask(
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

final class MockURLSessionDataStreamTask: NSObject, DataSession, Sendable {
    typealias Response = (data: Data?, response: URLResponse?, error: Error?)
    
    private let completionHandler: @Sendable (Data?, URLResponse?, Error?) -> Void
    private let responses: [Response]

    init(
        responses: [(Data?, URLResponse?, Error?)],
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) {
        self.responses = responses
        self.completionHandler = completionHandler
    }

    func resume() {
        // Call the completion handler with mock data after a short delay to simulate network latency
        Task {
            for response in responses {
                try? await Task.sleep(for: .milliseconds(100))
                self.completionHandler(response.data, response.response, response.error)
            }
        }
    }

    func cancel() {
        // Handle cancellation logic if necessary
    }
}
