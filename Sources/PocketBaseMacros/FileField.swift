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
    case mustBeMarkedAsOptional
    case invalidType

    var errorDescription: String {
        switch self {
        case .mustBeVariable:
            "`@FileField` must be applied to a variable declaration."
        case .missingIdentifierPattern:
            "Invalid pattern. Must be an identifier pattern. Example: `@FileField var avatar: RecordFile?`."
        case .mustDefineTypeAnnotation:
            "Missing type annotation. Example: `@FileField var avatar: RecordFile?` or `@FileField var documents: [RecordFile]?`."
        case .mustBeMarkedAsOptional:
            "`@FileField` variables must be marked as optional. Example: `@FileField var avatar: RecordFile?` or `@FileField var documents: [RecordFile]?`."
        case .invalidType:
            "File fields must be `RecordFile?`, `FileValue?` (single file) or `[RecordFile]?`, `[FileValue]?` (multiple files)."
        }
    }
}

/// The `@FileField` macro marks a property as a file field and generates backing storage.
///
/// Similar to `@Relation`, this macro generates a hidden property to store the raw
/// filename(s) while the visible property holds hydrated `RecordFile` objects.
///
/// For `@FileField var avatar: RecordFile?`:
/// - Generates: `var _avatarFilename: String?`
///
/// For `@FileField var documents: [RecordFile]?`:
/// - Generates: `var _documentsFilenames: [String] = []`
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
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw MacroExpansionErrorMessage(FileFieldError.missingIdentifierPattern.errorDescription)
        }

        // Validate type annotation exists
        guard let typeAnnotation = binding.typeAnnotation else {
            throw MacroExpansionErrorMessage(FileFieldError.mustDefineTypeAnnotation.errorDescription)
        }

        // Must be optional
        guard let optional = typeAnnotation.type.as(OptionalTypeSyntax.self) else {
            throw MacroExpansionErrorMessage(FileFieldError.mustBeMarkedAsOptional.errorDescription)
        }

        // Validate type is RecordFile? or [RecordFile]?
        let isValidType = isValidFileFieldType(optional.wrappedType)
        guard isValidType else {
            throw MacroExpansionErrorMessage(FileFieldError.invalidType.errorDescription)
        }

        let name = pattern.identifier
        let isArray = optional.wrappedType.is(ArrayTypeSyntax.self)

        // Generate backing storage property
        if isArray {
            // For [RecordFile]? generate var _<name>Filenames: [String] = []
            return ["var _\(name)Filenames: [String] = []"]
        } else {
            // For RecordFile? generate var _<name>Filename: String?
            return ["var _\(name)Filename: String?"]
        }
    }

    /// Checks if the type is valid for a file field.
    ///
    /// Valid types are:
    /// - `RecordFile` (for RecordFile?)
    /// - `FileValue` (for FileValue?)
    /// - `[RecordFile]` (for [RecordFile]?)
    /// - `[FileValue]` (for [FileValue]?)
    private static func isValidFileFieldType(_ type: TypeSyntax) -> Bool {
        // Check for RecordFile or FileValue
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            let name = identifier.name.text
            if name == "RecordFile" || name == "FileValue" {
                return true
            }
        }

        // Check for [RecordFile] or [FileValue]
        if let array = type.as(ArrayTypeSyntax.self),
           let element = array.element.as(IdentifierTypeSyntax.self) {
            let name = element.name.text
            if name == "RecordFile" || name == "FileValue" {
                return true
            }
        }

        return false
    }
}
