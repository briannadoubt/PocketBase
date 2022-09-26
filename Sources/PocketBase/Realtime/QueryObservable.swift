//
//  QueryObservable.swift
//  PocketBase
//
//  Created by Bri on 9/21/22.
//

import Alamofire
import AlamofireEventSource
import Combine
import Foundation

@available(iOS 14.0, macOS 12.0, watchOS 7.0, tvOS 14.0, *)
/// An observable query object used to download records from PocketBase.
public class QueryObservable<U: Codable>: ObservableObject {
    
    /// The decoded response as an array of records that conform to the casted `Codable` type.
    @Published public var records: [U]
    @Published public var messages: [Realtime.EventMessage<U>]
    
    /// An object used to interact with the PocketBase **Records API**.
    private let recordsService: Records
    
    /// An object used to interact with the PocketBase **Realtime API**.
    private let realtime: Realtime
    
    /// The configuration that alters the realtime subscription as it's modified.
    var configuration: Query<U>.Configuration
    
    /// Load the records and start the realtime subscription.
    public func load(lastEventId: String?) async throws {
        remove(configuration.path)
        let records = try await self.getRecords().items
        await set(records)
        self.realtime.connect(to: configuration.path, lastEventId: nil) { newMessage in
            await self.append(newMessage.record)
            
        }
    }
    
    /// Create a new QueryObservable object with a given configuration.
    ///  - Parameter configuration: The Query configuration that serves as a coordinator for SwiftUI.
    init(baseUrl: URL, configuration: Query<U>.Configuration, initialMessages: [Realtime.EventMessage<U>] = []) {
        self.records = initialMessages.map(\.record)
        self.messages = initialMessages
        self.configuration = configuration
        self.recordsService = Records(baseUrl: baseUrl)
        self.realtime = Realtime(baseUrl: baseUrl)
        Task {
            do {
                try await load(lastEventId: nil)
            } catch {
                print("PocketBase: Recieved error while loading initial records.")
            }
        }
    }
    
    /// Set the records via the main thread.
    @MainActor func set(_ records: [U]) {
        self.records = records
    }
    
    /// Append a record to the stored records via the main thread.
    @MainActor func append(_ record: U) {
        self.records.append(record)
    }
    
    /// Append a record to the stored records via the main thread.
    @MainActor func append(_ message: Realtime.EventMessage<U>) {
        self.messages.append(message)
    }
    
    /// Download new records.
    func getRecords() async throws -> ListResult<U> {
        try await recordsService.list(configuration.path)
    }
}
