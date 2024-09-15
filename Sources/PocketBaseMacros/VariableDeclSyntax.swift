//
//  VariableDeclSyntax.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/11/24.
//

import SwiftSyntax
import SwiftSyntaxMacros

extension VariableDeclSyntax {
    func hasAttribute(_ name: String) -> Bool {
        return attributes.contains { attribute in
            guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
            if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
                return identifier.name.text == name
            }
            return false
        }
    }
}


extension VariableDeclSyntax {
    func hasAttributeArgument(_ name: String) -> Bool {
        return attributes.contains { attribute in
            guard let attribute = attribute.as(AttributeSyntax.self) else {
                return false
            }
            return attribute.hasAttributeArgument(name)
        }
    }
}

extension AttributeSyntax {
    func hasAttributeArgument(_ name: String) -> Bool {
        guard let argumentList = arguments?.as(LabeledExprListSyntax.self) else {
            return false
        }
        return argumentList.contains { element in
            if let identifierExpr = element.expression.as(DeclReferenceExprSyntax.self) {
                return identifierExpr.baseName.text == name
            }
            return false
        }
    }
}
