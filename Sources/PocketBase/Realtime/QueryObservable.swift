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
public class QueryObservable<T: Decodable>: ObservableObject {
    
    @Published public var records: T
    
    private let recordsService = Records()
    
    private var cancellables: Set<AnyCancellable> = []
    
    internal var shouldUpdateListener = true
    
    internal var configuration: Query<T>.Configuration {
        didSet {
            guard shouldUpdateListener else { return }
            remove(configuration.path)
            startListening()
        }
    }
    
    private var startListening: (() -> ())!
    
    /// Used to maintain a persistent Server Side Event connection.
    private let eventSource: EventSource
    
    private var clientId: String?
    
    @MainActor func set<U: Decodable>(_ records: [U]) where T == [U] {
        withAnimation {
            self.records = records
        }
    }
    
    func getRecords<U: Codable>() async throws where T == [U] {
        try await set(recordsService.list("test").items)
    }
    
    public func remove(_ path: String) {
        eventSource.removeEventListener(path)
    }
    
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
                do {
                    try await self.getRecords()
                } catch {
                    print("Failed to get records with error:", error)
                }
            }
            self.eventSource.onOpen {
                print("SSE Connection Opened")
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
        startListening()
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
