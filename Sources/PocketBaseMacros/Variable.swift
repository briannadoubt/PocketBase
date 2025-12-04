//
//  Variable.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/10/24.
//

import SwiftSyntax
import SwiftSyntaxMacros

enum VariableError: Error {
    case missingName
    case missingType
}

struct Variable {
    var name: TokenSyntax
    var type: TypeSyntax
    var isArray: Bool
    var isDate: Bool
    var relation: RelationType
    var skipExpand: Bool
    var isOptionalRelationship: Bool
    var isFileField: Bool
    var isFileFieldRequired: Bool
    var modifiers: DeclModifierListSyntax

    init(modifiers: DeclModifierListSyntax, _ variable: VariableDeclSyntax) throws {
        self.modifiers = modifiers
        guard let name = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed else {
            throw VariableError.missingName
        }
        self.name = name
        guard let type = variable.bindings.first?.typeAnnotation?.type.trimmed else {
            throw VariableError.missingType
        }
        if let array = type.as(ArrayTypeSyntax.self) {
            self.type = array.element.trimmed
        } else if let optional = type.as(OptionalTypeSyntax.self) {
            if let array = optional.wrappedType.as(ArrayTypeSyntax.self) {
                self.type = array.element.trimmed
            } else {
                self.type = optional.wrappedType.trimmed
            }
        } else {
            self.type = type.trimmed
        }
        self.isArray = type.isOptional(ArrayTypeSyntax.self) || type.is(ArrayTypeSyntax.self)
        self.isDate = type.hasTypeIdentifier("Date")
        self.relation = try RelationType(type: type, variable)
        self.skipExpand = variable.hasAttributeArgument("skipExpand")
        self.isOptionalRelationship = variable.hasAttributeArgument("optional")
        self.isFileField = variable.hasAttribute("FileField")
        self.isFileFieldRequired = variable.hasAttributeArgument("required")
    }
}

extension Collection where Element == VariableDeclSyntax {
    func parsed(modifiers: DeclModifierListSyntax) throws -> [Variable] {
        try map {
            try Variable(
                modifiers: modifiers,
                $0
            )
        }
    }
}
