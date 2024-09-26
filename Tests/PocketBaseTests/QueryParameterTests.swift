//
//  QueryParameterTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/25/24.
//

@testable import PocketBase
import Testing
import SwiftData

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
}

@Suite("Query parameter tests")
struct QueryParameterTests {
    @Test("#Filter macro output")
    func filter() async throws {
        #expect(#Filter<Rawr>({ $0.field == "rawr" && $0.field ~ "meow" || $0.field ~= "woof" }) == Filter(rawValue: "(field=\'rawr\'&&field~\'meow\'||field~=\'woof\')"))
    }
    
    @Test("Filter Parameter Infix Operators")
    func infixOperators() {
        let foo = "foo"
        let bar = "bar"
        #expect((foo ~ bar) == false)
        #expect((foo !~ bar) == false)
        #expect((foo ?= bar) == false)
        #expect((foo ?!= bar) == false)
        #expect((foo ?> bar) == false)
        #expect((foo ?>= bar) == false)
        #expect((foo ?< bar) == false)
        #expect((foo ?<= bar) == false)
        #expect((foo ?~ bar) == false)
        #expect((foo ?!~ bar) == false)
    }
    
    @Test("SortDescriptor to string output")
    func sort() async throws {
        let descriptors = [
            SortDescriptor<Rawr>(\Rawr.created, order: .reverse),
            SortDescriptor<Rawr>(\Rawr.field),
            SortDescriptor<Rawr>(\Rawr.updated, order: .reverse),
        ]
        let string = descriptors.sortParameter()
        #expect(string == "-created,field,-updated")
    }
}
