//
//  RecordCollectionMacro.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/11/24.
//

import SwiftSyntax
import SwiftSyntaxMacros

protocol RecordCollectionMacro: MemberMacro, ExtensionMacro {}

public struct AuthCollection: RecordCollectionMacro {}
public struct BaseCollection: RecordCollectionMacro {}

extension RecordCollectionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        [
            ExtensionDeclSyntax(
                extendedType: type,
                inheritanceClause: InheritanceClauseSyntax {
                    for type in protocols {
                        InheritedTypeSyntax(type: type)
                    }
                },
                memberBlock: MemberBlockSyntax(
                    membersBuilder: {}
                )
            )
        ]
    }
}

extension RecordCollectionMacro {
    static func members(_ node: AttributeSyntax, _ variables: [Variable]) throws -> [DeclSyntax] {
        var members: [DeclSyntax] = []
        members.append(contentsOf: try baseCollectionVariables(node))
        if isAuthCollection(node) {
            members.append(contentsOf: try authCollectionVariables(node))
        }
        members.append(DeclSyntax(memberwiseInit(variables)))
        members.append(DeclSyntax(try initFromDecoder(node, variables)))
        members.append(DeclSyntax(try encodeToEncoder(node, variables)))
        members.append(DeclSyntax(try relations(variables)))
        members.append(DeclSyntax(try codingKeysEnum(node, variables)))
        if hasRelations(variables) {
            members.append(DeclSyntax(try expandStruct(variables)))
        }
        return members
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try members(node, declaration.variables.parsed)
    }
}

extension RecordCollectionMacro {
    static func authCollectionVariables(_ node: AttributeSyntax) throws -> [DeclSyntax] {
        [
            "var verified: Bool = false",
            "var emailVisibility: Bool = false",
            "var username: String = \"\"",
            "var email: String? = nil",
        ]
    }
    
    static func hasRelations(_ variables: [Variable]) -> Bool {
        variables.contains { variable in
            variable.relation != .none
        }
    }
    
    static func collectionName(_ node: AttributeSyntax) throws -> TokenSyntax? {
        guard let collectionName = node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .first?
            .expression
            .as(StringLiteralExprSyntax.self)?
            .segments
            .first?
            .as(StringSegmentSyntax.self)?
            .content
        else {
            throw MacroExpansionErrorMessage(RelationError.missingCollectionName.errorDescription)
        }
        return collectionName
    }
    
    static func isAuthCollection(_ node: AttributeSyntax) -> Bool {
        node.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "AuthCollection"
    }
    
    static func memberwiseInitParameters(_ variables: [Variable]) -> [FunctionParameterSyntax] {
        var parameters: [FunctionParameterSyntax] = []
        for variable in variables {
            switch variable.relation {
            case .none:
                parameters.append("\(variable.name): \(variable.type)")
            case .single:
                if variable.isOptionalRelationship {
                    parameters.append("\(variable.name): \(variable.type).ID? = nil")
                } else {
                    parameters.append("\(variable.name): \(variable.type).ID")
                }
            case .multiple:
                parameters.append("\(variable.name): [\(variable.type).ID] = []")
            case .backwards:
                continue
            }
        }
        return parameters
    }
    
    static func memberwiseInitMembers(_ variables: [Variable]) -> [CodeBlockItemSyntax] {
        var parameters: [CodeBlockItemSyntax] = []
        for variable in variables {
            switch variable.relation {
            case .none:
                parameters.append("self.\(variable.name) = \(variable.name)")
            case .single:
                parameters.append("self._\(variable.name)Id = \(variable.name)")
            case .multiple:
                parameters.append("self._\(variable.name)Ids = \(variable.name)")
            case .backwards:
                continue
            }
        }
        return parameters
    }
    
    static func memberwiseInit(_ variables: [Variable]) -> InitializerDeclSyntax {
        InitializerDeclSyntax(
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parametersBuilder: {
                        memberwiseInitParameters(variables)
                    }
                )
            )
        ) {
            memberwiseInitMembers(variables)
        }
    }
    
    static func initFromDecoder(_ node: AttributeSyntax, _ variables: [Variable]) throws -> InitializerDeclSyntax {
        try InitializerDeclSyntax("init(from decoder: Decoder) throws") {
            "let container = try decoder.container(keyedBy: CodingKeys.self)"
            "// Base Collection Fields"
            "let id = try container.decode(String.self, forKey: .id)"
            "self.id = id"
            "collectionName = try container.decode(String.self, forKey: .collectionName)"
            "collectionId = try container.decode(String.self, forKey: .collectionId)"
            "created = try container.decode(Date.self, forKey: .created)"
            "updated = try container.decode(Date.self, forKey: .updated)"
            
            if isAuthCollection(node) {
                "// Auth Collection Fields"
                "username = try container.decode(String.self, forKey: .username)"
                "email = try container.decode(String?.self, forKey: .email)"
                "verified = try container.decode(Bool.self, forKey: .verified)"
                "emailVisibility = try container.decode(Bool.self, forKey: .emailVisibility)"
            }
            
            if !variables.isEmpty {
                if hasRelations(variables) {
                    "let expand = try container.decode(Expand.self, forKey: .expand)"
                }
                for variable in variables {
                    switch variable.relation {
                    case .none:
                        "self.\(variable.name) = try container.decode(\(variable.type).self, forKey: .\(variable.name))"
                    case .single:
                        "self.\(variable.name) = expand.\(variable.name)"
                        "self._\(variable.name)Id = try container.decode(\(variable.type).ID.self, forKey: .\(variable.name))"
                    case .multiple:
                        "self.\(variable.name) = expand.\(variable.name)"
                        "self._\(variable.name)Ids = try container.decode([\(variable.type).ID].self, forKey: .\(variable.name))"
                    case .backwards:
                        if variable.isOptionalRelationship {
                            "self.\(variable.name) = expand.\(variable.name) ?? []"
                        } else {
                            "self.\(variable.name) = expand.\(variable.name)"
                        }
                    }
                }
            }
        }
    }
    
    static func relations(_ variables: [Variable]) throws -> VariableDeclSyntax {
        try VariableDeclSyntax("static var relations: [String: any Record.Type]") {
            DictionaryExprSyntax(
                contentBuilder: {
                    for variable in variables {
                        switch variable.relation {
                        case .none:
                            .init()
                        case .single:
                            DictionaryElementSyntax(
                                key: StringLiteralExprSyntax(content: "\(variable.name)"),
                                value: MemberAccessExprSyntax(
                                    base: DeclReferenceExprSyntax(
                                        baseName: "\(variable.type)"
                                    ),
                                    name: .keyword(.self)
                                )
                            )
                        case .multiple:
                            if let elementType = variable
                                .type
                                .as(OptionalTypeSyntax.self)?
                                .wrappedType
                                .as(ArrayTypeSyntax.self)?
                                .element
                            {
                                DictionaryElementSyntax(
                                    key: StringLiteralExprSyntax(content: "\(variable.name)"),
                                    value: MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(
                                            baseName: "\(elementType)"
                                        ),
                                        name: .keyword(.self)
                                    )
                                )
                            }
                        case .backwards:
                            if let elementType = variable
                                .type
                                .as(ArrayTypeSyntax.self)?
                                .element
                            {
                                DictionaryElementSyntax(
                                    key: StringLiteralExprSyntax(content: "\(variable.name)"),
                                    value: MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(
                                            baseName: "\(elementType)"
                                        ),
                                        name: .keyword(.self)
                                    )
                                )
                            }
                        }
                    }
                }
            )
        }
    }
    
    static func codingKeysEnum(_ node: AttributeSyntax, _ variables: [Variable]) throws -> EnumDeclSyntax {
        try EnumDeclSyntax("enum CodingKeys: String, CodingKey") {
            "case id, collectionName, collectionId, created, updated, expand"
            if isAuthCollection(node) {
                "case verified, emailVisibility, username, email"
            }
            if !variables.isEmpty {
                EnumCaseDeclSyntax() {
                    for variable in variables {
                        EnumCaseElementSyntax(name: variable.name)
                    }
                }
            }
        }
    }
    
    static func encodeToEncoderMembers(_ variables: [Variable]) -> [CodeBlockItemSyntax] {
        var members: [CodeBlockItemSyntax] = []
        let keysToSkipEncoding: [String] = [
            "id",
            "collectionName",
            "collectionId",
            "created",
            "updated"
        ]
        for variable in variables {
            if keysToSkipEncoding.contains(variable.name.text) == false {
                switch variable.relation {
                case .none:
                    members.append("try container.encode(\(variable.name), forKey: .\(variable.name))")
                case .single:
                    members.append("try container.encode(_\(variable.name)Id, forKey: .\(variable.name))")
                case .multiple:
                    members.append("try container.encode(_\(variable.name)Ids, forKey: .\(variable.name))")
                case .backwards:
                    continue
                }
            }
        }
        return members
    }
    
    static func encodeToEncoder(_ node: AttributeSyntax, _ variables: [Variable]) throws -> FunctionDeclSyntax {
        try FunctionDeclSyntax("func encode(to encoder: Encoder) throws") {
            "var container = encoder.container(keyedBy: CodingKeys.self)"
        
            "// BaseRecord fields"
            "try container.encode(id, forKey: .id)"
            "try container.encode(collectionName, forKey: .collectionName)"
            "try container.encode(collectionId, forKey: .collectionId)"
            "try container.encode(created, forKey: .created)"
            "try container.encode(updated, forKey: .updated)"
        
            "// Declared fields"
            encodeToEncoderMembers(variables)
        }
    }
    
    static func baseCollectionVariables(_ node: AttributeSyntax) throws -> [DeclSyntax] {
        [
            "static let collection: String = \"\(try collectionName(node))\"",
            "var id: String = \"\"",
            "var collectionId: String = \"\"",
            "var collectionName: String = \"\"",
            "var created: Date = Date.distantPast",
            "var updated: Date = Date.distantPast",
        ]
    }
    
    static func expandStruct(_ variables: [Variable]) throws -> StructDeclSyntax {
        try StructDeclSyntax("struct Expand: Codable") {
            for variable in variables where variable.relation != .none {
                switch variable.relation {
                case .none: 
                    ""
                case .single:
                    "var \(variable.name): \(variable.type)?"
                case .multiple:
                    "var \(variable.name): [\(variable.type)]?"
                case .backwards:
                    "var \(variable.name): [\(variable.type)] = []"
                }
            }
            try expandStructCodingKeys(variables)
        }
    }
    
    static func expandCodingKeysRawValue(_ variables: [Variable]) throws -> VariableDeclSyntax {
        try VariableDeclSyntax(
            bindingSpecifier: "var"
        ) {
            PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: "rawValue"),
                typeAnnotation: TypeAnnotationSyntax(
                    type: IdentifierTypeSyntax(name: "String")
                ),
                accessorBlock: AccessorBlockSyntax(
                    accessors: .getter(
                        try CodeBlockItemListSyntax {
                            try SwitchExprSyntax("switch self") {
                                for variable in variables where variable.relation != .none {
                                    SwitchCaseListSyntax {
                                        SwitchCaseSyntax("case .\(variable.name):") {
                                            CodeBlockItemListSyntax {
                                                if variable.relation == .backwards {
                                                    StringLiteralExprSyntax(
                                                        openingQuote: TokenSyntax.stringQuoteToken(),
                                                        segments: StringLiteralSegmentListSyntax {
                                                            ExpressionSegmentSyntax(
                                                                expressions: LabeledExprListSyntax {
                                                                    LabeledExprSyntax(
                                                                        expression: MemberAccessExprSyntax(
                                                                            base: DeclReferenceExprSyntax(
                                                                                baseName: "\(variable.type)"
                                                                            ),
                                                                            name: "collection"
                                                                        )
                                                                    )
                                                                }
                                                            )
                                                            StringSegmentSyntax(
                                                                content: "_via_\(variable.name)"
                                                            )
                                                        },
                                                        closingQuote: TokenSyntax.stringQuoteToken()
                                                    )
                                                } else {
                                                    StringLiteralExprSyntax(content: "\(variable.name)")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    )
                )
            )
        }
    }
    
    static func expandStructCodingKeys(_ variables: [Variable]) throws -> EnumDeclSyntax {
        try EnumDeclSyntax("enum CodingKeys: String, CodingKey") {
            for variable in variables where variable.relation != .none {
                EnumCaseDeclSyntax {
                    EnumCaseElementSyntax(name: variable.name)
                }
            }
            try expandCodingKeysRawValue(variables)
        }
    }
}
