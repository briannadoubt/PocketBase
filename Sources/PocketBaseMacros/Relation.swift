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

enum RelationError {
    case mustBeMarkedAsOptional
    case missingCollectionName
    case mustDefineTypeAnnotation
    case missingIdentifierType
    case missingIdentitifierPattern
    case mustBeVariable
    
    var errorDescription: String {
        switch self {
        case .mustBeMarkedAsOptional:
            "`Relation` variables must be marked as optional. If the relation is optional on the pocketbase side, use `@Relation(.optional)`, otherwise the relationship will be \"required\" and enforced through a memberwise initializer."
        case .missingCollectionName:
            "Missing collection name. Match the collection name property string to the name of the collection on the pocketbase side. Example: `@BaseCollection(\"cats\")`."
        case .mustDefineTypeAnnotation:
            "Missing type annotation. Match the type to the type of the collection on the pocketbase side. Example: `@Relation var cats: [Cat]?`."
        case .missingIdentifierType:
            "Invalid type. Must be an identifier type. Example: `@Relation var cats: [Cat]?`."
        case .missingIdentitifierPattern:
            "Invalid pattern. Must be an identifier pattern. Example: `@Relation var cats: [Cat]?`."
        case .mustBeVariable:
            "Invalid declaration. Must be a variable declaration. Example: `@Relation var cats: [Cat]?`."
        }
    }
}

struct Relation: PeerMacro {
    static func expansion(
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

struct BackRelation: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
