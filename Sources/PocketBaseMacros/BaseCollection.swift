//
//  BaseCollection.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/12/24.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct BaseCollection {}

//extension BaseCollection: AccessorMacro {
//    public static func expansion(
//        of node: AttributeSyntax,
//        providingAccessorsOf declaration: some DeclSyntaxProtocol,
//        in context: some MacroExpansionContext
//    ) throws -> [AccessorDeclSyntax] {
//        ["@Model"]
//    }
//}

//extension BaseCollection: PeerMacro {
//    public static func expansion(
//        of node: AttributeSyntax,
//        providingPeersOf declaration: some DeclSyntaxProtocol,
//        in context: some MacroExpansionContext
//    ) throws -> [DeclSyntax] {
//        ["@Model"]
//    }
//}



extension BaseCollection: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract the collection name
        guard
            let arguments = node.arguments,
            let labeledList = arguments.as(LabeledExprListSyntax.self),
            let argument = labeledList.first,
            let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
            let stringSegment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
        else {
            return []
        }
        let collectionName = stringSegment.content.text
        // Create members for BaseRecord conformance
        let baseRecordConformance: [DeclSyntax] = [
            "static let collection: String = \"\(raw: collectionName)\"",
            "var id: String = \"\"",
            "var collectionId: String = \"\"",
            "var collectionName: String = \"\"",
            "var created: Date = Date.distantPast",
            "var updated: Date = Date.distantPast",
        ]

        let variableBindings = declaration.memberBlock.members
            .map(\.decl)
            .compactMap {
                $0.as(VariableDeclSyntax.self)
            }
            .map(\.bindings)
            .compactMap(\.first)
        
        let variables: [(name: TokenSyntax, type: TypeSyntax)] = variableBindings.compactMap {
            (
                name: $0.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                type: $0.typeAnnotation?.type.trimmed
            )
        }
        .compactMap { (name: TokenSyntax?, type: TypeSyntax?) in
            guard let name, let type else { return nil }
            return (name: name, type: type)
        }
        
        let codingKeys = variables
            .map(\.name)
            .map(\.text)
            .joined(separator: ", ")
        
        let decode = variables.filter {
            !$0.type.is(ArrayTypeSyntax.self)
        }
        .map { name, type in
            "\(name) = try container.decode(\(type).self, forKey: .\(name))"
        }
        .joined(separator: "\n")
        
        let encode = variables.map { name, type in
            "try container.encode(\(name), forKey: .\(name))"
        }
        .joined(separator: "\n")
        
        let codableConformance: [DeclSyntax] = [
            """
            enum CodingKeys: String, CodingKey {
                case id, collectionName, collectionId, created, updated
                case \(raw: codingKeys)
            }
            """,
            """
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                // BaseRecord fields
                id = try container.decode(String.self, forKey: .id)
                collectionName = try container.decode(String.self, forKey: .collectionName)
                collectionId = try container.decode(String.self, forKey: .collectionId)
                created = try container.decode(Date.self, forKey: .created)
                updated = try container.decode(Date.self, forKey: .updated)
            
                // Declared fields
                \(raw: decode)
            }
            """,
            """
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
            
                // BaseRecord fields
                try container.encode(id, forKey: .id)
                try container.encode(collectionName, forKey: .collectionName)
                try container.encode(collectionId, forKey: .collectionId)
                try container.encode(created, forKey: .created)
                try container.encode(updated, forKey: .updated)
            
                // Declared fields
                \(raw: encode)
            }
            """
        ]
        return baseRecordConformance + codableConformance
    }
}

extension BaseCollection: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let rawProtocols = protocols.compactMap({ $0.as(IdentifierTypeSyntax.self) }).map(\.name.text).joined(separator: ", ")
        let decl: DeclSyntax = """
        extension \(type.trimmed): \(raw: rawProtocols) {}
        """
        guard let extensionDecl = decl.as(ExtensionDeclSyntax.self) else {
            return []
        }
        return [extensionDecl]
    }
}
