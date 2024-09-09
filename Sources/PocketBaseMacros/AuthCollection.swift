//
//  AuthCollection.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/12/24.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct AuthCollection {}

extension AuthCollection: MemberMacro {
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
        // Create members for AuthRecord conformance
        var authRecordConformance: [DeclSyntax] = [
            "static let collection: String = \"\(raw: collectionName)\"",
            "var id: String = \"\"",
            "var collectionId: String = \"\"",
            "var collectionName: String = \"\"",
            "var created: Date = Date.distantPast",
            "var updated: Date = Date.distantPast",
            "var verified: Bool = false",
            "var emailVisibility: Bool = false",
            "var username: String = \"\"",
            "var email: String? = nil",
        ]

        let variables = declaration.memberBlock.members
            .map(\.decl)
            .compactMap {
                $0.as(VariableDeclSyntax.self)
            }
        
        let variablesMap: [CollectionVariable] = variables.compactMap { variable in
            guard
                let name = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                var type = variable.bindings.first?.typeAnnotation?.type
            else {
                return nil
            }
            let isRelation = variable.attributes
                .contains { attribute in
                    attribute.description.contains("Relation")
                }
            if
                isRelation,
                let wrappedType = type.as(OptionalTypeSyntax.self)?.wrappedType // Stored record relationship should be optional
            {
                type = wrappedType
            }
            let skipExpand = variable.attributes
                .first { attribute in
                    attribute.description.contains("Relation")
                }?
                .description
                .contains("skipExpand") ?? false
            return CollectionVariable(
                name: name,
                type: type,
                isRelation: isRelation,
                skipExpand: skipExpand
            )
        }
        
        let hasRelations: Bool = variablesMap.contains(where: { $0.isRelation })
        
        let codingKeys: String = variablesMap
            .map(\.name)
            .map(\.text)
            .joined(separator: ", ")
        
        let decode = variablesMap.filter {
            !$0.type.is(ArrayTypeSyntax.self)
        }
        .compactMap { variable in
            "\(variable.name) = try container.decode(\(variable.type).self, forKey: .\(variable.name))"
        }
        .joined(separator: "\n")
        
        let encode = variablesMap.map { variable in
            "try container.encode(\(variable.name), forKey: .\(variable.name))"
        }
        .joined(separator: "\n")
        
        // This is only added if at least one variable is decorated with the `@Relation` macro, and at least one decoration does not contain the `.skipExpand` attribute.
        let relationsSetup: DeclSyntax = !hasRelations ? "" : """
        // Set up relations
            let rawExpand = try container.decode(Data.self, forKey: .expand)
        guard let json = try JSONSerialization.jsonObject(with: rawExpand) as? [String: Any] else {
            throw DecodingError.typeMismatch(
                [String: Any].self,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expand block is not a valid JSON object."
                )
            )
        }
        let expandedRecords = try Self.relations
            .map { key, type in
                guard let raw = json[type.collection] as? [[String: Any]] else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: container.codingPath,
                            debugDescription: "The key '\\(type.collection)' not found in expand values."
                        )
                    )
                }
                guard let rawRecord = raw.first(where: { $0["id"] as? String == id }) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: container.codingPath,
                            debugDescription: "The key 'id' not found in expand values for `\\(type.collection)`."
                        )
                    )
                }
                let recordData = try JSONSerialization.data(withJSONObject: rawRecord)
                return try PocketBase.JSONDecoder().decode(type, from: recordData)
            }
        
        """
        
        let decodeRelations: String = variablesMap.compactMap { variable in
            var decodeRelationship: [String] = []
            guard variable.isRelation else {
                return decodeRelationship
            }
            decodeRelationship.append("_\(variable.name)Id = try container.decode(\(variable.type).ID.self, forKey: .\(variable.name))")
            guard !variable.skipExpand else {
                return decodeRelationship
            }
            decodeRelationship.append(
                """
                \(variable.name) = expandedRecords.first(where: { $0.id == id }) as? \(variable.type)
                """
            )
            return decodeRelationship
        }
        .flatMap({ $0 })
        .joined(separator: "\n")
        
        var initParams = variablesMap
            .map {
                $0.isRelation ? "\($0.name): \($0.type).ID" : "\($0.name): \($0.type)"
            }
            .joined(separator: ", ")
        
        var initBlock = variablesMap
            .map {
                $0.isRelation ? "self._\($0.name)Id = \($0.name)" : "self.\($0.name) = \($0.name)"
            }
            .joined(separator: "\n")
        
        let relations = variablesMap
            .compactMap({ $0.isRelation ? ".\($0.name): \($0.type).self" : nil })
            .joined(separator: ",\n")
        
        let codableConformance: [DeclSyntax] = [
            """
            init(\(raw: initParams)) {
                \(raw: initBlock)
            }
            """,
            """
            static let relations: [CodingKeys: any Record.Type] = [
                \(raw: relations.isEmpty ? ":" : relations)
            ]
            """,
            """
            enum CodingKeys: String, CodingKey {
                case id, collectionName, collectionId, created, updated, expand
                case username, email, verified, emailVisibility
                \(raw: codingKeys.isEmpty ? "" : "case " + codingKeys)
            }
            """,
            """
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                // BaseRecord fields
                let id = try container.decode(String.self, forKey: .id)
                self.id = id 
                collectionName = try container.decode(String.self, forKey: .collectionName)
                collectionId = try container.decode(String.self, forKey: .collectionId)
                created = try container.decode(Date.self, forKey: .created)
                updated = try container.decode(Date.self, forKey: .updated)
            
                // AuthRecord fields
                username = try container.decode(String.self, forKey: .username)
                email = try container.decode(String?.self, forKey: .email)
                verified = try container.decode(Bool.self, forKey: .verified)
                emailVisibility = try container.decode(Bool.self, forKey: .emailVisibility)
            
                \(raw: relationsSetup)
            
                // Declared fields
                \(raw: decode)
            
                // Relation fields
                \(raw: decodeRelations)
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
            
                // AuthRecord fields
                try container.encode(username, forKey: .username)
                try container.encode(email, forKey: .email)
                try container.encode(verified, forKey: .verified)
                try container.encode(emailVisibility, forKey: .emailVisibility)
            
                // Declared fields
                \(raw: encode)
            }
            """
        ]
        return authRecordConformance + codableConformance
    }
}

extension AuthCollection: ExtensionMacro {
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
