//
//  File.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

/// Marks a property as a file field with hydrated `FileValue` objects.
///
/// Similar to `@Relation`, the `@File` macro generates backing storage for
/// filenames while the visible property holds hydrated `FileValue` objects with
/// ready-to-use URLs.
///
/// ## Usage
///
/// ```swift
/// @BaseCollection("posts")
/// public struct Post {
///     var title: String = ""
///
///     @File var coverImage: FileValue?       // Single file
///     @File var attachments: [FileValue]?    // Multiple files
/// }
/// ```
///
/// ## Generated Code
///
/// For `@File var coverImage: FileValue?`:
/// - Generates: `var _coverImageFilename: String?`
/// - Decodes filename from JSON, hydrates into `FileValue.existing(RecordFile(...))` with collection/record/baseURL context
///
/// For `@File var attachments: [FileValue]?`:
/// - Generates: `var _attachmentsFilenames: [String] = []`
/// - Decodes filenames from JSON, hydrates into `[FileValue]` array
///
/// ## Accessing Files
///
/// ```swift
/// // Access the hydrated FileValue with ready-to-use URL
/// if let cover = post.coverImage {
///     // Direct URL access via existingFile
///     let url = cover.existingFile?.url
///     // "http://localhost:8090/api/files/posts/abc123/cover_xyz.png"
///
///     // With thumbnail
///     let thumbUrl = cover.existingFile?.url(thumb: .crop(width: 100, height: 100))
///
///     // Force download
///     let downloadUrl = cover.existingFile?.url(download: true)
///
///     // Protected file with token
///     let token = try await collection.getFileToken()
///     let protectedUrl = cover.existingFile?.url(token: token.token)
///
///     // Access raw filename
///     print(cover.filename) // "cover_Ab24ZjL.png"
/// }
///
/// // Iterate over multiple files
/// for attachment in post.attachments ?? [] {
///     if let file = attachment.existingFile {
///         let url = file.url  // Ready to use!
///         print(file.filename)
///     }
/// }
/// ```
///
/// ## Uploading Files
///
/// Assign pending uploads directly to file properties and the system auto-detects
/// whether to use JSON or multipart encoding:
///
/// ```swift
/// let imageFile = UploadFile(filename: "cover.png", data: imageData, mimeType: "image/png")
///
/// // Create with files - auto-detects, uses multipart
/// var post = Post(title: "My Post")
/// post.coverImage = .pending(imageFile)
/// let created = try await collection.create(post)
///
/// // The returned post has hydrated FileValue with URL!
/// if let url = created.coverImage?.existingFile?.url {
///     // Use directly in image views, download tasks, etc.
/// }
///
/// // Update with mixed files (keep existing + add new)
/// created.attachments = [
///     .existing(existingFile),  // Keep this one
///     .pending(newUpload)       // Upload this one
/// ]
/// let updated = try await collection.update(created)
///
/// // Delete specific files
/// try await collection.deleteFiles(
///     from: post,
///     files: FileDeletePayload(["attachments": ["old.pdf"]])
/// )
/// ```
///
/// ## Important: Memberwise Init Behavior
///
/// File field properties are only hydrated when decoding records from the server.
/// When using the memberwise initializer, file properties remain `nil` even if
/// filenames are passed - this is because `RecordFile` requires server context
/// (record ID, collection name, base URL) that isn't available at creation time.
///
/// ```swift
/// // When creating a new record locally:
/// let post = Post(title: "My Post")
/// post.coverImage  // nil - not hydrated
///
/// // Assign pending upload:
/// post.coverImage = .pending(UploadFile(...))
///
/// // After saving to server and getting response:
/// let savedPost = try await collection.create(post)
/// savedPost.coverImage?.existingFile?.url  // Fully hydrated with URL
/// ```
///
/// This matches the behavior of `@Relation` which also only hydrates from server responses.
@attached(peer, names: arbitrary)
public macro File(
    _ options: FileOption...
) = #externalMacro(module: "PocketBaseMacros", type: "File")

/// Options for configuring file field behavior.
public enum FileOption: Sendable {
    /// Mark the file field as required (must have at least one file).
    case required
}
