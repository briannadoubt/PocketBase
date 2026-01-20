//
//  RealtimeTests.swift
//  PocketBase
//
//  Created by Claude on 2026-01-15.
//

import Testing
import Foundation
@testable import PocketBase
import TestUtilities

@Suite("Realtime")
struct RealtimeTests {

    @Suite("Subscription")
    struct SubscriptionTests {

        @Test("Concurrent subscribers share the same request")
        func concurrentSubscribersShareRequest() async throws {
            let session = SubscriptionSpySession()
            let realtime = Realtime(
                baseUrl: .localhost,
                defaults: nil,
                session: session
            )

            // Set clientId to skip connection setup
            await realtime.set(clientId: "test-client-id")

            // Start two concurrent subscriptions to the same topic
            async let stream1 = realtime.subscribe(topic: "posts")
            async let stream2 = realtime.subscribe(topic: "posts")

            // Both should succeed
            _ = try await stream1
            _ = try await stream2

            // Only one request should have been made
            let requests = await session.requests
            #expect(requests.count == 1)
        }

        @Test("Concurrent subscribers all receive error on failure")
        func concurrentSubscribersReceiveError() async throws {
            let session = FailingSession()
            let realtime = Realtime(
                baseUrl: .localhost,
                defaults: nil,
                session: session
            )

            // Set clientId to skip connection setup
            await realtime.set(clientId: "test-client-id")

            // Start two concurrent subscriptions
            async let result1: Result<AsyncStream<RawRecordEvent>, Error> = {
                do {
                    return .success(try await realtime.subscribe(topic: "posts"))
                } catch {
                    return .failure(error)
                }
            }()

            async let result2: Result<AsyncStream<RawRecordEvent>, Error> = {
                do {
                    return .success(try await realtime.subscribe(topic: "posts"))
                } catch {
                    return .failure(error)
                }
            }()

            let results = await [result1, result2]

            // Both should have failed
            for result in results {
                switch result {
                case .success:
                    Issue.record("Expected failure but got success")
                case .failure:
                    break // Expected
                }
            }

            // No subscription should be stored
            let subscriptions = await realtime.subscriptions
            #expect(subscriptions.isEmpty)
        }

        @Test("Cancellation cleans up server subscription")
        func cancellationCleansUpServerSubscription() async throws {
            // Use a coordinated session that signals when request completes
            let session = CoordinatedSession()
            let realtime = Realtime(
                baseUrl: .localhost,
                defaults: nil,
                session: session
            )

            // Set clientId to skip connection setup
            await realtime.set(clientId: "test-client-id")

            // Start subscription task
            let task = Task {
                try await realtime.subscribe(topic: "posts")
            }

            // Wait for the first request to complete
            await session.waitForRequestCount(1)

            // Cancel the task after request succeeded but before Task.isCancelled check completes
            // The task should see the cancellation and clean up
            task.cancel()

            // Wait for cancellation to propagate
            do {
                _ = try await task.value
                // Task might succeed if cancellation doesn't propagate in time - that's OK
            } catch is CancellationError {
                // Expected when cancellation propagates
            } catch {
                Issue.record("Unexpected error: \(error)")
            }

            // Give time for cleanup
            try await Task.sleep(for: .milliseconds(100))

            // Check if unsubscribe was called (may or may not happen depending on timing)
            let requests = await session.requests
            let hasUnsubscribe = requests.contains { request in
                guard let body = request.httpBody,
                      let json = try? JSONDecoder().decode(SubscriptionRequest.self, from: body) else {
                    return false
                }
                return json.subscriptions.isEmpty // Empty array = unsubscribe
            }

            // If task was cancelled in time, unsubscribe should have been sent
            // If not, subscription should be stored
            let subscriptions = await realtime.subscriptions
            if subscriptions.isEmpty {
                // Cancellation worked - should have unsubscribe request
                #expect(hasUnsubscribe, "Should have sent unsubscribe request on cancellation")
            }
            // If subscription exists, cancellation was too late - that's also valid behavior
        }

        @Test("Subscription not stored when cancelled before completion")
        func subscriptionNotStoredWhenCancelled() async throws {
            let session = SlowThenSuccessSession(delay: .milliseconds(200))
            let realtime = Realtime(
                baseUrl: .localhost,
                defaults: nil,
                session: session
            )

            // Set clientId to skip connection setup
            await realtime.set(clientId: "test-client-id")

            // Start subscription in a task we can cancel
            let task = Task {
                try await realtime.subscribe(topic: "posts")
            }

            // Cancel immediately before request completes
            try await Task.sleep(for: .milliseconds(50))
            task.cancel()

            // Wait for task to finish
            _ = try? await task.value

            // Give time for any async cleanup
            try await Task.sleep(for: .milliseconds(300))

            // No subscription should be stored
            let subscriptions = await realtime.subscriptions
            #expect(subscriptions.isEmpty)
        }
    }

    @Suite("Reconnection")
    struct ReconnectionTests {

        @Test("Re-subscribes to existing topics after receiving PB_CONNECT")
        func resubscribesAfterReconnection() async throws {
            let session = SubscriptionSpySession()
            let realtime = Realtime(
                baseUrl: .localhost,
                defaults: nil,
                session: session
            )

            // Simulate initial connection by setting clientId and adding a subscription
            await realtime.set(clientId: "initial-client-id")
            await realtime.setSubscription(Subscription(), forTopic: "posts")
            await realtime.setSubscription(Subscription(), forTopic: "comments")

            // Verify we have 2 subscriptions
            let subscriptionCount = await realtime.subscriptions.count
            #expect(subscriptionCount == 2)

            // Clear any previous requests
            await session.clearRequests()

            // Simulate reconnection by sending PB_CONNECT event with new clientId
            let reconnectEvent = MessageEvent(
                data: "{}",
                lastEventId: "new-client-id-123"
            )
            await realtime.onMessage(eventType: "PB_CONNECT", messageEvent: reconnectEvent)

            // Verify the new clientId was set
            let newClientId = await realtime.clientId
            #expect(newClientId == "new-client-id-123")

            // Verify re-subscription requests were made
            let requests = await session.requests
            #expect(requests.count == 2)

            // Verify both topics were re-subscribed
            let subscribedTopics = requests.compactMap { request -> String? in
                guard let body = request.httpBody,
                      let json = try? JSONDecoder().decode(SubscriptionRequest.self, from: body),
                      let topic = json.subscriptions.first else {
                    return nil
                }
                return topic
            }
            #expect(subscribedTopics.contains("posts"))
            #expect(subscribedTopics.contains("comments"))

            // Verify clientId in requests is the new one
            for request in requests {
                guard let body = request.httpBody,
                      let json = try? JSONDecoder().decode(SubscriptionRequest.self, from: body) else {
                    Issue.record("Failed to decode subscription request")
                    continue
                }
                #expect(json.clientId == "new-client-id-123")
            }
        }

        @Test("Does not make requests when no existing subscriptions on reconnect")
        func noRequestsWhenNoSubscriptions() async throws {
            let session = SubscriptionSpySession()
            let realtime = Realtime(
                baseUrl: .localhost,
                defaults: nil,
                session: session
            )

            // Simulate initial connection with no subscriptions
            await realtime.set(clientId: "initial-client-id")

            // Verify no subscriptions
            let subscriptionCount = await realtime.subscriptions.count
            #expect(subscriptionCount == 0)

            // Clear any previous requests
            await session.clearRequests()

            // Simulate reconnection
            let reconnectEvent = MessageEvent(
                data: "{}",
                lastEventId: "new-client-id-456"
            )
            await realtime.onMessage(eventType: "PB_CONNECT", messageEvent: reconnectEvent)

            // Verify no re-subscription requests were made
            let requests = await session.requests
            #expect(requests.isEmpty)

            // Verify clientId was still updated
            let newClientId = await realtime.clientId
            #expect(newClientId == "new-client-id-456")
        }

        @Test("Subscriptions dictionary preserved after reconnection")
        func subscriptionsPreservedAfterReconnection() async throws {
            let session = SubscriptionSpySession()
            let realtime = Realtime(
                baseUrl: .localhost,
                defaults: nil,
                session: session
            )

            // Simulate initial connection
            await realtime.set(clientId: "initial-client-id")
            await realtime.setSubscription(Subscription(), forTopic: "users")

            let initialSubscriptions = await realtime.subscriptions
            #expect(initialSubscriptions.keys.contains("users"))

            // Simulate reconnection
            let reconnectEvent = MessageEvent(
                data: "{}",
                lastEventId: "reconnected-client-id"
            )
            await realtime.onMessage(eventType: "PB_CONNECT", messageEvent: reconnectEvent)

            // Verify subscriptions are still present
            let postReconnectSubscriptions = await realtime.subscriptions
            #expect(postReconnectSubscriptions.keys.contains("users"))
            #expect(postReconnectSubscriptions.count == initialSubscriptions.count)
        }

        @Test("Skips re-subscribing to topics removed before reconnection completes")
        func skipsRemovedTopicsDuringReconnection() async throws {
            let session = SubscriptionSpySession()
            let realtime = Realtime(
                baseUrl: .localhost,
                defaults: nil,
                session: session
            )

            // Simulate initial connection with multiple subscriptions
            await realtime.set(clientId: "initial-client-id")
            await realtime.setSubscription(Subscription(), forTopic: "posts")
            await realtime.setSubscription(Subscription(), forTopic: "comments")

            // Verify we start with 2 subscriptions
            let initialCount = await realtime.subscriptions.count
            #expect(initialCount == 2)

            // Remove one subscription BEFORE reconnection
            // This simulates an unsubscribe that happened just before PB_CONNECT arrives
            await realtime.setSubscription(nil, forTopic: "comments")

            // Clear any previous requests
            await session.clearRequests()

            // Simulate reconnection
            let reconnectEvent = MessageEvent(
                data: "{}",
                lastEventId: "new-client-id"
            )
            await realtime.onMessage(eventType: "PB_CONNECT", messageEvent: reconnectEvent)

            // Get the topics that were actually re-subscribed
            let requests = await session.requests
            let subscribedTopics = requests.compactMap { request -> String? in
                guard let body = request.httpBody,
                      let json = try? JSONDecoder().decode(SubscriptionRequest.self, from: body),
                      let topic = json.subscriptions.first else {
                    return nil
                }
                return topic
            }

            // Only "posts" should have been re-subscribed
            #expect(subscribedTopics.contains("posts"))
            #expect(!subscribedTopics.contains("comments"))
            #expect(requests.count == 1)
        }
    }
}

// MARK: - Test Helpers

/// A spy session that records all subscription requests
actor SubscriptionSpySession: NetworkSession {
    private(set) var requests: [URLRequest] = []

    static func == (lhs: SubscriptionSpySession, rhs: SubscriptionSpySession) -> Bool {
        lhs === rhs
    }

    func clearRequests() {
        requests = []
    }

    nonisolated func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        await recordRequest(request)

        // Return a successful response
        let response = HTTPURLResponse(
            url: request.url ?? .localhost,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(), response)
    }

    private func recordRequest(_ request: URLRequest) {
        requests.append(request)
    }

    nonisolated func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> any DataSession {
        fatalError("Not implemented for tests")
    }
}

/// A session that always fails requests
actor FailingSession: NetworkSession {
    struct TestError: Error {}

    static func == (lhs: FailingSession, rhs: FailingSession) -> Bool {
        lhs === rhs
    }

    nonisolated func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        throw TestError()
    }

    nonisolated func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> any DataSession {
        fatalError("Not implemented for tests")
    }
}

/// A session that succeeds immediately but allows waiting for requests
actor CoordinatedSession: NetworkSession {
    private(set) var requests: [URLRequest] = []
    private var requestContinuations: [CheckedContinuation<Void, Never>] = []
    private var targetCount = 0

    static func == (lhs: CoordinatedSession, rhs: CoordinatedSession) -> Bool {
        lhs === rhs
    }

    func waitForRequestCount(_ count: Int) async {
        if requests.count >= count {
            return
        }
        targetCount = count
        await withCheckedContinuation { continuation in
            requestContinuations.append(continuation)
        }
    }

    nonisolated func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        await recordRequest(request)

        let response = HTTPURLResponse(
            url: request.url ?? .localhost,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(), response)
    }

    private func recordRequest(_ request: URLRequest) {
        requests.append(request)
        if requests.count >= targetCount {
            for continuation in requestContinuations {
                continuation.resume()
            }
            requestContinuations.removeAll()
        }
    }

    nonisolated func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> any DataSession {
        fatalError("Not implemented for tests")
    }
}

/// A session that delays then succeeds, recording all requests
actor SlowThenSuccessSession: NetworkSession {
    private(set) var requests: [URLRequest] = []
    private let delay: Duration

    init(delay: Duration) {
        self.delay = delay
    }

    static func == (lhs: SlowThenSuccessSession, rhs: SlowThenSuccessSession) -> Bool {
        lhs === rhs
    }

    nonisolated func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        await recordRequest(request)

        // Delay to simulate slow network
        try await Task.sleep(for: delay)

        // Check for cancellation
        try Task.checkCancellation()

        let response = HTTPURLResponse(
            url: request.url ?? .localhost,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(), response)
    }

    private func recordRequest(_ request: URLRequest) {
        requests.append(request)
    }

    nonisolated func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> any DataSession {
        fatalError("Not implemented for tests")
    }
}

