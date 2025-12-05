//
//  FileTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Testing
@testable import PocketBase
import TestUtilities
import Foundation

@Suite("File Tests")
struct FileTests: NetworkResponseTestSuite {

    // MARK: - UploadFile Tests

    @Suite("UploadFile")
    struct UploadFileTests {
        @Test("Create from data")
        func createFromData() {
            let data = "Hello, World!".data(using: .utf8)!
            let file = UploadFile(
                filename: "test.txt",
                data: data,
                mimeType: "text/plain"
            )

            #expect(file.filename == "test.txt")
            #expect(file.data == data)
            #expect(file.mimeType == "text/plain")
        }

        @Test("Default MIME type")
        func defaultMimeType() {
            let file = UploadFile(
                filename: "unknown.xyz",
                data: Data()
            )

            #expect(file.mimeType == "application/octet-stream")
        }

        @Test("MIME type inference for common extensions", arguments: [
            ("jpg", "image/jpeg"),
            ("jpeg", "image/jpeg"),
            ("png", "image/png"),
            ("gif", "image/gif"),
            ("webp", "image/webp"),
            ("pdf", "application/pdf"),
            ("txt", "text/plain"),
            ("json", "application/json"),
            ("mp4", "video/mp4"),
            ("mp3", "audio/mpeg"),
            ("zip", "application/zip")
        ])
        func mimeTypeInference(ext: String, expected: String) {
            let mimeType = UploadFile.mimeType(forExtension: ext)
            #expect(mimeType == expected)
        }
    }

    // MARK: - ThumbSize Tests

    @Suite("ThumbSize")
    struct ThumbSizeTests {
        @Test("Crop query value")
        func cropQueryValue() {
            let thumb = ThumbSize.crop(width: 100, height: 200)
            #expect(thumb.queryValue == "100x200")
        }

        @Test("Crop top query value")
        func cropTopQueryValue() {
            let thumb = ThumbSize.cropTop(width: 100, height: 200)
            #expect(thumb.queryValue == "100x200t")
        }

        @Test("Crop bottom query value")
        func cropBottomQueryValue() {
            let thumb = ThumbSize.cropBottom(width: 100, height: 200)
            #expect(thumb.queryValue == "100x200b")
        }

        @Test("Fit query value")
        func fitQueryValue() {
            let thumb = ThumbSize.fit(width: 100, height: 200)
            #expect(thumb.queryValue == "100x200f")
        }

        @Test("Height only query value")
        func heightOnlyQueryValue() {
            let thumb = ThumbSize.height(300)
            #expect(thumb.queryValue == "0x300")
        }

        @Test("Width only query value")
        func widthOnlyQueryValue() {
            let thumb = ThumbSize.width(400)
            #expect(thumb.queryValue == "400x0")
        }
    }

    // MARK: - MultipartFormData Tests

    @Suite("MultipartFormData")
    struct MultipartFormDataTests {
        @Test("Content type includes boundary")
        func contentTypeIncludesBoundary() {
            let multipart = MultipartFormData()
            #expect(multipart.contentType.contains("multipart/form-data; boundary="))
            #expect(multipart.contentType.contains(multipart.boundary))
        }

        @Test("Append text field")
        func appendTextField() {
            var multipart = MultipartFormData(boundary: "test-boundary")
            multipart.append(name: "field", value: "value")
            let data = multipart.finalize()

            let string = String(data: data, encoding: .utf8)!
            #expect(string.contains("--test-boundary"))
            #expect(string.contains("Content-Disposition: form-data; name=\"field\""))
            #expect(string.contains("value"))
        }

        @Test("Append file")
        func appendFile() {
            var multipart = MultipartFormData(boundary: "test-boundary")
            let file = UploadFile(
                filename: "test.txt",
                data: "Hello".data(using: .utf8)!,
                mimeType: "text/plain"
            )
            multipart.append(name: "document", file: file)
            let data = multipart.finalize()

            let string = String(data: data, encoding: .utf8)!
            #expect(string.contains("--test-boundary"))
            #expect(string.contains("Content-Disposition: form-data; name=\"document\"; filename=\"test.txt\""))
            #expect(string.contains("Content-Type: text/plain"))
            #expect(string.contains("Hello"))
        }

        @Test("Finalize adds closing boundary")
        func finalizeAddsClosingBoundary() {
            var multipart = MultipartFormData(boundary: "test-boundary")
            let data = multipart.finalize()

            let string = String(data: data, encoding: .utf8)!
            #expect(string.contains("--test-boundary--"))
        }
    }

    // MARK: - File URL Generation Tests

    @Suite("File URL Generation")
    struct FileURLGenerationTests: NetworkResponseTestSuite {
        @Test("Basic file URL")
        func basicFileURL() {
            let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)
            let url = pocketbase.fileURL(
                collectionIdOrName: "posts",
                recordId: "abc123",
                filename: "image.png"
            )

            #expect(url.absoluteString == "http://localhost:8090/api/files/posts/abc123/image.png")
        }

        @Test("File URL with thumb")
        func fileURLWithThumb() {
            let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)
            let url = pocketbase.fileURL(
                collectionIdOrName: "posts",
                recordId: "abc123",
                filename: "image.png",
                thumb: .crop(width: 100, height: 100)
            )

            #expect(url.absoluteString == "http://localhost:8090/api/files/posts/abc123/image.png?thumb=100x100")
        }

        @Test("File URL with token")
        func fileURLWithToken() {
            let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)
            let url = pocketbase.fileURL(
                collectionIdOrName: "posts",
                recordId: "abc123",
                filename: "secret.pdf",
                token: "file-token-123"
            )

            #expect(url.absoluteString == "http://localhost:8090/api/files/posts/abc123/secret.pdf?token=file-token-123")
        }

        @Test("File URL with download flag")
        func fileURLWithDownload() {
            let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)
            let url = pocketbase.fileURL(
                collectionIdOrName: "posts",
                recordId: "abc123",
                filename: "document.pdf",
                download: true
            )

            #expect(url.absoluteString == "http://localhost:8090/api/files/posts/abc123/document.pdf?download=1")
        }

        @Test("File URL with all options")
        func fileURLWithAllOptions() {
            let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)
            let url = pocketbase.fileURL(
                collectionIdOrName: "posts",
                recordId: "abc123",
                filename: "image.png",
                thumb: .fit(width: 200, height: 200),
                token: "token123",
                download: true
            )

            let urlString = url.absoluteString
            #expect(urlString.contains("thumb=200x200f"))
            #expect(urlString.contains("token=token123"))
            #expect(urlString.contains("download=1"))
        }

        @Test("File URL from record")
        func fileURLFromRecord() {
            let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)
            let record = Self.rawr
            let url = pocketbase.fileURL(
                record: record,
                filename: "attachment.pdf"
            )

            #expect(url.absoluteString == "http://localhost:8090/api/files/rawrs/meow1234/attachment.pdf")
        }
    }

    // MARK: - File Token Tests

    @Suite("File Token")
    struct FileTokenTests: NetworkResponseTestSuite {
        @Test("Request file token")
        func requestFileToken() async throws {
            let baseURL = Self.baseURL
            let tokenResponse = FileTokenResponse(token: "short-lived-token-123")
            let response = try PocketBase.encoder.encode(tokenResponse, configuration: .none)
            let environment = PocketBase.TestEnvironment(baseURL: baseURL, response: response)
            let collection = environment.pocketbase.collection(Rawr.self)

            let result = try await collection.getFileToken()
            #expect(result.token == "short-lived-token-123")

            try environment.assertNetworkRequest(
                url: baseURL.absoluteString + "/api/files/token",
                method: .post
            )
        }
    }

    // MARK: - Create with Files Tests

    @Suite("Create with Files")
    struct CreateWithFilesTests: NetworkResponseTestSuite {
        @Test("Create record with files uses multipart")
        func createRecordWithFilesUsesMultipart() async throws {
            let expectedRawr = Self.rawr
            let response = try PocketBase.encoder.encode(expectedRawr, configuration: .none)
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(baseURL: baseURL, response: response)
            let collection = environment.pocketbase.collection(Rawr.self)

            let file = UploadFile(
                filename: "test.txt",
                data: "Hello".data(using: .utf8)!,
                mimeType: "text/plain"
            )

            let rawr = try await collection.create(
                Rawr(field: Self.field),
                files: ["document": [file]]
            )

            #expect(rawr.id == expectedRawr.id)

            // Verify the request was made with multipart content type
            guard let lastRequest = environment.session.lastRequest else {
                Issue.record("No request was made")
                return
            }

            let contentType = lastRequest.value(forHTTPHeaderField: "Content-Type") ?? ""
            #expect(contentType.contains("multipart/form-data"))
        }
    }

    // MARK: - Update with Files Tests

    @Suite("Update with Files")
    struct UpdateWithFilesTests: NetworkResponseTestSuite {
        @Test("Update record with files uses multipart")
        func updateRecordWithFilesUsesMultipart() async throws {
            let expectedRawr = Self.rawr
            let response = try PocketBase.encoder.encode(expectedRawr, configuration: .none)
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(baseURL: baseURL, response: response)
            let collection = environment.pocketbase.collection(Rawr.self)

            let file = UploadFile(
                filename: "new-file.txt",
                data: "Updated content".data(using: .utf8)!,
                mimeType: "text/plain"
            )

            let rawr = try await collection.update(
                Self.rawr,
                files: ["document": [file]]
            )

            #expect(rawr.id == expectedRawr.id)

            guard let lastRequest = environment.session.lastRequest else {
                Issue.record("No request was made")
                return
            }

            let contentType = lastRequest.value(forHTTPHeaderField: "Content-Type") ?? ""
            #expect(contentType.contains("multipart/form-data"))
            #expect(lastRequest.httpMethod == "PATCH")
        }

        @Test("Update with file deletions includes delete modifier")
        func updateWithFileDeletions() async throws {
            let expectedRawr = Self.rawr
            let response = try PocketBase.encoder.encode(expectedRawr, configuration: .none)
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(baseURL: baseURL, response: response)
            let collection = environment.pocketbase.collection(Rawr.self)

            let rawr = try await collection.update(
                Self.rawr,
                files: [:],
                deleteFiles: FileDeletePayload(["documents": ["old_file.pdf"]])
            )

            #expect(rawr.id == expectedRawr.id)

            guard let lastRequest = environment.session.lastRequest else {
                Issue.record("No request was made")
                return
            }

            // Verify the body contains the deletion modifier
            guard let body = lastRequest.httpBody else {
                Issue.record("No request body")
                return
            }

            let bodyString = String(data: body, encoding: .utf8) ?? ""
            #expect(bodyString.contains("documents-"))
            #expect(bodyString.contains("old_file.pdf"))
        }

        @Test("Delete files from record")
        func deleteFilesFromRecord() async throws {
            let expectedRawr = Self.rawr
            let response = try PocketBase.encoder.encode(expectedRawr, configuration: .none)
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(baseURL: baseURL, response: response)
            let collection = environment.pocketbase.collection(Rawr.self)

            let rawr = try await collection.deleteFiles(
                from: Self.rawr,
                files: FileDeletePayload(fieldName: "avatar", filenames: ["old_avatar.png"])
            )

            #expect(rawr.id == expectedRawr.id)
        }

        @Test("Clear file field")
        func clearFileField() async throws {
            let expectedRawr = Self.rawr
            let response = try PocketBase.encoder.encode(expectedRawr, configuration: .none)
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(baseURL: baseURL, response: response)
            let collection = environment.pocketbase.collection(Rawr.self)

            let rawr = try await collection.clearFileField(
                on: Self.rawr,
                fieldName: "avatar"
            )

            #expect(rawr.id == expectedRawr.id)

            guard let lastRequest = environment.session.lastRequest else {
                Issue.record("No request was made")
                return
            }

            guard let body = lastRequest.httpBody else {
                Issue.record("No request body")
                return
            }

            let bodyString = String(data: body, encoding: .utf8) ?? ""
            #expect(bodyString.contains("name=\"avatar\""))
        }
    }

    // MARK: - FileDeletePayload Tests

    @Suite("FileDeletePayload")
    struct FileDeletePayloadTests {
        @Test("Create from dictionary")
        func createFromDictionary() {
            let payload = FileDeletePayload([
                "documents": ["file1.pdf", "file2.pdf"],
                "images": ["photo.jpg"]
            ])

            #expect(payload.deletions["documents"]?.count == 2)
            #expect(payload.deletions["images"]?.count == 1)
        }

        @Test("Create from single field")
        func createFromSingleField() {
            let payload = FileDeletePayload(
                fieldName: "avatar",
                filenames: ["old.png", "older.png"]
            )

            #expect(payload.deletions["avatar"]?.count == 2)
        }
    }

    // MARK: - @FileField Macro Tests

    @Suite("FileField Macro")
    struct FileFieldMacroTests {
        @Test("fileFields static property lists all file fields")
        func fileFieldsProperty() {
            // Post has two file fields: coverImage and attachments
            #expect(Post.fileFields.contains("coverImage"))
            #expect(Post.fileFields.contains("attachments"))
            #expect(Post.fileFields.count == 2)
        }

        @Test("Record without file fields has empty fileFields")
        func noFileFields() {
            // Rawr has no file fields
            #expect(Rawr.fileFields.isEmpty)
        }

        @Test("Post can be created with memberwise init using filenames")
        func memberwiseInit() {
            let post = Post(
                title: "My Post",
                coverImage: "cover.jpg",
                attachments: ["a.pdf", "b.pdf"]
            )

            #expect(post.title == "My Post")
            // Backing storage holds the filenames
            #expect(post._coverImageFilename == "cover.jpg")
            #expect(post._attachmentsFilenames == ["a.pdf", "b.pdf"])
        }

        @Test("Post file fields default to nil and empty array")
        func defaultValues() {
            let post = Post(title: "Minimal Post")

            #expect(post._coverImageFilename == nil)
            #expect(post._attachmentsFilenames.isEmpty)
        }
    }

    // MARK: - RecordFile Tests

    @Suite("RecordFile")
    struct RecordFileTests {
        @Test("RecordFile stores filename and context")
        func recordFileProperties() {
            let file = RecordFile(
                filename: "avatar_abc123.png",
                collectionName: "users",
                recordId: "user123"
            )

            #expect(file.filename == "avatar_abc123.png")
            #expect(file.collectionName == "users")
            #expect(file.recordId == "user123")
        }

        @Test("RecordFile generates URL")
        func recordFileURL() {
            let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)
            let file = RecordFile(
                filename: "avatar.png",
                collectionName: "users",
                recordId: "abc123"
            )

            let url = file.url(from: pocketbase)
            #expect(url.absoluteString == "http://localhost:8090/api/files/users/abc123/avatar.png")
        }

        @Test("RecordFile generates URL with thumb")
        func recordFileURLWithThumb() {
            let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)
            let file = RecordFile(
                filename: "photo.jpg",
                collectionName: "posts",
                recordId: "post456"
            )

            let url = file.url(from: pocketbase, thumb: .crop(width: 100, height: 100))
            #expect(url.absoluteString == "http://localhost:8090/api/files/posts/post456/photo.jpg?thumb=100x100")
        }

        @Test("RecordFile can be created from string literal")
        func recordFileFromStringLiteral() {
            let file: RecordFile = "test.pdf"
            #expect(file.filename == "test.pdf")
        }

        @Test("RecordFile description")
        func recordFileDescription() {
            let file = RecordFile(filename: "doc.pdf", collectionName: "files", recordId: "123")
            #expect(file.description == "RecordFile(doc.pdf)")
        }
    }
}
