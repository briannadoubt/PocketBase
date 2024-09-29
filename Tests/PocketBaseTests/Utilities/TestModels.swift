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
    
    init(id: String, username: String) {
        self.id = id
        self.username = username
        self.created = Self.date
        self.updated = Self.date
        self.collectionName = Self.collection
    }
}

extension Tester {
    static let date = Date()
}

@BaseCollection("rawrs")
public struct Rawr {
    var field: String = ""
    @BackRelation(\Tester.rawrs) var testers: [Tester] = []
    
    init(id: String, field: String) {
        self.id = id
        self.field = field
        self.created = Self.date
        self.updated = Self.date
        self.collectionName = Self.collection
    }
}

extension Rawr {
    static let date = Date()
}
