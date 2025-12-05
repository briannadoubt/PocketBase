//
//  FileField.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

/// Marks a property as a file field with hydrated `RecordFile` objects.
///
/// Similar to `@Relation`, the `@FileField` macro generates backing storage for
/// filenames while the visible property holds hydrated `RecordFile` objects that
/// provide convenient URL generation.
///
/// ## Usage
///
/// ```swift
/// @BaseCollection("posts")
/// public struct Post {
///     var title: String = ""
///
///     @FileField var coverImage: RecordFile?       // Single file
///     @FileField var attachments: [RecordFile]?    // Multiple files
/// }
/// ```
///
/// ## Generated Code
///
/// For `@FileField var coverImage: RecordFile?`:
/// - Generates: `var _coverImageFilename: String?`
/// - Decodes filename from JSON, hydrates into `RecordFile` with collection/record context
///
/// For `@FileField var attachments: [RecordFile]?`:
/// - Generates: `var _attachmentsFilenames: [String] = []`
/// - Decodes filenames from JSON, hydrates into `[RecordFile]` array
///
/// ## Working with Files
///
/// ```swift
/// // Access the hydrated RecordFile
/// if let cover = post.coverImage {
///     // Generate URL with optional thumbnail
///     let url = cover.url(from: pocketbase)
///     let thumbUrl = cover.url(from: pocketbase, thumb: .crop(width: 100, height: 100))
///
///     // Force download
///     let downloadUrl = cover.url(from: pocketbase, download: true)
///
///     // Access raw filename
///     print(cover.filename) // "cover_Ab24ZjL.png"
/// }
///
/// // Iterate over multiple files
/// for attachment in post.attachments ?? [] {
///     let url = attachment.url(from: pocketbase)
///     print(attachment.filename)
/// }
/// ```
///
/// ## Uploading Files
///
/// When creating or updating records with files, use multipart/form-data:
///
/// ```swift
/// let imageFile = UploadFile(filename: "cover.png", data: imageData, mimeType: "image/png")
///
/// // Create with files
/// let post = try await collection.create(
///     Post(title: "My Post"),
///     files: ["coverImage": [imageFile]]
/// )
///
/// // Update with files
/// try await collection.update(post, files: ["attachments+": [newDoc]])
///
/// // Delete specific files
/// try await collection.deleteFiles(
///     from: post,
///     files: FileDeletePayload(["attachments": ["old.pdf"]])
/// )
/// ```
///
/// ## Field Modifiers for Updates
///
/// - `fieldName+` - Append new files to existing ones
/// - `+fieldName` - Prepend new files to existing ones
/// - `fieldName-` - Delete specific files by name
@attached(peer, names: arbitrary)
public macro FileField(
    _ options: FileFieldOption...
) = #externalMacro(module: "PocketBaseMacros", type: "FileField")

/// Options for configuring file field behavior.
public enum FileFieldOption: Sendable {
    /// Mark the file field as required (must have at least one file).
    case required
}
