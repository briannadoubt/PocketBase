//
//  RecordCollection+RequestSubscription.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/18/24.
//

extension RecordCollection where T: BaseRecord {
    public func requestSubscription(
        for path: String,
        clientId: String
    ) async throws {
        try await post(
            path: "/api/realtime",
            headers: headers,
            body: SubscriptionRequest(
                clientId: clientId,
                subscriptions: [path]
            )
        )
    }
    
    struct SubscriptionRequest: Encodable {
        var clientId: String
        var subscriptions: [String]
    }
}
