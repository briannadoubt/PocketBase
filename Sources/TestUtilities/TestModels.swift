//
//  Tester.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/28/24.
//

import PocketBase

@AuthCollection("testers")
public struct Tester {
    
    @Relation public var rawrs: [Rawr]?
    
    public init(id: String, username: String) {
        self.id = id
        self.username = username
        self.created = Self.date
        self.updated = Self.date
        self.collectionName = Self.collection
    }
}

public extension Tester {
    static let date = Date()
}

@BaseCollection("rawrs")
public struct Rawr {
    public var field: String = ""
    @BackRelation(\Tester.rawrs) public var testers: [Tester] = []

    public init(id: String, field: String) {
        self.id = id
        self.field = field
        self.created = Self.date
        self.updated = Self.date
        self.collectionName = Self.collection
    }
}

public extension Rawr {
    static let date = Date()
}

/// A test model that includes file fields for testing file upload functionality.
/// Uses the unified `FileValue` type for auto-detection of pending uploads.
@BaseCollection("posts")
public struct Post {
    public var title: String = ""
    @FileField public var coverImage: FileValue? = nil
    @FileField public var attachments: [FileValue]? = nil
}
