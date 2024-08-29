//
//  Record.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public protocol Record: Identifiable, Codable, Sendable, Equatable, Hashable {
    /// 15 characters string to store as record ID.
    ///
    /// If not set, it will be auto generated when it is created.
    var id: String { get }
    var collectionId: String { get }
    var collectionName: String { get }
    var created: Date { get }
    var updated: Date { get }

    static var collection: String { get }
}

public protocol BaseRecord: Record {}
