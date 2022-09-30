//
//  Realtime.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Alamofire
import AlamofireEventSource
import Combine
import Foundation

/// An object used to interact with the PocketBase **Realtime API**.
public actor Realtime: Service {
    
    /// Whether or not the client is currently recieveing Server Side Events from `/api/realtime`
    @Published public var isConnected = false
    
    /// The baseURL for all requests to PocketBase.
    public let baseUrl: URL
    
    /// Used for retry policies and authorization headers.
    public var interceptor: Interceptor
    
    /// The clientId of this query's SSE connection.
    public var clientId: String?
    
    /// An object used to interact with the PocketBase **Realtime API**.
    /// - Parameters:
    ///  - baseUrl: The baseURL for all requests to PocketBase.
    ///  - interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    public init(baseUrl: URL, interceptor: Interceptor) {
        self.baseUrl = baseUrl
        self.interceptor = interceptor
    }
    
    private func sendSubscription(from clientId: String?, to path: [String]) async throws {
        guard let clientId else {
            throw NSError(domain: "QueryObservable.BadRequest.NoClientId", code: 400)
        }
        try await http.request(
            Realtime.Request.subscribe(
                baseUrl: baseUrl,
                request: Realtime.SubscriptionRequest(
                    clientId: clientId,
                    subscriptions: path
                )
            )
        )
    }
    
    private func handleMessage<U: Decodable>(
        path: String,
        message: Message<Event<U>>,
        newMessage: @escaping (_ newMessage: Message<Event<U>>) async -> ()
    ) async {
        print("PocketBase: Recieved Realtime message:", String(describing: message))
        switch message.event {
        case "PB_CONNECT":
            do {
                self.clientId = try await self.handlePBConnect(message, path: path)
                isConnected = true
            } catch {
                print("PocketBase: Recieved error while connecting to realtime services:", error)
            }
        case path:
            Task {
                await newMessage(message)
            }
        default:
            break
        }
    }
    
    func connect<U: Decodable>(
        to path: String,
        lastEventId: String?,
        recievedMessage: @escaping ((_ newMessage: Message<Event<U>>) async -> ()),
        recievedError: ((_ error: Error) -> ())? = nil
    ) {
        http.requestEventStream(
            baseUrl: baseUrl,
            lastEventId: lastEventId,
            interceptor: interceptor,
            recievedMessage: { message in
                await self.handleMessage(path: path, message: message, newMessage: recievedMessage)
            },
            recievedCompletion: { completion in
                print(
                    "SSE Stream ended with status code: \(String(describing: completion.response?.statusCode)).", "\n",
                    "Error:", String(describing: completion.error)
                )
                if let error = completion.error {
                    recievedError?(error)
                }
                self.isConnected = false
            }
        )
    }
    
    /// Handle recieving a `PB_CONNECT` event.
    /// - Parameter message: The `EventSourceMessage` that was returned for the `PB_CONNECT` event.
    /// - Returns The `clientId` for the SSE connection to PocketBase. Store this key for future requests.
    private func handlePBConnect<U: Decodable>(_ message: Message<Event<U>>, path: String) async throws -> String {
        print("Recieved PB_CONNECT message with event:", String(describing: message.event), "id:", String(describing: message.id), "and data:", String(describing: message.data))
        guard
            let clientId = message.id
        else {
            throw NSError(domain: "No clientId found.", code: 500)
        }
        try await self.sendSubscription(from: clientId, to: [path])
        return clientId
    }
}

public typealias Message<U: Decodable> = DecodableEventSourceMessage<U>

public struct Event<U: Decodable & Identifiable>: Decodable where U.ID == String? {
    public var id: U.ID?
    public var action: Action?
    public var record: U?
}

public enum Action: String, Decodable {
    case create
    case update
    case delete
}

public extension Realtime {
    
    struct SubscriptionRequest: Encodable {
        public var clientId: String
        public var subscriptions: [String]
    }
    
    struct Connect: Decodable, Identifiable {
        public var id: String?
        public var clientId: String
    }
    
    enum Request: URLRequestConvertible {
        /// Establishes a new SSE connection and immediately sends a `PB_CONNECT` SSE event with the created client ID.
        ///
        /// NB! The user/admin authorization happens during the first Set subscriptions call.
        ///
        /// If the connected client doesn't receive any new messages for 5 minutes, the server will send a disconnect signal (this is to prevent forgotten/leaked connections). The connection will be automatically reestablished if the client is still active (eg. the app is still open).
        case connect(baseUrl: URL)
        
        /// The new client subscriptions to set in the format: `COLLECTION_ID_OR_NAME` or` COLLECTION_ID_OR_NAME/RECORD_ID`.
        ///
        /// Leave empty to unsubscribe from everything.
        case subscribe(baseUrl: URL, request: SubscriptionRequest)
        
        /// The generated URL for a given request.
        public var url: URL {
            switch self {
            case .connect(let baseUrl), .subscribe(let baseUrl, _):
                return baseUrl
                    .appendingPathComponent("api")
                    .appendingPathComponent("realtime")
            }
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
            headers.add(.contentType("application/json"))
            return headers
        }
        
        // MARK: - `URLRequestConvertible` Conformance
        
        /// Convert the current case to a `URLRequest`.
        public func asURLRequest() throws -> URLRequest {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            switch self {
            case .connect:
                break
            case .subscribe(_, let subscriptionRequest):
                let body: [String: Any] = [
                    "clientId": subscriptionRequest.clientId,
                    "subscriptions": subscriptionRequest.subscriptions
                ]
                let bodyData = try JSONSerialization.data(withJSONObject: body)
                urlRequest.httpBody = bodyData
                print("PocketBase: Sending subscription request:", String(describing: try JSONSerialization.jsonObject(with: bodyData)))
            }
            return urlRequest
        }
    }
}
