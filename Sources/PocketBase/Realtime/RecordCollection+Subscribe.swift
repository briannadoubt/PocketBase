//
//  RecordCollection+Subscribe.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/18/24.
//

extension RecordCollection where T: BaseRecord {
    public func events(_ recordId: String? = "*") async throws -> AsyncStream<RecordEvent<T>> {
        let path = if let recordId {
            "\(T.collection)/\(recordId)"
        } else {
            T.collection
        }
        let subscription = try await pocketbase.realtime.subscribe(self, at: path)
        // Capture the decoder configured with baseURL for file field hydration
        let decoder = self.decoder
        return AsyncStream { continuation in
            Task {
                for await event in subscription {
                    guard let rawEvent = event as? RawRecordEvent else {
                        Self.logger.error("Event is not raw record event")
                        continue
                    }
                    for line in rawEvent.record.components(separatedBy: "\n") {
                        do {
                            let event = try decoder.decode(
                                RecordEvent<T>.self,
                                from: Data(line.utf8)
                            )
                            continuation.yield(event)
                        } catch {
                            Self.logger.error("Failed to decode event with error: \(error)")
                        }
                    }
                }
            }
        }
    }
}
