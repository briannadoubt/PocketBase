//
//  TypeSyntax+.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/11/24.
//

import SwiftSyntax
import SwiftSyntaxMacros

extension TypeSyntax {
    func isOptional(_ syntaxType: TypeSyntaxProtocol.Type) -> Bool {
        self.is(syntaxType)
        || self.as(OptionalTypeSyntax.self)?.wrappedType.is(syntaxType) ?? false
    }
    
    func hasTypeIdentifier(_ identifier: TokenSyntax) -> Bool {
        self.as(IdentifierTypeSyntax.self)?.name.text == identifier.text
        || self.as(OptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?.name.text == identifier.text
    }
}
