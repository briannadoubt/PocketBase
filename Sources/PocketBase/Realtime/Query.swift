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
public struct Query<T: Codable>: DynamicProperty {
    
    @StateObject var queryObservable: QueryObservable<T>
    
    public struct Configuration {
        public var path: String
        public var error: Error?
    }
    
    public var wrappedValue: T {
        queryObservable.records
    }
    
    public var projectedValue: Coordinator<T> {
        Coordinator(query: self)
    }
    
    public func refresh<U: Codable>() async where T == [U] {
        await queryObservable.getRecords()
    }
    
    public init<U: Codable>(_ path: String) where T == [U] {
        let configuration = Configuration(path: path)
        _queryObservable = StateObject(wrappedValue: QueryObservable<T>(configuration: configuration))
    }
    
    public struct Coordinator<T: Codable> {
        var query: Query<T>
        
        public init(query: Query<T>) {
            self.query = query
        }
        
        @Sendable public func refresh<U: Codable>() async where T == [U] {
            await query.refresh()
        }
    }
}
#endif
