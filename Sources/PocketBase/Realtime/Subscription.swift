//
//  Subscription.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/18/24.
//

import Foundation
import AsyncAlgorithms

/// A subscription to a PocketBase realtime topic.
///
/// Subscriptions manage the async channel that receives raw events
/// from the SSE connection.
public struct Subscription: Sendable {
    /// The async channel that receives raw record events.
    public let channel = AsyncChannel<RawRecordEvent>()

    public init() {}
}
