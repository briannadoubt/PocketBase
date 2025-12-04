//
//  FileField.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

/// Marks a property as a file field that will be uploaded via multipart/form-data.
///
/// File fields are automatically excluded from JSON encoding and tracked for
/// file upload operations. The macro generates helper code to build file upload
/// payloads from your record's file properties.
///
/// ## Usage
///
/// ```swift
/// @BaseCollection("posts")
/// public struct Post {
///     var title: String = ""
///
///     @FileField var coverImage: String?           // Single file (stores filename)
///     @FileField var attachments: [String] = []    // Multiple files (stores filenames)
/// }
/// ```
///
/// ## How File Fields Work
///
/// In PocketBase, file fields store only the filename(s) in the database. The actual
/// files are stored in the filesystem or S3. When you read a record, you get the
/// filename(s) which you can use to construct file URLs.
///
/// When creating or updating records with files, you need to use multipart/form-data
/// encoding. The `@FileField` macro helps by:
///
/// 1. **Excluding from JSON encoding** - File fields are skipped when encoding the
///    record for create/update operations, since files must be sent separately.
///
/// 2. **Generating `fileFields`** - A static property listing all file field names,
///    useful for validation and documentation.
///
/// ## Field Modifiers for Updates
///
/// When updating records, you can use field name modifiers:
///
/// - `fieldName+` - Append new files to existing ones
/// - `+fieldName` - Prepend new files to existing ones
/// - `fieldName-` - Delete specific files by name
///
/// ```swift
/// // Append a new attachment
/// try await collection.update(post, files: ["attachments+": [newFile]])
///
/// // Delete a specific attachment
/// try await collection.deleteFiles(from: post, files: .init(["attachments": ["old.pdf"]]))
/// ```
///
/// ## Getting File URLs
///
/// Use `pocketbase.fileURL(record:filename:)` to get the URL for a file:
///
/// ```swift
/// if let filename = post.coverImage {
///     let url = pocketbase.fileURL(record: post, filename: filename)
///     // Use url to display or download the file
/// }
/// ```
@attached(peer, names: arbitrary)
public macro FileField(
    _ options: FileFieldOption...
) = #externalMacro(module: "PocketBaseMacros", type: "FileField")

/// Options for configuring file field behavior.
public enum FileFieldOption: Sendable {
    /// Mark the file field as required (must have at least one file).
    case required
}
