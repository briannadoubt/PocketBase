//
//  QueryObservable.swift
//  PocketBase
//
//  Created by Bri on 9/21/22.
//

import Combine
import EventSource
import Foundation
import SwiftUI

@available(iOS 14.0, macOS 12.0, watchOS 7.0, tvOS 14.0, *)
/// An observable query object used to download records from PocketBase.
public class QueryObservable<T: Codable>: ObservableObject {
    
    /// The decoded response as an array of records that conform to the casted `Codable` type.
    @Published public var records: T
    
    /// An object used to interact with the PocketBase **Records API**.
    private let recordsService = Records()
    
    /// The configuration that alters the realtime subscription as it's modified.
    internal var configuration: Query<T>.Configuration
    
    /// Restart the connection and reload the records.
    public func restart() {
        remove(configuration.path)
        startListening()
    }
    
    /// Private variable that enables starting a new connection.
    private var startListening: (() -> ())!
    
    /// Used to maintain a persistent Server Side Event connection.
    private let eventSource: EventSource
    
    /// The clientId of this query's SSE connection.
    private var clientId: String?
    
    init<U: Codable>(configuration: Query<T>.Configuration) where T == [U] {
        self.records = []
        self.configuration = configuration
        self.eventSource = EventSource(
            url: Realtime.Request.connect.url,
            headers: Realtime.Request.connect.headers.dictionary
        )
        self.eventSource.connect(lastEventId: self.eventSource.lastEventId)
        startListening = {
            Task {
                await self.getRecords()
                
                self.eventSource.onOpen {
                    print("SSE Connection Opened")
                }
                
                self.eventSource.addEventListener(configuration.path) { id, event, data in
                    print("Recieved \(configuration.path) message with event:", String(describing: event), "id:", String(describing: id), "and data:", String(describing: data))
                    guard
                        let jsonString = data,
                        let jsonData = jsonString.data(using: .utf8)
                    else {
                        print("Failed to decode JSON string to data for \(configuration.path).")
                        return
                    }
                    do {
                        let record = try JSONDecoder().decode(U.self, from: jsonData)
                        self.records.append(record)
                    } catch {
                        print("Failed to decode event for \(configuration.path):", error)
                    }
                }
                
                self.eventSource.addEventListener("PB_CONNECT") { id, event, data in
                    print("Recieved PB_CONNECT message with event:", String(describing: event), "id:", String(describing: id), "and data:", String(describing: data))
                    guard
                        let jsonString = data,
                        let jsonData = jsonString.data(using: .utf8),
                        let connect = try? JSONDecoder().decode(RealtimeConnect.self, from: jsonData)
                    else {
                        assertionFailure("Failed to connect for some reason...")
                        return
                    }
                    guard let clientId = connect.clientId else {
                        assertionFailure("No clientId found!")
                        self.clientId = nil
                        return
                    }
                    self.clientId = clientId
                    self.sendSubscription(from: clientId, to: [configuration.path])
                }
                
                self.eventSource.onMessage { id, event, data in
                    print("Recieved message with id:", String(describing: id), "event:", String(describing: event), "data:", String(describing: data))
                }
                
                self.eventSource.onComplete { statusCode, shouldAttempReconnection, error in
                    print(
                        "SSE Stream ended with status code: \(String(describing: statusCode)).", "\n",
                        "Should attempt reconnection: \(String(describing: shouldAttempReconnection)).", "\n",
                        "Error:", String(describing: error))
                }
            }
        }
        startListening()
    }
    
    /// Set the records via the main thread.
    @MainActor func set<U: Decodable>(_ records: T) where T == [U] {
        withAnimation {
            self.records = records
        }
    }
    
    /// Download new records.
    internal func getRecords<U: Codable>() async where T == [U] {
        do {
            try await set(recordsService.list("test").items)
        } catch {
            configuration.error = error
        }
    }
    
    /// Remove a subscription for a given path.
    /// - Parameter path: A `collectionId`, `collectionName`, or `recordId`.
    public func remove(_ path: String) {
        eventSource.removeEventListener(path)
    }
    
    private func sendSubscription(from clientId: String?, to path: [String]) {
        Task {
            do {
                guard let clientId else {
                    throw NSError(domain: "QueryObservable.BadRequest.NoClientId", code: 400)
                }
                try await self.recordsService.http.request(
                    Realtime.Request.subscribe(
                        request: RealtimeSubscriptionRequest(
                            clientId: clientId,
                            subscriptions: path
                        )
                    )
                )
            } catch {
                print(error)
                assertionFailure(error.localizedDescription)
            }
        }
    }
}
