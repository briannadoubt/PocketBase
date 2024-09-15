//
//  RelationType.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/11/24.
//

import SwiftSyntax

enum RelationType {
    case single
    case multiple
    case backwards
    case none
    
    init(type: TypeSyntax, _ variable: VariableDeclSyntax) {
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
            self = .backwards
            return
        }
        self = .none
    }
}
