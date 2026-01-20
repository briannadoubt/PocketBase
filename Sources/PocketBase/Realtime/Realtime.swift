//
//  Realtime.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Foundation
import AsyncAlgorithms

/// An object used to interact with the PocketBase **Realtime API**.
///
/// Provides low-level topic-based subscriptions that can be used directly
/// or through higher-level APIs like `RecordCollection.events()`.
///
/// ```swift
/// // Low-level API
/// let stream = try await pocketbase.realtime.subscribe(topic: "posts")
/// for await event in stream {
///     print("Received: \(event.record)")
/// }
///
/// // High-level API (preferred)
/// for await event in try await pocketbase.collection(Post.self).events() {
///     print("Post: \(event.record.title)")
/// }
/// ```
public actor Realtime: HasLogger {
    let defaults: UserDefaults?

    /// The baseURL for all requests to PocketBase.
    public let baseUrl: URL

    /// The clientId of the SSE connection.
    public private(set) var clientId: String?

    /// Auth token provider for subscription requests.
    var authToken: String?

    /// The network session used for subscription requests.
    let session: any NetworkSession

    func set(clientId: String?) {
        self.clientId = clientId
    }

    func setSubscription(_ subscription: Subscription?, forTopic topic: String) {
        if let subscription {
            subscriptions[topic] = subscription
        } else {
            subscriptions.removeValue(forKey: topic)
        }
    }

    private(set) var subscriptions: [String: Subscription] = [:]

    /// Tracks in-flight subscription requests so concurrent callers can await the same result.
    private var pendingSubscriptions: [String: Task<Subscription, Error>] = [:]

    private var eventSource: EventSource?

    /// An object used to interact with the PocketBase **Realtime API**.
    /// - Parameters:
    ///  - baseUrl: The baseURL for all requests to PocketBase.
    ///  - defaults: UserDefaults for persisting last event ID.
    ///  - session: The network session for subscription requests (defaults to URLSession.shared).
    public init(
        baseUrl: URL,
        defaults: UserDefaults? = UserDefaults.pocketbase,
        session: any NetworkSession = URLSession.shared
    ) {
        self.baseUrl = baseUrl
        self.defaults = defaults
        self.session = session
    }

    /// Sets the auth token for subscription requests.
    public func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    /// Connects to the SSE endpoint.
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

    // MARK: - Low-level Topic Subscription

    /// Subscribes to a topic and returns a stream of raw record events.
    ///
    /// This is the low-level API that higher-level APIs build upon.
    /// Use `RecordCollection.events()` for typed events, or
    /// `RecordsAdmin.events()` for admin access.
    ///
    /// - Parameter topic: The topic to subscribe to (e.g., "posts", "posts/abc123").
    /// - Returns: An async stream of raw record events.
    public func subscribe(topic: String) async throws -> AsyncStream<RawRecordEvent> {
        // Ensure we're connected
        if clientId == nil {
            await connect()
        }

        // Wait for clientId
        try await waitForClientId()

        guard let clientId = clientId else {
            throw RealtimeError.noClientId
        }

        // Return existing subscription if present
        if let existing = subscriptions[topic] {
            return existing.channel.asAsyncStream()
        }

        // If there's already an in-flight request for this topic, wait for it.
        // This ensures concurrent callers all observe the same success/failure.
        if let pendingTask = pendingSubscriptions[topic] {
            let subscription = try await withTaskCancellationHandler {
                try await pendingTask.value
            } onCancel: {
                pendingTask.cancel()
            }
            return subscription.channel.asAsyncStream()
        }

        // Create a task to handle the subscription request.
        // The task checks for cancellation after the request succeeds to avoid
        // storing subscriptions that no caller will use.
        let task = Task<Subscription, Error> { [weak self] in
            guard let self else { throw CancellationError() }

            let subscription = Subscription()

            // Request the subscription from PocketBase
            try await self.requestSubscription(topic: topic, clientId: clientId)

            // Check for cancellation after request succeeds - if cancelled,
            // clean up the server-side subscription to avoid leaks
            if Task.isCancelled {
                try? await self.requestUnsubscription(topic: topic, clientId: clientId)
                throw CancellationError()
            }

            // Store subscription only if not cancelled (must use actor-isolated method)
            await self.setSubscription(subscription, forTopic: topic)
            return subscription
        }

        // Track the in-flight request
        pendingSubscriptions[topic] = task

        do {
            let subscription = try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
            pendingSubscriptions.removeValue(forKey: topic)
            return subscription.channel.asAsyncStream()
        } catch {
            pendingSubscriptions.removeValue(forKey: topic)
            throw error
        }
    }

    /// Unsubscribes from a topic.
    ///
    /// - Parameter topic: The topic to unsubscribe from.
    public func unsubscribe(topic: String) async throws {
        guard let clientId = clientId else { return }

        subscriptions.removeValue(forKey: topic)

        // Notify server of unsubscription
        try await requestUnsubscription(topic: topic, clientId: clientId)
    }

    // MARK: - Private Helpers

    private func waitForClientId() async throws {
        var attempts = 0
        let maxAttempts = 50 // 5 seconds max

        while clientId == nil && attempts < maxAttempts {
            try await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        if clientId == nil {
            throw RealtimeError.connectionTimeout
        }
    }

    private func requestSubscription(topic: String, clientId: String) async throws {
        let url = baseUrl.appendingPathComponent("api/realtime")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = SubscriptionRequest(clientId: clientId, subscriptions: [topic])
        request.httpBody = try JSONEncoder().encode(body)

        #if DEBUG
        Self.logger.log("Requesting: \(request.cURL)")
        #endif

        let (data, response) = try await session.data(for: request, delegate: nil)

        #if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            Self.logger.log("Response: \(responseString)")
        } else {
            Self.logger.log("Response: cannot parse")
        }
        #endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw RealtimeError.subscriptionFailed(topic: topic)
        }
    }

    private func requestUnsubscription(topic: String, clientId: String) async throws {
        let url = baseUrl.appendingPathComponent("api/realtime")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Empty subscriptions array removes the topic
        let body = SubscriptionRequest(clientId: clientId, subscriptions: [])
        request.httpBody = try JSONEncoder().encode(body)

        #if DEBUG
        Self.logger.log("Requesting: \(request.cURL)")
        #endif

        do {
            let (data, _) = try await session.data(for: request, delegate: nil)
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                Self.logger.log("Response: \(responseString)")
            } else {
                Self.logger.log("Response: cannot parse")
            }
            #else
            _ = data
            #endif
        } catch {
            Self.logger.warning("Failed to unsubscribe from topic '\(topic)': \(error)")
        }
    }
}

// MARK: - Request Types

struct SubscriptionRequest: Codable {
    var clientId: String
    var subscriptions: [String]
}

// MARK: - Errors

public enum RealtimeError: Error, LocalizedError {
    case noClientId
    case connectionTimeout
    case subscriptionFailed(topic: String)

    public var errorDescription: String? {
        switch self {
        case .noClientId:
            return "No client ID available. Connection may have failed."
        case .connectionTimeout:
            return "Timed out waiting for SSE connection."
        case .subscriptionFailed(let topic):
            return "Failed to subscribe to topic: \(topic)"
        }
    }
}

// MARK: - EventHandler

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

        if let debugData = try? JSONSerialization.data(
            withJSONObject: messageEvent.data,
            options: [.prettyPrinted, .fragmentsAllowed, .withoutEscapingSlashes]
        ),
           let debugMessage = String(data: debugData, encoding: .utf8) {
            Self.logger.debug("PocketBase: Received Realtime message:\n***\n \(eventType): \(debugMessage) \n***")
        }

        switch eventType {
        case "PB_CONNECT":
            let newClientId = messageEvent.lastEventId
            let existingTopics = Array(subscriptions.keys)
            set(clientId: newClientId)

            // Re-subscribe to existing topics with new clientId
            if !existingTopics.isEmpty, !newClientId.isEmpty {
                Self.logger.info("PocketBase: Re-subscribing to \(existingTopics.count) topic(s) after reconnection")
                for topic in existingTopics {
                    // Check if subscription still exists (may have been removed during reconnect)
                    guard subscriptions[topic] != nil else {
                        Self.logger.debug("PocketBase: Skipping re-subscribe for \(topic) - already unsubscribed")
                        continue
                    }
                    do {
                        try await requestSubscription(topic: topic, clientId: newClientId)
                        Self.logger.debug("PocketBase: Re-subscribed to \(topic)")
                    } catch {
                        Self.logger.warning("PocketBase: Failed to re-subscribe to \(topic): \(error)")
                    }
                }
            }
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
                record: message
            )
            await subscription.channel.send(rawEvent)
        }
    }

    public func onComment(comment: String) {
        Self.logger.info("PocketBase: Received comment: \(comment)")
    }

    public func onError(error: any Error) {
        Self.logger.warning("PocketBase: Received error from EventSource: \(error)")
    }
}

// MARK: - AsyncChannel Extension

extension AsyncChannel {
    /// Converts an AsyncChannel to an AsyncStream.
    func asAsyncStream() -> AsyncStream<Element> {
        AsyncStream { continuation in
            let task = Task {
                for await element in self {
                    if Task.isCancelled { break }
                    continuation.yield(element)
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
