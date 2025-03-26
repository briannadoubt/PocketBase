//
//  BackRelation.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/24/25.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct BackRelation: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
