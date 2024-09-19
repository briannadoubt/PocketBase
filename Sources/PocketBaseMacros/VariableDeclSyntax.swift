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
    
    func backRelationKeyPath() -> String? {
        guard
            let attribute = attributes.first?.as(AttributeSyntax.self),
            let labeledExpressionList = attribute.arguments?.as(LabeledExprListSyntax.self),
            let labeledExpression = labeledExpressionList.first,
            let keyPathExpression = labeledExpression.expression.as(KeyPathExprSyntax.self),
            let component = keyPathExpression.components.first,
            let propertyComponent = component.component.as(KeyPathPropertyComponentSyntax.self)
        else {
            return nil
        }
        let referenceExpression = propertyComponent.declName.baseName
        return referenceExpression.text
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
