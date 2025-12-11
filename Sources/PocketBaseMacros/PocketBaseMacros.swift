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
        File.self,
        Filter.self,
        Relation.self,
        BackRelation.self,
    ]
}
