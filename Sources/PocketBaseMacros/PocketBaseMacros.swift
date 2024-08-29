//
//  PocketBaseMacros.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/12/24.
//

import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct PocketBaseMacros: CompilerPlugin {
    var providingMacros: [Macro.Type] = [
        AuthCollection.self,
        BaseCollection.self,
        Filter.self,
        Relation.self,
    ]
}
