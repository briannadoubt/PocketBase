//
//  NetworkSession.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/3/24.
//

import Foundation

public protocol NetworkSession: Sendable {
    /// Convenience method to load data using a URLRequest, creates and resumes a URLSessionDataTask internally.
    ///
    /// - Parameter request: The URLRequest for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse)
    
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> DataSession
}

public protocol DataSession: AnyObject {
    func resume()
    func cancel()
}

extension URLSessionDataTask: DataSession {}

extension NetworkSession {
    /// Convenience method to load data using a URLRequest, creates and resumes a URLSessionDataTask internally.
    ///
    /// - Parameter request: The URLRequest for which to load data.
    /// - Parameter delegate: Task-specific delegate. Defaults to `nil`.
    /// - Returns: Data and response.
    public func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: delegate)
    }
}

extension URLSession: NetworkSession {
    public func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> any DataSession {
        dataTask(
            with: request,
            completionHandler: completionHandler
        ) as URLSessionDataTask
    }
}
