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

public enum PocketBaseError: LocalizedError {
    
    case client(_ error: ClientError)
    case query(_ error: QueryError)
    
    public var errorDescription: String? {
        let pocketbase = "PocketBase: Recieved error: "
        switch self {
        case .client(let error as LocalizedError),
             .query(let error as LocalizedError):
            return pocketbase + (error.errorDescription ?? "")
        }
    }
    
    public enum ClientError: LocalizedError {
        
        case noClientFound(_ message: String)
        
        public var errorDescription: String? {
            switch self {
            case .noClientFound(let message):
                return "No client found: " + message
            }
        }
    }
    
    public enum QueryError: LocalizedError {
        
        case failedLoadingInitialQuery(_ message: String)
        
        public var errorDescription: String? {
            switch self {
            case .failedLoadingInitialQuery(let message):
                return "Loading Error: " + message
            }
        }
    }
    
    public enum RecordsError: LocalizedError {
        
    }
}

@available(iOS 14.0, macOS 12.0, watchOS 7.0, tvOS 14.0, *)
/// An observable query object used to download records from PocketBase.
public class QueryObservable<U: Codable & Identifiable>: ObservableObject where U.ID == String? {
    
    /// The decoded response as an array of records that conform to the casted `Codable` type.
    @Published public var messages: [Message<Event<U>>]
    
    /// An object used to interact with the PocketBase **Records API**.
    var client = PocketBase.shared
    
    /// The configuration that alters the realtime subscription as it's modified.
    var configuration: Query<U>.Configuration
    
    /// Create a new QueryObservable object with a given configuration.
    ///  - Parameter configuration: The Query configuration that serves as a coordinator for SwiftUI.
    init(
        configuration: Query<U>.Configuration,
        initialMessages: [Message<Event<U>>] = []
    ) {
        self.messages = initialMessages
        self.configuration = configuration
        Task {
            do {
                try await load(clientId: await client.realtime.clientId, lastEventId: nil)
            } catch let error as LocalizedError {
                print(error.errorDescription ?? "Unknown Error")
            }
        }
    }
    
    /// Load the records and start the realtime subscription.
    func load(clientId: String?, lastEventId: String?) async throws {
        let records = try await getRecords().items
        let messages = records.map { record in
            Message(
                event: configuration.path,
                id: clientId,
                data: Event(
                    id: record.id,
                    action: .create,
                    record: record
                )
            )
        }
        await set(messages)
        guard await !client.realtime.isConnected else {
            // If the client is already connected we don't need to attempt another reconnect call.
            return
        }
        await client.realtime.connect(to: configuration.path, lastEventId: lastEventId) { (newMessage: Message<Event<U>>) in
            guard let event = newMessage.data, let action = event.action else {
                print("PocketBase: Recieved Error: No event found for message:", newMessage)
                return
            }
            switch action {
            case .create:
                await self.append(newMessage)
            case .update:
                await self.update(newMessage)
            case .delete:
                await self.remove(newMessage)
            }
        } recievedError: { error in
            print(error)
        }
    }
    
    /// Set the messages via the main thread.
    @MainActor func set(_ messages: [Message<Event<U>>]) {
        self.messages = messages
    }
    
    /// Append a record to the stored records via the main thread.
    @MainActor func append(_ message: Message<Event<U>>) {
        self.messages.append(message)
    }
    
    /// Remove a record from the stored records via the main thread
    @MainActor func remove(_ message: Message<Event<U>>) {
        guard let index = self.messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        self.messages.remove(at: index)
    }
    
    @MainActor func update(_ message: Message<Event<U>>) {
        guard let index = self.messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        self.messages[index] = message
    }
    
    /// Download new records.
    func getRecords() async throws -> ListResult<U> {
        return try await client.records.list(configuration.path)
    }
}
