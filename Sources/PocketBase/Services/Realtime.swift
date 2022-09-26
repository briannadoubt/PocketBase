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

public class Realtime {
    
    /// Used to make HTTP requests.
    private let http = HTTP()
    
    /// The baseURL for all requests to PocketBase.
    private let baseUrl: URL
    
    /// Used for retry policies and authorization headers.
    private var interceptor: Interceptor?
    
    /// The clientId of this query's SSE connection.
    private var clientId: String?
    
    /// An object used to interact with the PocketBase **Users API**.
    /// - Parameters:
    ///  - baseUrl: The baseURL for all requests to PocketBase.
    ///  - interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    public init(baseUrl: URL, interceptor: Interceptor? = nil) {
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
    
    /// Handle recieving a message from a PocketBase Realtime subscription.
    /// - Parameter message: The `EventSourceMessage` that was returned for a given event.
    nonisolated private func decode<U: Decodable>(_ message: EventSourceMessage) throws -> Realtime.EventMessage<U> {
        guard
            let jsonString = message.data,
            let jsonData = jsonString.data(using: .utf8)
        else {
            throw NSError(domain: "PocketBase: Failed to decode JSON string to data.", code: 500)
        }
        let decodedMessage = try JSONDecoder().decode(Realtime.EventMessage<U>.self, from: jsonData)
        return decodedMessage
    }
    
    nonisolated private func subscribe(
        to path: String,
        lastEventId: String?,
        recievedMessage: @escaping (_ message: EventSourceMessage) -> (),
        recievedCompletion: ((_ completion: DataStreamRequest.Completion) -> ())? = nil
    ) {
        http.requestEventStream(
            baseUrl: baseUrl,
            lastEventId: lastEventId,
            interceptor: interceptor,
            recievedMessage: recievedMessage,
            recievedCompletion: recievedCompletion
        )
    }
    
    nonisolated private func recievedMessage<U: Decodable>(
        path: String,
        message: EventSourceMessage,
        recievedMessage: @escaping (_ newMessage: Realtime.EventMessage<U>) async -> ()
    ) {
        print("PocketBase: Recieved Realtime message:", String(describing: message))
        switch message.event {
        case "PB_CONNECT":
            Task {
                do {
                    self.clientId = try await self.handleConnect(message, path: path)
                } catch {
                    print("PocketBase: Recieved error while connecting to realtime services:", error)
                }
            }
        case path:
            Task {
                do {
                    let eventMessage: Realtime.EventMessage<U> = try self.decode(message)
                    await recievedMessage(eventMessage)
                } catch {
                    print("PocketBase: Recieved error while parsing realtime message:", error)
                }
            }
        default:
            break
        }
    }
    
    nonisolated func connect<U: Decodable>(
        to path: String,
        lastEventId: String?,
        recievedMessage: @escaping ((_ newMessage: Realtime.EventMessage<U>) async -> ()),
        recievedError: ((_ error: Error) -> ())? = nil
    ) {
        self.subscribe(to: path, lastEventId: lastEventId) { message in
            self.recievedMessage(path: path, message: message, recievedMessage: recievedMessage)
        } recievedCompletion: { completion in
            print(
                "SSE Stream ended with status code: \(String(describing: completion.response?.statusCode)).", "\n",
                "Error:", String(describing: completion.error)
            )
            if let error = completion.error {
                recievedError?(error)
            }
        }
    }
    
    /// Handle recieving a `PB_CONNECT` event.
    /// - Parameter message: The `EventSourceMessage` that was returned for the `PB_CONNECT` event.
    /// - Returns The `clientId` for the SSE connection to PocketBase. Store this key for future requests.
    private func handleConnect(_ message: EventSourceMessage, path: String) async throws -> String {
        guard
            let jsonString = message.data,
            let jsonData = jsonString.data(using: .utf8)
        else {
            throw NSError(domain: "PocketBase: Realtime: Failed to decode PB_CONNECT message.", code: 500)
        }
        let connect = try JSONDecoder().decode(Realtime.Connect.self, from: jsonData)
        print("Recieved PB_CONNECT message with event:", String(describing: message.event), "id:", String(describing: message.id), "and data:", String(describing: try JSONSerialization.jsonObject(with: jsonData)))
        guard let clientId = connect.clientId else {
            self.clientId = nil
            throw NSError(domain: "No clientId found.", code: 500)
        }
        try await sendSubscription(from: clientId, to: [path])
        return clientId
    }
}

public extension Realtime {
    
    struct SubscriptionRequest: Encodable {
        var clientId: String
        var subscriptions: [String]
    }
    
    struct Connect: Decodable {
        var clientId: String?
    }

    struct EventMessage<U: Decodable>: Decodable {
        public var action: EventAction
        public var record: U
        public var retry: Bool?
    }
    
    enum EventAction: String, Decodable {
        case create
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
