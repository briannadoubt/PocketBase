//
//  PocketBaseMacrosTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/15/24.
//

import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.

#if canImport(PocketBaseMacros)
import PocketBaseMacros

let testMacros: [String: Macro.Type] = [
    "AuthCollection": AuthCollection.self,
    "BaseCollection": BaseCollection.self,
    "Filter": Filter.self,
    "Relation": Relation.self,
    "BackRelation": BackRelation.self,
    "File": File.self,
]
#endif

// MARK: - BaseCollection Tests

@Suite("BaseCollection Macro")
struct BaseCollectionTests {

    @Test("Empty struct generates BaseRecord conformance")
    func noVariables() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @BaseCollection("cats")
            struct Cat {

            }
            """,
            expandedSource: """
            struct Cat {

            }
            extension Cat: BaseRecord {}
            """,
            macros: testMacros
        )
        #endif
    }

    @Test("Generates collection static property")
    func generatesCollectionProperty() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @BaseCollection("posts")
            struct Post {
                var title: String
            }
            """,
            expandedSource: """
            struct Post {
                var title: String

                static let collection: String = "posts"
                var id: String = ""
                var collectionId: String = ""
                var collectionName: String = ""
                var created: Date = Date.distantPast
                var updated: Date = Date.distantPast
                typealias EncodingConfiguration = PocketBase.EncodingConfiguration
                init(title: String) {
                    self.title = title
                }
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    // Base Collection Fields
                    let id = try container.decode(String.self, forKey: .id)
                    self.id = id
                    collectionName = try container.decode(String.self, forKey: .collectionName)
                    collectionId = try container.decode(String.self, forKey: .collectionId)
                    created = try container.decode(Date.self, forKey: .created)
                    updated = try container.decode(Date.self, forKey: .updated)
                    self.title = try container.decode(String.self, forKey: .title)
                }
                func encode(to encoder: Encoder, configuration: PocketBase.EncodingConfiguration) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    // BaseRecord fields and file fields (skip for remote body)
                    if configuration == .none {
                        try container.encode(id, forKey: .id)
                        try container.encode(collectionName, forKey: .collectionName)
                        try container.encode(collectionId, forKey: .collectionId)
                        try container.encode(created, forKey: .created)
                        try container.encode(updated, forKey: .updated)
                    }
                    // Declared fields (non-file)
                    try container.encode(title, forKey: .title)
                }
                static var relations: [String: any Record.Type] {
                    [:]
                }
                static var fileFields: [String] {
                    []
                }
                func pendingFileUploads() -> FileUploadPayload {
                    [:]
                }
                func fileFieldValues() -> [String: [FileFieldEntry]] {
                    [:]
                }
                enum CodingKeys: String, CodingKey {
                    case id, collectionName, collectionId, created, updated, expand
                    case title
                }
            }
            extension Post: BaseRecord {}
            """,
            macros: testMacros
        )
        #endif
    }
}

// MARK: - AuthCollection Tests

@Suite("AuthCollection Macro")
struct AuthCollectionTests {

    @Test("Generates auth fields")
    func generatesAuthFields() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @AuthCollection("users")
            struct User {
            }
            """,
            expandedSource: """
            struct User {

                static let collection: String = "users"
                var id: String = ""
                var collectionId: String = ""
                var collectionName: String = ""
                var created: Date = Date.distantPast
                var updated: Date = Date.distantPast
                typealias EncodingConfiguration = PocketBase.EncodingConfiguration
                var verified: Bool = false
                var emailVisibility: Bool = false
                var username: String = ""
                var email: String? = nil
                init(username: String? = nil, email: String? = nil, verified: Bool = false, emailVisibility: Bool = false) {
                    self.username = username ?? ""
                    self.email = email
                    self.verified = verified
                    self.emailVisibility = emailVisibility
                }
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    // Base Collection Fields
                    let id = try container.decode(String.self, forKey: .id)
                    self.id = id
                    collectionName = try container.decode(String.self, forKey: .collectionName)
                    collectionId = try container.decode(String.self, forKey: .collectionId)
                    created = try container.decode(Date.self, forKey: .created)
                    updated = try container.decode(Date.self, forKey: .updated)
                    // Auth Collection Fields
                    username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
                    email = try container.decodeIfPresent(String.self, forKey: .email)
                    verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
                    emailVisibility = try container.decodeIfPresent(Bool.self, forKey: .emailVisibility) ?? false
                }
                func encode(to encoder: Encoder, configuration: PocketBase.EncodingConfiguration) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    // BaseRecord fields and file fields (skip for remote body)
                    if configuration == .none {
                        try container.encode(id, forKey: .id)
                        try container.encode(collectionName, forKey: .collectionName)
                        try container.encode(collectionId, forKey: .collectionId)
                        try container.encode(created, forKey: .created)
                        try container.encode(updated, forKey: .updated)
                    }
                    // Declared fields (non-file)
                    try container.encode(username, forKey: .username)
                    try container.encode(email, forKey: .email)
                    try container.encode(verified, forKey: .verified)
                    try container.encode(emailVisibility, forKey: .emailVisibility)
                }
                static var relations: [String: any Record.Type] {
                    [:]
                }
                static var fileFields: [String] {
                    []
                }
                func pendingFileUploads() -> FileUploadPayload {
                    [:]
                }
                func fileFieldValues() -> [String: [FileFieldEntry]] {
                    [:]
                }
                enum CodingKeys: String, CodingKey {
                    case id, collectionName, collectionId, created, updated, expand
                    case verified, emailVisibility, username, email
                }
            }
            extension User: AuthRecord {}
            """,
            macros: testMacros
        )
        #endif
    }
}

// MARK: - Relation Macro Tests

@Suite("Relation Macro")
struct RelationMacroTests {

    @Test("Single relation generates ID backing storage")
    func singleRelation() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @Relation var author: Author?
            """,
            expandedSource: """
            var author: Author?
            var _authorId: Author.ID
            """,
            macros: testMacros
        )
        #endif
    }

    @Test("Array relation generates IDs backing storage")
    func arrayRelation() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @Relation var tags: [Tag]?
            """,
            expandedSource: """
            var tags: [Tag]?
            var _tagsIds: [Tag.ID] = []
            """,
            macros: testMacros
        )
        #endif
    }

    @Test("Optional relation generates optional ID")
    func optionalRelation() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @Relation(.optional) var category: Category?
            """,
            expandedSource: """
            var category: Category?
            var _categoryId: Category.ID? = nil
            """,
            macros: testMacros
        )
        #endif
    }

    @Test("Relation requires optional type")
    func requiresOptionalType() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @Relation var author: Author
            """,
            expandedSource: """
            var author: Author
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`Relation` variables must be marked as optional. If the relation is optional on the pocketbase side, use `@Relation(.optional)`, otherwise the relationship will be \"required\" and enforced through a memberwise initializer.",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
        #endif
    }
}

// MARK: - BackRelation Macro Tests

@Suite("BackRelation Macro")
struct BackRelationMacroTests {

    @Test("BackRelation generates no peers")
    func backRelationNoPeers() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @BackRelation("posts") var posts: [Post]?
            """,
            expandedSource: """
            var posts: [Post]?
            """,
            macros: testMacros
        )
        #endif
    }
}

// MARK: - Filter Macro Tests

@Suite("Filter Macro")
struct FilterMacroTests {

    @Test("Simple equality filter")
    func simpleEquality() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            #Filter { $0.name == "test" }
            """,
            expandedSource: """
            Filter(rawValue: "(name='test')")
            """,
            macros: testMacros
        )
        #endif
    }

    @Test("Comparison operators")
    func comparisonOperators() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            #Filter { $0.age > $0.minAge }
            """,
            expandedSource: """
            Filter(rawValue: "(age>minAge)")
            """,
            macros: testMacros
        )
        #endif
    }
}

// MARK: - File Macro Tests

@Suite("File Macro")
struct FileMacroTests {

    @Test("Single file generates filename backing storage")
    func singleFile() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @File var avatar: FileValue?
            """,
            expandedSource: """
            var avatar: FileValue?
            var _avatarFilename: String? = nil
            """,
            macros: testMacros
        )
        #endif
    }

    @Test("Multiple files generate filenames backing storage")
    func multipleFiles() async throws {
        #if canImport(PocketBaseMacros)
        assertMacroExpansion(
            """
            @File var photos: [FileValue]?
            """,
            expandedSource: """
            var photos: [FileValue]?
            var _photosFilenames: [String] = []
            """,
            macros: testMacros
        )
        #endif
    }
}

