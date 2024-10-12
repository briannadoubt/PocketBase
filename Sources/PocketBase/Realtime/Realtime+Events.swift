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
    public var value: Record
    
    public enum Action: String, Decodable, Sendable {
        case create
        case update
        case delete
    }
}
