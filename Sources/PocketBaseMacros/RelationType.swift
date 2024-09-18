//
//  RelationType.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/11/24.
//

import SwiftSyntax
import SwiftSyntaxMacros

enum RelationType {
    case single
    case multiple
    case backwards(key: String)
    case none
    
    init(type: TypeSyntax, _ variable: VariableDeclSyntax) throws {
        if variable.hasAttribute("Relation") {
            if type.isOptional(ArrayTypeSyntax.self) {
                self = .multiple
                return
            } else {
                self = .single
                return
            }
        }
        if variable.hasAttribute("BackRelation") {
            guard let key = variable.backRelationKeyPath() else {
                throw MacroExpansionErrorMessage("Missing keypath in BackRelation attribute")
            }
            self = .backwards(key: key)
            return
        }
        self = .none
    }
}

extension RelationType: Equatable {
    
}
