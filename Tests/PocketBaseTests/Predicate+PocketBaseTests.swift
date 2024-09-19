//
//  Predicate+PocketBaseTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/25/24.
//

@testable import PocketBase
import Testing
import SwiftData

@BaseCollection("rawrs")
struct Rawr {
    var field: String = ""
}

@Test("Test the #Filter macro output")
func filter() async throws {
    #expect(#Filter<Rawr>({ $0.field == "rawr" && $0.field ~ "meow" || $0.field ~= "woof" }) == Filter(rawValue: "(field=\'rawr\'&&field~\'meow\'||field~=\'woof\')"))
}

@Test func sort() async throws {
    let descriptors = [
        SortDescriptor<Rawr>(\Rawr.created, order: .reverse),
        SortDescriptor<Rawr>(\Rawr.field),
        SortDescriptor<Rawr>(\Rawr.updated, order: .reverse),
    ]
    let string = descriptors.sortParameter()
    #expect(string == "-created,field,-updated")
}
