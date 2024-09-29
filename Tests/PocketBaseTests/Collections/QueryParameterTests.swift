//
//  QueryParameterTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/25/24.
//

@testable import PocketBase
import Testing
import SwiftData

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
