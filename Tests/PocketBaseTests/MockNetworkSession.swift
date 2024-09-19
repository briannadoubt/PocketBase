//
//  MockNetworkSession.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/6/24.
//

import Foundation
import PocketBase

struct MockNetworkSession: NetworkSession {
    var data: Data = Data()
    var response: URLResponse = HTTPURLResponse()
    var shouldThrow = false
    
    var stream: MockURLSessionDataStreamTask?
    
    func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        if shouldThrow {
            throw NSError(domain: "MockNetworkSession", code: 0)
        }
        try? await Task.sleep(for: .milliseconds(100))
        return (data, response)
    }
    
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> DataSession {
        guard let stream else {
            completionHandler(nil, nil, NSError(domain: "MockNetworkSession", code: 0))
            preconditionFailure("MockNetworkSession: dataTask called without stream")
        }
        return stream
    }
}

final class MockURLSessionDataStreamTask: DataSession, Sendable {
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
