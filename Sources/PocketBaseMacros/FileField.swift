//
//  FileField.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion

/// Errors that can occur during FileField macro expansion.
enum FileFieldError {
    case mustBeVariable
    case missingIdentifierPattern
    case mustDefineTypeAnnotation
    case invalidType

    var errorDescription: String {
        switch self {
        case .mustBeVariable:
            "`@FileField` must be applied to a variable declaration."
        case .missingIdentifierPattern:
            "Invalid pattern. Must be an identifier pattern. Example: `@FileField var avatar: String?`."
        case .mustDefineTypeAnnotation:
            "Missing type annotation. Example: `@FileField var avatar: String?` or `@FileField var documents: [String]`."
        case .invalidType:
            "File fields must be `String?` (single file) or `[String]` (multiple files)."
        }
    }
}

/// The `@FileField` macro marks a property as a file field.
///
/// File fields are tracked separately from regular fields and are excluded from
/// JSON encoding during create/update operations (since files are sent via multipart).
///
/// The macro itself is a peer macro that doesn't generate any additional declarations,
/// but its presence is detected by the RecordCollectionMacro to:
/// - Skip the field during JSON encoding
/// - Include it in the generated `fileFields` static property
public struct FileField: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate that this is applied to a variable
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
              let binding = variableDecl.bindings.first else {
            throw MacroExpansionErrorMessage(FileFieldError.mustBeVariable.errorDescription)
        }

        // Validate pattern
        guard binding.pattern.as(IdentifierPatternSyntax.self) != nil else {
            throw MacroExpansionErrorMessage(FileFieldError.missingIdentifierPattern.errorDescription)
        }

        // Validate type annotation exists
        guard let typeAnnotation = binding.typeAnnotation else {
            throw MacroExpansionErrorMessage(FileFieldError.mustDefineTypeAnnotation.errorDescription)
        }

        // Validate type is String?, [String], or [String]?
        let type = typeAnnotation.type
        let isValidType = isValidFileFieldType(type)

        guard isValidType else {
            throw MacroExpansionErrorMessage(FileFieldError.invalidType.errorDescription)
        }

        // FileField is a marker macro - it doesn't generate peer declarations
        // Its presence is detected by RecordCollectionMacro to handle encoding
        return []
    }

    /// Checks if the type is valid for a file field.
    ///
    /// Valid types are:
    /// - `String?` (single optional file)
    /// - `[String]` (multiple files, non-optional array)
    /// - `[String]?` (multiple files, optional array)
    private static func isValidFileFieldType(_ type: TypeSyntax) -> Bool {
        // Check for String?
        if let optional = type.as(OptionalTypeSyntax.self) {
            // String?
            if let identifier = optional.wrappedType.as(IdentifierTypeSyntax.self),
               identifier.name.text == "String" {
                return true
            }
            // [String]?
            if let array = optional.wrappedType.as(ArrayTypeSyntax.self),
               let element = array.element.as(IdentifierTypeSyntax.self),
               element.name.text == "String" {
                return true
            }
        }

        // Check for [String]
        if let array = type.as(ArrayTypeSyntax.self),
           let element = array.element.as(IdentifierTypeSyntax.self),
           element.name.text == "String" {
            return true
        }

        return false
    }
}
