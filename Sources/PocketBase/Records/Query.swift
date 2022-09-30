//
//  RecordQuery.swift
//  PocketBase
//
//  Created by Bri on 9/21/22.
//

import Alamofire
import AlamofireEventSource
#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(SwiftUI)
@available(iOS 14.0, macOS 12.0, watchOS 7.0, tvOS 14.0, *)
@propertyWrapper
public struct Query<U: Codable & Identifiable>: DynamicProperty where U.ID == String? {
    
    @EnvironmentObject var client: PocketBase
    @StateObject var queryObservable: QueryObservable<U>
    @Environment(\.baseUrl) var baseUrl
    
    public struct Configuration {
        public var path: String
        public var error: Error?
        public var interceptor: Interceptor = UserBearerTokenPolicy().interceptor
    }
    
    public var wrappedValue: [U] {
        queryObservable.messages.compactMap(\.data?.record)
    }
    
    public var projectedValue: Coordinator<U> {
        Coordinator(query: self)
    }
    
    public func load(clientId: String?) async {
        do {
            queryObservable.messages = try await queryObservable.getRecords().items.map { record in
                DecodableEventSourceMessage(
                    event: queryObservable.configuration.path,
                    id: clientId,
                    data: Event(
                        id: record.id,
                        action: .create,
                        record: record
                    )
                )
            }
        } catch {
            print("PocketBase: Error loading records:", error)
            queryObservable.configuration.error = error
        }
    }
    
    public init(_ path: String) {
        let configuration = Configuration(path: path)
        _queryObservable = StateObject(wrappedValue: QueryObservable<U>(configuration: configuration))
    }
    
    public struct Coordinator<U: Codable & Identifiable> where U.ID == String? {
        var query: Query<U>
        
        public init(query: Query<U>) {
            self.query = query
        }
        
        @Sendable public func reconnect(lastEventId: String?) async throws {
            try await query.queryObservable.load(clientId: await query.queryObservable.client.realtime.clientId, lastEventId: lastEventId)
        }
        
        @Sendable public func refresh() async {
            await query.load(clientId: await query.queryObservable.client.realtime.clientId)
        }
    }
}
#endif
