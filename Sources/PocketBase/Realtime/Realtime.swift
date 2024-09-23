//
//  Realtime.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Combine
import Foundation
import AsyncAlgorithms
import EventSource

/// An object used to interact with the PocketBase **Realtime API**.
public actor Realtime: HasLogger {
    let defaults: UserDefaults?
    
    /// The baseURL for all requests to PocketBase.
    public let baseUrl: URL
    
    /// The clientId of the SSE connection.
    public private(set) var clientId: String?
    
    private func set(clientId: String?) {
        self.clientId = clientId
    }
    
    private(set) var subscriptions: [String: Subscription] = [:]
    
    private var eventSource: EventSource?
    
    /// An object used to interact with the PocketBase **Realtime API**.
    /// - Parameters:
    ///  - baseUrl: The baseURL for all requests to PocketBase.
    ///  - interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    public init(baseUrl: URL, defaults: UserDefaults? = UserDefaults.pocketbase) {
        self.baseUrl = baseUrl
        self.defaults = defaults
    }
    
    public func connect() async {
        eventSource = EventSource(
            config: EventSource.Config(
                handler: self,
                url: baseUrl.appendingPathComponent("api/realtime"),
                lastEventId: defaults?.string(forKey: PocketBase.lastEventKey)
            )
        )
        await eventSource?.start()
    }
    
    func subscribe<Record: BaseRecord>(
        _ collection: RecordCollection<Record>,
        at path: String
    ) async throws -> AsyncChannel<any Event> {
        if clientId == nil {
            await connect()
        }
        var shouldRetry = true
        while shouldRetry {
            try await Task.sleep(for: .milliseconds(100))
            if clientId != nil {
                shouldRetry = false
            }
        }
        guard let clientId = clientId else {
            throw NSError(domain: "QueryObservable.BadRequest.NoClientId", code: 400)
        }
        guard !clientId.isEmpty else {
            throw NSError(domain: "QueryObservable.BadRequest.InvalidClientId", code: 400)
        }
        if let subscription = subscriptions[path] {
            return subscription.channel
        }
        try await collection.requestSubscription(
            for: path,
            clientId: clientId
        )
        subscriptions[path] = Subscription(
            type: Record.self,
            channel: AsyncChannel<any Event>()
        )
        guard let channel = subscriptions[path]?.channel else {
            throw NSError(domain: "QueryObservable.BadRequest.InvalidChannel", code: 500)
        }
        return channel
    }
}

extension Realtime: EventHandler {
    public func onOpened() {
        Self.logger.info("PocketBase: SSE Stream started.")
    }
    
    public func onClosed() {
        Self.logger.info("PocketBase: SSE Stream ended.")
    }
    
    public func onMessage(
        eventType: String,
        messageEvent: MessageEvent
    ) async {
        defaults?.set(messageEvent.lastEventId, forKey: "io.pocketbase.lastEventId")
        if
            let debugData = try? JSONSerialization.data(withJSONObject: messageEvent.data, options: [.prettyPrinted, .fragmentsAllowed, .withoutEscapingSlashes]),
            let debugMessage = String(data: debugData, encoding: .utf8)
        {
            Self.logger.debug("PocketBase: Recieved Realtime message:\n***\n \(eventType): \(debugMessage) \n***")
        }
        switch eventType {
        case "PB_CONNECT":
            set(clientId: messageEvent.lastEventId)
        default:
            let messageComponents = messageEvent.data.components(separatedBy: "\n")
            guard let subscription = subscriptions[eventType] else {
                Self.logger.warning("PocketBase: Subscription for \(eventType) not found.")
                return
            }
            guard let message = messageComponents.first else {
                Self.logger.warning("PocketBase: Empty message received for \(eventType)")
                return
            }
            let rawEvent = RawRecordEvent(
                id: messageEvent.lastEventId,
                value: message
            )
            await subscription.channel.send(rawEvent)
        }
    }
    
    public func onComment(comment: String) {
        Self.logger.info("PocketBase: Recieved comment: \(comment)")
    }
    
    public func onError(error: any Error) {
        Self.logger.warning("PocketBase: Recieved error from EventSource: \(error)")
    }
}
