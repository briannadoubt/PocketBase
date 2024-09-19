//
//  RecordCollection+Subscribe.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/18/24.
//

extension RecordCollection where T: BaseRecord {
    public func subscribe(
        _ recordId: String? = "*",
        handleEvent: @Sendable (RecordEvent<T>) async -> ()
    ) async throws {
        let path = if let recordId {
            "\(T.collection)/\(recordId)"
        } else {
            T.collection
        }
        let subscription = try await pocketbase.realtime.subscribe(self, at: path)
        for await event in subscription {
            if let rawEvent = event as? RawRecordEvent {
                for line in rawEvent.value.components(separatedBy: "\n") {
                    do {
                        let event = try JSONDecoder().decode(RecordEvent<T>.self, from: Data(line.utf8))
                        await handleEvent(event)
                    } catch {
                        Self.logger.error("Failed to decode event with error: \(error)")
                    }
                }
            } else {
                Self.logger.error("Failed to decode record event")
            }
        }
    }
}
