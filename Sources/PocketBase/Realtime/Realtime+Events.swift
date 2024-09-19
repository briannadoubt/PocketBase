//
//  Realtime+Events.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/18/24.
//

import Foundation

public protocol Event: Sendable, Equatable {
    associatedtype Value = Decodable
    var id: String? { get }
    var value: Value { get }
}

public struct RawRecordEvent: Event {
    public var id: String?
    public var value: String
}

public protocol DecodableEvent: Event, Decodable {}

public struct RecordEvent<Record: BaseRecord>: DecodableEvent {
    public var id: String?
    public var action: Action
    public var record: Record
    public var value: Record { record }
    
    public init(id: String?, action: Action, record: Record) {
        self.id = id
        self.action = action
        self.record = record
    }
    
    public enum Action: String, Decodable, Sendable {
        case create
        case update
        case delete
    }
}
