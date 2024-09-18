//
//  Test.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/15/24.
//

import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.

#if canImport(PocketBaseMacros)
import PocketBaseMacros

let testMacros: [String: Macro.Type] = [
    "AuthCollection": AuthCollection.self,
    "BaseCollection": BaseCollection.self,
    "Filter": Filter.self,
    "Relation": Relation.self,
    "BackRelation": BackRelation.self,
]
#endif

struct BaseRelationTests {
    
    @Test func noVariables() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @BaseCollection("cats")
            struct Cat {}
            """,
            expandedSource: """
            extension Cat: BaseRecord {}
            """,
            macros: testMacros
        )
        #else
        // MARK: macros are only supported when running tests for the host platform
        #endif
    }
}

