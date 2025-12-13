//
//  RecordsAdmin+Events.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

extension RecordsAdmin {
    /// Subscribes to realtime record events for this collection.
    ///
    /// Returns an async stream of record events (create, update, delete)
    /// with `RecordModel` for dynamic field access.
    ///
    /// - Parameter recordId: Specific record ID to subscribe to, or "*" for all records. Defaults to "*".
    /// - Returns: An async stream of record events.
    ///
    /// ```swift
    /// for await event in try await pocketbase.admin.records("posts").events() {
    ///     switch event.action {
    ///     case .create: print("Created: \(event.record.id)")
    ///     case .update: print("Updated: \(event.record.id)")
    ///     case .delete: print("Deleted: \(event.record.id)")
    ///     }
    /// }
    /// ```
    public func events(_ recordId: String = "*") async throws -> AsyncStream<RecordEvent<RecordModel>> {
        let topic = if recordId != "*" {
            "\(collection)/\(recordId)"
        } else {
            collection
        }

        // Set the auth token on realtime before subscribing
        await pocketbase.realtime.setAuthToken(pocketbase.authStore.token)

        // Subscribe to the raw event stream
        let rawStream = try await pocketbase.realtime.subscribe(topic: topic)

        // Transform raw events to RecordModel events
        return AsyncStream { continuation in
            Task {
                for await rawEvent in rawStream {
                    for line in rawEvent.record.components(separatedBy: "\n") {
                        do {
                            let event = try PocketBase.decoder.decode(
                                RecordEvent<RecordModel>.self,
                                from: Data(line.utf8)
                            )
                            continuation.yield(event)
                        } catch {
                            Self.logger.error("Failed to decode admin record event: \(error)")
                        }
                    }
                }
                continuation.finish()
            }
        }
    }
}
