//
//  HTTP.swift
//  PocketBase
//
//  Created by Bri on 9/16/22.
//

import Alamofire
import AlamofireEventSource
import Combine
import Foundation

/// An HTTP client that allows for generic requests.
actor HTTP {
    
    /// Execute an HTTP request and decode the response as a list of objects.
    /// - Parameters:
    ///   - convertible: The request built with Alamofire's `URLRequestConvertible` protocol.
    ///   - interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    /// - Returns: A decoded list of objects.
    func requestList<T: Decodable>(_ convertible: URLRequestConvertible, interceptor: RequestInterceptor? = nil) async throws -> [T] {
        try await AF
            .request(convertible, interceptor: interceptor)
            .serializingDecodable([T].self)
            .value
    }
    
    /// Execute an HTTP request and decode the response as an object.
    /// - Parameters:
    ///   - convertible: The request built with Alamofire's `URLRequestConvertible` protocol.
    ///   - interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    /// - Returns: A decoded object.
    func request<T: Decodable>(_ convertible: URLRequestConvertible, interceptor: RequestInterceptor? = nil) async throws -> T {
        try await AF
            .request(convertible, interceptor: interceptor)
            .serializingDecodable(T.self)
            .value
    }
    
    /// Execute an HTTP request.
    /// - Parameters:
    ///   - convertible: The request built with Alamofire's `URLRequestConvertible` protocol.
    ///   - interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    func request(_ convertible: URLRequestConvertible, interceptor: RequestInterceptor? = nil) async throws {
        switch await AF
            .request(convertible, interceptor: interceptor)
            .serializingData()
            .result {
        case .success(_):
            break
        case .failure(let error):
            throw error
        }
    }
    
    /// Execute HTTP request to open a Server Side Events connection.
    ///
    /// Use the resulting `DataStreamPublisher` to update observed objects or view bindings.
    /// - Parameters:
    ///   - convertible: The request built with Alamofire's `URLRequestConvertible` protocol.
    ///   - interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    /// - Returns: A publisher that publishes decoded PocketBase Server Side Events
    func eventListener<T: Decodable>(_ convertible: URLRequestConvertible, interceptor: RequestInterceptor? = nil) async throws -> DataStreamPublisher<T> {
        guard
            let url = try convertible.asURLRequest().url,
            let method = try convertible.asURLRequest().method,
            let headers = convertible.urlRequest?.headers
        else {
            throw URLError(.badURL)
        }
        return AF
            .eventSourceRequest(url, method: method, headers: headers)
            .publishDecodable(type: T.self)
    }
}
