//
//  Realtime.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Alamofire
import Foundation

public actor Realtime {
    
    /// Used to make HTTP requests.
    private let http = HTTP()
    
    /// Used for retry policies and authorization headers.
    private var interceptor: Interceptor
    
    /// An object used to interact with the PocketBase **Realtime API**.
    /// - Parameter interceptor: The request's interceptor. Use the interceptor to apply retry policies or attach headers as necessary.
    init(interceptor: Interceptor) {
        self.interceptor = interceptor
    }
    
    /// Establishes a new SSE connection and immediately sends a `PB_CONNECT` SSE event with the created client ID.
    ///
    /// NB! The user/admin authorization happens during the first Set subscriptions call.
    ///
    /// If the connected client doesn't receive any new messages for 5 minutes, the server will send a disconnect signal (this is to prevent forgotten/leaked connections). The connection will be automatically reestablished if the client is still active (eg. the app is still open).
    func connect() async throws {
        try await http.request(Request.connect, interceptor: interceptor)
    }
    
    /// The new client subscriptions to set in the format: `COLLECTION_ID_OR_NAME` or` COLLECTION_ID_OR_NAME/RECORD_ID`.
    ///
    /// Leave empty to unsubscribe from everything.
    func subscribe<T: Decodable>(clientId: UUID, subscriptions: [String]) async throws -> DataStreamPublisher<T> {
        try await http.eventListener(Request.subscribe(clientId: clientId, subscriptions: subscriptions), interceptor: interceptor)
    }
    
    enum Request: URLRequestConvertible {
        /// Establishes a new SSE connection and immediately sends a `PB_CONNECT` SSE event with the created client ID.
        ///
        /// NB! The user/admin authorization happens during the first Set subscriptions call.
        ///
        /// If the connected client doesn't receive any new messages for 5 minutes, the server will send a disconnect signal (this is to prevent forgotten/leaked connections). The connection will be automatically reestablished if the client is still active (eg. the app is still open).
        case connect
        
        /// The new client subscriptions to set in the format: `COLLECTION_ID_OR_NAME` or` COLLECTION_ID_OR_NAME/RECORD_ID`.
        ///
        /// Leave empty to unsubscribe from everything.
        case subscribe(clientId: UUID, subscriptions: [String])
        
        /// The base URL for the Realtime API
        var base: URL {
            URL(string: "https://127.0.0.1:8090")!
                .appendingPathComponent("api")
                .appendingPathComponent("realtime")
        }
        
        /// The generated URL for a given request.
        var url: URL {
            base
        }
        
        /// The HTTP Method used for a given request.
        var method: HTTPMethod {
            switch self {
            case .connect:
                return .get
            case .subscribe:
                return .post
            }
        }
        
        /// The HTTP Headers used for a given request.
        var headers: HTTPHeaders {
            var headers = HTTPHeaders()
            headers.add(.defaultAcceptEncoding)
            headers.add(.defaultUserAgent)
            headers.add(.defaultAcceptLanguage)
            return headers
        }
        
        // MARK: - `URLRequestConvertible` Conformance
        
        /// Convert the current case to a `URLRequest`.
        func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: url, method: method, headers: headers)
            var body: [String: Encodable]?
            switch self {
            case .connect:
                break
            case .subscribe(let clientId, let subscriptions):
                body = [
                    "clientId": clientId,
                    "subscriptions": subscriptions
                ]
            }
            if let body = body as? Encodable {
                request.httpBody = try JSONEncoder().encode(body)
            }
            return request
        }
            
    }
}
