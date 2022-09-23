//
//  Realtime.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Alamofire
import Combine
import Foundation

public struct RealtimeEventMessage<U: Decodable> {
    public var id: String?
    public var event: String?
    public var record: U?
}

public struct RealtimeConnectEventMessage {
    public var id: String?
    public var event: String?
    public var item: RealtimeConnect?
}

public struct RealtimeConnect: Decodable {
    var clientId: String?
}

public struct RealtimeSubscriptionRequest: Encodable {
    var clientId: String
    var subscriptions: [String]
}

public enum Realtime {
    
    /// Establishes a new SSE connection and immediately sends a `PB_CONNECT` SSE event with the created client ID.
    ///
    /// NB! The user/admin authorization happens during the first Set subscriptions call.
    ///
    /// If the connected client doesn't receive any new messages for 5 minutes, the server will send a disconnect signal (this is to prevent forgotten/leaked connections). The connection will be automatically reestablished if the client is still active (eg. the app is still open).
//    public func connect() async throws {
//        try await http.request(Request.connect, interceptor: interceptor)
//    }
    
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
        case subscribe(request: RealtimeSubscriptionRequest)
        
        /// The base URL for the Realtime API
        var base: URL {
            URL(string: "http://127.0.0.1:8090")!
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
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            switch self {
            case .connect:
                break
            case .subscribe(let subscriptionRequest):
                let body = try JSONEncoder().encode(subscriptionRequest)
                urlRequest.httpBody = body
                print("PocketBase: Sending subscription request:", String(describing: try JSONSerialization.jsonObject(with: body)))
            }
            
            return urlRequest
        }
    }
}
