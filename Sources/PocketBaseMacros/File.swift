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

/// Errors that can occur during File macro expansion.
enum FileError {
    case mustBeVariable
    case missingIdentifierPattern
    case mustDefineTypeAnnotation
    case mustBeMarkedAsOptional
    case invalidType

    var errorDescription: String {
        switch self {
        case .mustBeVariable:
            "`@File` must be applied to a variable declaration."
        case .missingIdentifierPattern:
            "Invalid pattern. Must be an identifier pattern. Example: `@File var avatar: FileValue?`."
        case .mustDefineTypeAnnotation:
            "Missing type annotation. Example: `@File var avatar: FileValue?` or `@File var documents: [FileValue]?`."
        case .mustBeMarkedAsOptional:
            "`@File` variables must be marked as optional. Example: `@File var avatar: FileValue?` or `@File var documents: [FileValue]?`."
        case .invalidType:
            "File fields must be `FileValue?` (single file) or `[FileValue]?` (multiple files)."
        }
    }
}

/// The `@File` macro marks a property as a file field and generates backing storage.
///
/// Similar to `@Relation`, this macro generates a hidden property to store the raw
/// filename(s) while the visible property holds hydrated `FileValue` objects.
///
/// For `@File var avatar: FileValue?`:
/// - Generates: `var _avatarFilename: String?`
///
/// For `@File var documents: [FileValue]?`:
/// - Generates: `var _documentsFilenames: [String] = []`
public struct File: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate that this is applied to a variable
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
              let binding = variableDecl.bindings.first else {
            throw MacroExpansionErrorMessage(FileError.mustBeVariable.errorDescription)
        }

        // Validate pattern
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw MacroExpansionErrorMessage(FileError.missingIdentifierPattern.errorDescription)
        }

        // Validate type annotation exists
        guard let typeAnnotation = binding.typeAnnotation else {
            throw MacroExpansionErrorMessage(FileError.mustDefineTypeAnnotation.errorDescription)
        }

        // Must be optional
        guard let optional = typeAnnotation.type.as(OptionalTypeSyntax.self) else {
            throw MacroExpansionErrorMessage(FileError.mustBeMarkedAsOptional.errorDescription)
        }

        // Validate type is FileValue? or [FileValue]?
        let isValidType = isValidFileFieldType(optional.wrappedType)
        guard isValidType else {
            throw MacroExpansionErrorMessage(FileError.invalidType.errorDescription)
        }

        let name = pattern.identifier
        let isArray = optional.wrappedType.is(ArrayTypeSyntax.self)

        // Generate backing storage property
        if isArray {
            // For [FileValue]? generate var _<name>Filenames: [String] = []
            return ["var _\(name)Filenames: [String] = []"]
        } else {
            // For FileValue? generate var _<name>Filename: String?
            return ["var _\(name)Filename: String?"]
        }
    }

    /// Checks if the type is valid for a file field.
    ///
    /// Valid types are:
    /// - `FileValue` (for FileValue?)
    /// - `[FileValue]` (for [FileValue]?)
    private static func isValidFileFieldType(_ type: TypeSyntax) -> Bool {
        // Check for FileValue
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            return identifier.name.text == "FileValue"
        }

        // Check for [FileValue]
        if let array = type.as(ArrayTypeSyntax.self),
           let element = array.element.as(IdentifierTypeSyntax.self) {
            return element.name.text == "FileValue"
        }

        return false
    }
}
