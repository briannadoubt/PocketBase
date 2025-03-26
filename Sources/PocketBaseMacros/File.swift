//
//  File.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/24/25.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct File: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let name = declaration.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return []
        }
        return [
            "var _\(raw: name)FileName: String?"  
        ]
    }
}

extension File: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let name = declaration.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return []
        }
        return [
            """
            get {
                guard let _\(raw: name)FileName else {
                    return nil
                }
                return PocketBase().url.appending(
                    path: PocketBase.filePath(
                        Self.collection, 
                        id, 
                        _\(raw: name)FileName
                    )
                )
            }
            """
        ]
    }
}
