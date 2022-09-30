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
public actor HTTP {
    
    /// Execute an HTTP request and decode the response as a list of objects.
    /// - Parameters:
    ///   - convertible: The request built with Alamofire's `URLRequestConvertible` protocol.
    ///   - interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    /// - Returns: A decoded list of objects.
//    func requestList<T: Decodable>(_ convertible: URLRequestConvertible, interceptor: RequestInterceptor? = nil) async throws -> [T] {
//        try await AF
//            .request(convertible, interceptor: interceptor)
//            .serializingDecodable([T].self)
//            .value
//    }
    
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
        case .success(let response):
            print("PocketBase: Recieved Response:", String(describing: try? JSONSerialization.jsonObject(with: response)))
        case .failure(let error):
            throw error
        }
    }
    
    nonisolated func requestEventStream<T: Decodable>(
        baseUrl: URL,
        lastEventId: String?,
        interceptor: RequestInterceptor? = nil,
        recievedMessage: @escaping (_ message: Message<T>) async -> (),
        recievedCompletion: @escaping (_ completion: DataStreamRequest.Completion) async -> ()
    ) {
        print("PocketBase:", "Requesting Event Stream:", "baseUrl:", baseUrl, "lastEventId:", lastEventId ?? "", "interceptor:", String(describing: interceptor.self))
        AF
            .eventSourceRequest(Realtime.Request.connect(baseUrl: baseUrl).url, lastEventID: lastEventId)
            .responseDecodableEventSource(using: DecodableEventSourceSerializer<T>()) { eventSource in
                switch eventSource.event {
                case .message(let message):
                    Task {
                        await recievedMessage(message)
                    }
                case .complete(let completion):
                    Task {
                        await recievedCompletion(completion)
                    }
                }
            }
    }
}
