//
//  Realtime+Events.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/18/24.
//

import Foundation

/// A raw record event containing unparsed JSON data.
public struct RawRecordEvent: Sendable, Equatable {
    public var id: String?
    public var record: String

    public init(id: String? = nil, record: String) {
        self.id = id
        self.record = record
    }
}

/// A typed record event from realtime subscriptions.
///
/// Contains the action (create, update, delete) and the affected record.
public struct RecordEvent<Record: Decodable & Sendable>: Decodable, Sendable {
    public var id: String?
    public var action: Action
    public var record: Record

    public enum Action: String, Decodable, Sendable {
        case create
        case update
        case delete
    }
}

extension RecordEvent: Equatable where Record: Equatable {}
