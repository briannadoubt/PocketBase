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
            await realtime.simulateConnection(clientId: "initial-client-id")
            await realtime.addSubscription(topic: "posts")
            await realtime.addSubscription(topic: "comments")

            // Verify we have 2 subscriptions
            let subscriptionCount = await realtime.subscriptions.count
            #expect(subscriptionCount == 2)

            // Clear any previous requests
            await session.clearRequests()

            // Simulate reconnection by sending PB_CONNECT event with new clientId
            let reconnectEvent = MessageEvent(
                lastEventId: "new-client-id-123",
                data: "{}"
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
            await realtime.simulateConnection(clientId: "initial-client-id")

            // Verify no subscriptions
            let subscriptionCount = await realtime.subscriptions.count
            #expect(subscriptionCount == 0)

            // Clear any previous requests
            await session.clearRequests()

            // Simulate reconnection
            let reconnectEvent = MessageEvent(
                lastEventId: "new-client-id-456",
                data: "{}"
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
            await realtime.simulateConnection(clientId: "initial-client-id")
            await realtime.addSubscription(topic: "users")

            let initialSubscriptions = await realtime.subscriptions
            #expect(initialSubscriptions.keys.contains("users"))

            // Simulate reconnection
            let reconnectEvent = MessageEvent(
                lastEventId: "reconnected-client-id",
                data: "{}"
            )
            await realtime.onMessage(eventType: "PB_CONNECT", messageEvent: reconnectEvent)

            // Verify subscriptions are still present
            let postReconnectSubscriptions = await realtime.subscriptions
            #expect(postReconnectSubscriptions.keys.contains("users"))
            #expect(postReconnectSubscriptions.count == initialSubscriptions.count)
        }
    }
}

// MARK: - Test Helpers

/// A spy session that records all subscription requests
actor SubscriptionSpySession: NetworkSession {
    private(set) var requests: [URLRequest] = []

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

