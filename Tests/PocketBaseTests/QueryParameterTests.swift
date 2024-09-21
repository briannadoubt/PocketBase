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
struct Tester {
    @Relation var rawrs: [Rawr]?
    
    init(rawrs: [Rawr]? = nil) {
        self.rawrs = rawrs
    }
}

@BaseCollection("rawrs")
struct Rawr {
    var field: String = ""
}

@Suite("Query parametertests")
struct QueryParameterTests {
    @Test("#Filter macro output")
    func filter() async throws {
        #expect(#Filter<Rawr>({ $0.field == "rawr" && $0.field ~ "meow" || $0.field ~= "woof" }) == Filter(rawValue: "(field=\'rawr\'&&field~\'meow\'||field~=\'woof\')"))
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
