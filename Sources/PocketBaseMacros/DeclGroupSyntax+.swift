//
//  DeclGroupSyntax+.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/11/24.
//

import SwiftSyntax
import SwiftSyntaxMacros

extension DeclGroupSyntax {
    var variables: [VariableDeclSyntax] {
        memberBlock.members
            .map(\.decl)
            .compactMap { decl in
                decl.as(VariableDeclSyntax.self)
            }
    }
}
