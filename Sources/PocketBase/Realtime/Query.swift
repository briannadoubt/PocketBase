//
//  RecordQuery.swift
//  PocketBase
//
//  Created by Bri on 9/21/22.
//

import Alamofire
#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(SwiftUI)
@available(iOS 14.0, macOS 12.0, watchOS 7.0, tvOS 14.0, *)
@propertyWrapper
public struct Query<U: Codable>: DynamicProperty {
    
    @EnvironmentObject var client: PocketBase
    @StateObject var queryObservable: QueryObservable<U>
    
    public struct Configuration {
        public var path: String
        public var error: Error?
        public var interceptor: Interceptor = UserBearerTokenPolicy().interceptor
    }
    
    public var wrappedValue: [U] {
        queryObservable.records
    }
    
    public var projectedValue: Coordinator<U> {
        Coordinator(query: self)
    }
    
    public func load() async {
        do {
            queryObservable.records = try await queryObservable.getRecords().items
        } catch {
            print("PocketBase: Error loading records:", error)
            queryObservable.configuration.error = error
        }
    }
    
    public init(_ path: String, baseUrl: URL?) {
        let configuration = Configuration(path: path)
        _queryObservable = StateObject(wrappedValue: QueryObservable<U>(baseUrl: baseUrl!, configuration: configuration))
    }
    
    public struct Coordinator<T: Codable> {
        var query: Query<T>
        
        public init(query: Query<T>) {
            self.query = query
        }
        
        @Sendable public func load(lastEventId: String?) async throws {
            try await query.queryObservable.load(lastEventId: lastEventId)
        }
        
        @Sendable public func refresh() async {
            await query.load()
        }
    }
}
#endif
