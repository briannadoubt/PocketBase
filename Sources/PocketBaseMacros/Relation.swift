//
//  Relation.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/27/24.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion

public struct Relation: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let binding = declaration.as(VariableDeclSyntax.self)?.bindings.first else {
            throw MacroExpansionErrorMessage(RelationError.mustBeVariable.errorDescription)
        }
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw MacroExpansionErrorMessage(RelationError.missingIdentitifierPattern.errorDescription)
        }
        guard let typeAnnotation = binding.typeAnnotation else {
            throw MacroExpansionErrorMessage(RelationError.mustDefineTypeAnnotation.errorDescription)
        }
        guard let optional = typeAnnotation.type.as(OptionalTypeSyntax.self) else {
            throw MacroExpansionErrorMessage(RelationError.mustBeMarkedAsOptional.errorDescription)
        }
        var type: TokenSyntax
        let isArray = optional.wrappedType.is(ArrayTypeSyntax.self)
        if let arrayType = optional.wrappedType.as(ArrayTypeSyntax.self) {
            guard let element = arrayType.element.as(IdentifierTypeSyntax.self)?.name else {
                throw MacroExpansionErrorMessage(RelationError.missingIdentifierType.errorDescription)
            }
            type = element
        } else {
            guard let wrappedType = optional.wrappedType.as(IdentifierTypeSyntax.self)?.name else {
                throw MacroExpansionErrorMessage(RelationError.missingIdentifierType.errorDescription)
            }
            type = wrappedType
        }
        let name = pattern.identifier
        if isArray {
            return ["var _\(name)Ids: [\(type).ID] = []"]
        }
        if node.hasAttributeArgument("optional") {
            return ["var _\(name)Id: \(type).ID? = nil"]
        }
        return ["var _\(name)Id: \(type).ID"]
    }
}
