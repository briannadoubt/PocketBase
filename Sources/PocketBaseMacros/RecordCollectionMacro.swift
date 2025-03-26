//
//  RecordCollectionMacro.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/11/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxBuilder

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
    static func members(
        _ modifiers: DeclModifierListSyntax,
        _ node: AttributeSyntax,
        _ variables: [Variable]
    ) throws -> [DeclSyntax] {
        var members: [DeclSyntax] = []
        members.append(contentsOf: try baseCollectionVariables(modifiers, node))
        if isAuthCollection(node) {
            members.append(contentsOf: try authCollectionVariables(modifiers, node))
        }
        members.append(DeclSyntax(memberwiseInit(modifiers, node, variables)))
        members.append(DeclSyntax(try initFromDecoder(modifiers, node, variables)))
        members.append(DeclSyntax(try encodeToEncoderWithConfiguration(modifiers, node, variables)))
        members.append(DeclSyntax(try relations(modifiers, variables)))
        members.append(DeclSyntax(try codingKeysEnum(modifiers, node, variables)))
        if hasRelations(variables) {
            members.append(DeclSyntax(try expandStruct(modifiers, variables)))
        }
        return members
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try members(
            declaration.modifiers,
            node,
            declaration.variables.parsed(
                modifiers: declaration.modifiers
            )
        )
    }
}

extension DeclModifierListSyntax {
    var isPublic: Bool {
        contains { modifier in
            modifier.name.tokenKind == .keyword(.public)
        }
    }
    
    var modifier: TokenSyntax {
        isPublic
        ? TokenSyntax(TokenKind.keyword(.public), trailingTrivia: .space, presence: .present)
        : TokenSyntax(TokenKind.keyword(.internal), trailingTrivia: .space, presence: .missing)
    }
}

extension VariableDeclSyntax {
    init(
        isPublic: Bool,
        name: PatternSyntax,
        type: TokenSyntax,
        value: some ExprSyntaxProtocol
    ) {
        self.init(
            modifiers: .init {
                if isPublic {
                    DeclModifierSyntax(
                        name: .keyword(.public)
                    )
                }
            },
            .var,
            name: name,
            type: .init(
                type: IdentifierTypeSyntax(name: type)
            ),
            initializer: InitializerClauseSyntax(
                value: value
            )
        )
    }
}

extension DeclSyntax {
    static func variable(
        isPublic: Bool,
        name: PatternSyntax,
        type: TokenSyntax,
        value: some ExprSyntaxProtocol
    ) -> DeclSyntax {
        DeclSyntax(
            VariableDeclSyntax(
                isPublic: isPublic,
                name: name,
                type: type,
                value: value
            )
        )
    }
}

extension RecordCollectionMacro {
    static func authCollectionVariables(
        _ modifiers: DeclModifierListSyntax,
        _ node: AttributeSyntax
    ) throws -> [DeclSyntax] {
        [
            .variable(
                isPublic: modifiers.isPublic,
                name: "verified",
                type: "Bool",
                value: BooleanLiteralExprSyntax(false)
            ),
            .variable(
                isPublic: modifiers.isPublic,
                name: "emailVisibility",
                type: "Bool",
                value: BooleanLiteralExprSyntax(false)
            ),
            .variable(
                isPublic: modifiers.isPublic,
                name: "username",
                type: "String",
                value: StringLiteralExprSyntax(content: "")
            ),
            .variable(
                isPublic: modifiers.isPublic,
                name: "email",
                type: "String?",
                value: NilLiteralExprSyntax()
            )
        ]
    }
    
    static func hasRelations(_ variables: [Variable]) -> Bool {
        variables.contains { variable in
            variable.relation != .none
        }
    }
    
    static func collectionName(_ node: AttributeSyntax) throws -> TokenSyntax {
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
    
    static func memberwiseInitParameters(_ node: AttributeSyntax, _ variables: [Variable]) -> [FunctionParameterSyntax] {
        var parameters: [FunctionParameterSyntax] = []
        if isAuthCollection(node) {
            parameters.append("username: String? = nil")
            parameters.append("email: String? = nil")
            parameters.append("verified: Bool = false")
            parameters.append("emailVisibility: Bool = false")
        }
        for variable in variables {
            if variable.isFile {
                // MARK: Don't add files to initializer because we can't upload files async in a syncronous initializer.
                continue
            }
            if variable.name.text == "row" {
                continue
            }
            switch variable.relation {
            case .none:
                parameters.append("\(variable.name): \(variable.type)")
            case .single:
                if variable.isOptionalRelationship {
                    parameters.append("\(variable.name): String? = nil")
                } else {
                    parameters.append("\(variable.name): String")
                }
            case .multiple:
                parameters.append("\(variable.name): [String] = []")
            case .backwards:
                continue
            }
        }
        return parameters
    }
    
    static func memberwiseInitMembers(_ node: AttributeSyntax, _ variables: [Variable]) -> [CodeBlockItemSyntax] {
        var parameters: [CodeBlockItemSyntax] = []
        if isAuthCollection(node) {
            parameters.append("self.username = username ?? \"\"")
            parameters.append("self.email = email")
            parameters.append("self.verified = verified")
            parameters.append("self.emailVisibility = emailVisibility")
        }
        for variable in variables {
            if variable.isFile {
                // MARK: Don't add files to initializer because we can't upload files async in a syncronous initializer.
                continue
            }
            if variable.name.text == "row" {
                continue
            }
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
    
    static func memberwiseInit(_ modifiers: DeclModifierListSyntax, _ node: AttributeSyntax, _ variables: [Variable]) -> InitializerDeclSyntax {
        InitializerDeclSyntax(
            modifiers: .init {
                DeclModifierSyntax(name: modifiers.modifier)
            },
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parametersBuilder: {
                        for parameter in memberwiseInitParameters(node, variables) {
                            parameter
                        }
                    }
                )
            )
        ) {
            for member in memberwiseInitMembers(node, variables) {
                member
            }
        }
    }
    
    static func initFromDecoder(
        _ modifiers: DeclModifierListSyntax,
        _ node: AttributeSyntax,
        _ variables: [Variable]
    ) throws -> InitializerDeclSyntax {
        try InitializerDeclSyntax(
            "\(modifiers.modifier)init(from decoder: Decoder) throws"
        ) {
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
                "email = try container.decodeIfPresent(String.self, forKey: .email)"
                "verified = try container.decode(Bool.self, forKey: .verified)"
                "emailVisibility = try container.decode(Bool.self, forKey: .emailVisibility)"
            }
            
            if !variables.isEmpty {
                if hasRelations(variables) {
                    "let expand = try container.decodeIfPresent(Expand.self, forKey: .expand)"
                }
                for variable in variables {
                    switch variable.relation {
                    case .none:
                        if variable.name.text != "row" {
                            if variable.isFile {
                                "self._\(variable.name)FileName = try container.decodeIfPresent(String.self, forKey: .\(variable.name))"
                            } else {
                                "self.\(variable.name) = try container.decode(\(variable.type).self, forKey: .\(variable.name))"
                            }
                        }
                    case .single:
                        "self.\(variable.name) = expand?.\(variable.name)"
                        "self._\(variable.name)Id = try container.decode(String.self, forKey: .\(variable.name))"
                    case .multiple:
                        "self.\(variable.name) = expand?.\(variable.name)"
                        "self._\(variable.name)Ids = try container.decode([String].self, forKey: .\(variable.name))"
                    case .backwards:
                        "self.\(variable.name) = expand?.\(variable.name) ?? []"
                    }
                }
            }
        }
    }
    
    static func relationsDictionaryElements(_ variables: [Variable]) throws -> [DictionaryElementSyntax] {
        var elements: [DictionaryElementSyntax] = []
        for variable in variables {
            switch variable.relation {
            case .none:
                continue
            case .single:
                elements.append(
                    DictionaryElementSyntax(
                        key: StringLiteralExprSyntax(content: "\(variable.name)"),
                        value: MemberAccessExprSyntax(
                            base: DeclReferenceExprSyntax(
                                baseName: "\(variable.type)"
                            ),
                            name: .keyword(.self)
                        )
                    )
                )
            case .multiple:
                elements.append(
                    DictionaryElementSyntax(
                        key: StringLiteralExprSyntax(content: "\(variable.name)"),
                        value: MemberAccessExprSyntax(
                            base: DeclReferenceExprSyntax(
                                baseName: "\(variable.type)"
                            ),
                            name: .keyword(.self)
                        )
                    )
                )
            case .backwards(let key):
                elements.append(
                    DictionaryElementSyntax(
                        key: collectionBackRelationStringInterpolation(variable: variable, key: key),
                        value: MemberAccessExprSyntax(
                            base: DeclReferenceExprSyntax(
                                baseName: "\(variable.type)"
                            ),
                            name: .keyword(.self)
                        )
                    )
                )
            }
        }
        return elements
    }
    
    static func relations(
        _ modifiers: DeclModifierListSyntax,
        _ variables: [Variable]
    ) throws -> VariableDeclSyntax {
        return try VariableDeclSyntax("\(modifiers.modifier)static var relations: [String: any Record.Type]") {
            DictionaryExprSyntax {
                if let elements = try? relationsDictionaryElements(variables) {
                    for element in elements {
                        element
                    }
                }
            }
        }
    }
    
    static func codingKeysEnum(
        _ modifiers: DeclModifierListSyntax,
        _ node: AttributeSyntax,
        _ variables: [Variable]
    ) throws -> EnumDeclSyntax {
        try EnumDeclSyntax(
            "\(modifiers.modifier)enum CodingKeys: String, CodingKey"
        ) {
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
    
    static func encodeToEncoderMembers(
        _ node: AttributeSyntax,
        _ variables: [Variable]
    ) -> [CodeBlockItemSyntax] {
        var members: [CodeBlockItemSyntax] = []
        let keysToSkipEncoding: [String] = [
            "id",
            "collectionName",
            "collectionId",
            "created",
            "updated",
            "row",
        ]
        if isAuthCollection(node) {
            members.append("try container.encode(username, forKey: .username)")
            members.append("try container.encode(email, forKey: .email)")
            members.append("try container.encode(verified, forKey: .verified)")
            members.append("try container.encode(emailVisibility, forKey: .emailVisibility)")
        }
        for variable in variables {
            if keysToSkipEncoding.contains(variable.name.text) || variable.isFile {
                continue
            }
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
        return members
    }
    
    static func encodeToEncoderWithConfiguration(
        _ modifiers: DeclModifierListSyntax,
        _ node: AttributeSyntax,
        _ variables: [Variable]
    ) throws -> FunctionDeclSyntax {
        try FunctionDeclSyntax(
            "\(modifiers.modifier)func encode(to encoder: Encoder, configuration: PocketBase.EncodingConfiguration) throws"
        ) {
            "var container = encoder.container(keyedBy: CodingKeys.self)"
        
            "// BaseRecord fields"
            try IfExprSyntax("if configuration == .none") {
                "try container.encode(id, forKey: .id)"
                "try container.encode(collectionName, forKey: .collectionName)"
                "try container.encode(collectionId, forKey: .collectionId)"
                "try container.encode(created, forKey: .created)"
                "try container.encode(updated, forKey: .updated)"
            }
        
            "// Declared fields"
            for member in encodeToEncoderMembers(node, variables) {
                member
            }
        }
    }
    
    static func baseCollectionVariables(
        _ modifiers: DeclModifierListSyntax,
        _ node: AttributeSyntax
    ) throws -> [DeclSyntax] {
        [
            "\(modifiers.modifier)static let collection: String = \"\(try collectionName(node))\"",
            "\(modifiers.modifier)var id: String = \"\"",
            "\(modifiers.modifier)var collectionId: String = \"\"",
            "\(modifiers.modifier)var collectionName: String = \"\"",
            "\(modifiers.modifier)var created: Date = Date.distantPast",
            "\(modifiers.modifier)var updated: Date = Date.distantPast",
            "\(modifiers.modifier)typealias EncodingConfiguration = PocketBase.EncodingConfiguration"
        ]
    }
    
    static func expandStructRelationMembers(
        _ modifiers: DeclModifierListSyntax,
        _ variables: [Variable]
    ) -> [DeclSyntax] {
        var members: [DeclSyntax] = []
        for variable in variables where variable.relation != .none {
            switch variable.relation {
            case .none:
                continue
            case .single:
                members.append("\(modifiers.modifier)var \(variable.name): \(variable.type)?")
            case .multiple:
                members.append("\(modifiers.modifier)var \(variable.name): [\(variable.type)] = []")
            case .backwards:
                members.append("\(modifiers.modifier)var \(variable.name): [\(variable.type)] = []")
            }
        }
        return members
    }
    
    static func expandStruct(
        _ modifiers: DeclModifierListSyntax,
        _ variables: [Variable]
    ) throws -> StructDeclSyntax {
        try StructDeclSyntax("\(modifiers.modifier)struct Expand: Decodable, EncodableWithConfiguration") {
            for member in expandStructRelationMembers(modifiers, variables) {
                member
            }
            try expandStructCodingKeys(modifiers, variables)
            try expandInitFromDecoder(modifiers, variables)
            try expandEncodeToEncoderWithConfiguration(modifiers, variables)
        }
    }
    
    static func expandEncodeToEncoderWithConfiguration(
        _ modifiers: DeclModifierListSyntax,
        _ variables: [Variable]
    ) throws -> FunctionDeclSyntax {
        try FunctionDeclSyntax(
            "\(modifiers.modifier)func encode(to encoder: Encoder, configuration: PocketBase.EncodingConfiguration) throws"
        ) {
            "var container = encoder.container(keyedBy: CodingKeys.self)"
            for variable in variables where variable.relation != .none {
                switch variable.relation {
                case .none:
                    ""
                case .single:
                    "try container.encode(\(variable.name), forKey: .\(variable.name), configuration: configuration)"
                case .multiple:
                    "try container.encode(\(variable.name), forKey: .\(variable.name), configuration: configuration)"
                case .backwards:
                    try IfExprSyntax.init("if configuration == .none") {
                        "try container.encode(\(variable.name), forKey: .\(variable.name), configuration: configuration)"
                    }
                }
            }
        }
    }
    
    static func expandInitFromDecoder(
        _ modifiers: DeclModifierListSyntax,
        _ variables: [Variable]
    ) throws -> InitializerDeclSyntax {
        try InitializerDeclSyntax(
            "\(modifiers.modifier)init(from decoder: Decoder) throws"
        ) {
            "let container = try decoder.container(keyedBy: CodingKeys.self)"
            for variable in variables where variable.relation != .none {
                switch variable.relation {
                case .none:
                    ""
                case .single:
                    "self.\(variable.name) = try container.decodeIfPresent(\(variable.type).self, forKey: .\(variable.name))"
                case .multiple, .backwards:
                    "self.\(variable.name) = try container.decodeIfPresent([\(variable.type)].self, forKey: .\(variable.name)) ?? []"
                }
            }
        }
    }
    
    static func expandCodingKeysRawValue(_ modifiers: DeclModifierListSyntax, _ variables: [Variable]) throws -> VariableDeclSyntax {
        try VariableDeclSyntax(
            modifiers: .init {
                DeclModifierSyntax(name: modifiers.modifier)
            },
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
                                                switch variable.relation {
                                                case .backwards(let key):
                                                    collectionBackRelationStringInterpolation(
                                                        variable: variable,
                                                        key: key
                                                    )
                                                case .single, .multiple, .none:
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
    
    static func collectionBackRelationStringInterpolation(variable: Variable, key: String) -> StringLiteralExprSyntax {
        StringLiteralExprSyntax(
            openingQuote: .stringQuoteToken(),
            segments: StringLiteralSegmentListSyntax {
                ExpressionSegmentSyntax(
                    expressions: LabeledExprListSyntax {
                        LabeledExprSyntax(
                            expression: MemberAccessExprSyntax(
                                base: DeclReferenceExprSyntax(
                                    baseName: "\(raw: variable.type.trimmed)"
                                ),
                                name: "collection"
                            )
                        )
                    }
                )
                StringSegmentSyntax(
                    content: TokenSyntax.stringSegment(
                        "_via_",
                        trailingTrivia: []
                    )
                )
                StringSegmentSyntax(
                    content: TokenSyntax.stringSegment(key, trailingTrivia: [])
                )
            },
            closingQuote: .stringQuoteToken()
        )
    }
    
    static func expandStructCodingKeys(
        _ modifiers: DeclModifierListSyntax,
        _ variables: [Variable]
    ) throws -> EnumDeclSyntax {
        try EnumDeclSyntax(
            "\(modifiers.modifier)enum CodingKeys: String, CodingKey"
        ) {
            for variable in variables where variable.relation != .none {
                EnumCaseDeclSyntax {
                    EnumCaseElementSyntax(name: variable.name)
                }
            }
            try expandCodingKeysRawValue(modifiers, variables)
        }
    }
}
