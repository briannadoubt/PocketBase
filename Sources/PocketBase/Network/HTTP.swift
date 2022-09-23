//
//  HTTP.swift
//  PocketBase
//
//  Created by Bri on 9/16/22.
//

import Alamofire
import Combine
import Foundation

/// An HTTP client that allows for generic requests.
actor HTTP {
    
    static let shared = HTTP()
    
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
        print(convertible)
        print(try convertible.asURLRequest())
        switch await AF
            .request(convertible, interceptor: interceptor)
            .serializingData()
            .result {
        case .success(let response):
            print("Response:", String(describing: try? JSONSerialization.jsonObject(with: response)))
        case .failure(let error):
            throw error
        }
    }
}
