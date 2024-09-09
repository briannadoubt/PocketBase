//
//  Relation.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/27/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

enum RelationError: Error {
    case mustBeMarkedAsOptional
}

struct Relation: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let binding = declaration.as(VariableDeclSyntax.self)?.bindings.first,
            let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            return []
        }
        guard
            let optional = binding.typeAnnotation?.type.as(OptionalTypeSyntax.self)
        else {
            context.addDiagnostics(from: RelationError.mustBeMarkedAsOptional, node: binding)
            return []
        }
        guard
            let type = optional.wrappedType.as(IdentifierTypeSyntax.self)?.name.text
        else {
            return []
        }
        let name = pattern.identifier.text
        return [
            "var _\(raw: name)Id: \(raw: type).ID"
        ]
    }
}
