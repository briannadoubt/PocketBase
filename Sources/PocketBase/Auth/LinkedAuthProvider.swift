//
//  LinkedAuthProvider.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public struct LinkedAuthProvider: Codable, Sendable, Equatable {
    public var id: String
    public var created: Date
    public var updated: Date
    public var recordId: String
    public var collectionId: String
    public var provider: String
    public var providerId: String
}
