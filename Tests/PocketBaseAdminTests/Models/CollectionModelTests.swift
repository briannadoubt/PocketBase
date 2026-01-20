//
//  CollectionModelTests.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import Testing
@testable import PocketBaseAdmin
@testable import PocketBase

@Suite("CollectionModel")
struct CollectionModelTests {

    @Test("CollectionModelType raw values")
    func collectionTypeRawValues() {
        #expect(CollectionModelType.base.rawValue == "base")
        #expect(CollectionModelType.auth.rawValue == "auth")
        #expect(CollectionModelType.view.rawValue == "view")
    }

    @Test("CollectionModel decoding")
    func decodeCollectionModel() throws {
        let json = """
        {
            "id": "col123",
            "name": "posts",
            "type": "base",
            "system": false,
            "listRule": "",
            "viewRule": "",
            "createRule": "@request.auth.id != ''",
            "updateRule": "@request.auth.id = id",
            "deleteRule": "@request.auth.id = id",
            "schema": [
                {
                    "id": "field1",
                    "name": "title",
                    "type": "text",
                    "system": false,
                    "required": true
                }
            ],
            "indexes": ["idx_title"]
        }
        """

        let collection = try JSONDecoder().decode(CollectionModel.self, from: Data(json.utf8))

        #expect(collection.id == "col123")
        #expect(collection.name == "posts")
        #expect(collection.type == .base)
        #expect(collection.system == false)
        #expect(collection.createRule == "@request.auth.id != ''")
        #expect(collection.schema?.count == 1)
        #expect(collection.schema?.first?.name == "title")
        #expect(collection.indexes?.first == "idx_title")
    }

    @Test("CollectionModel auth type")
    func decodeAuthCollection() throws {
        let json = """
        {
            "id": "users",
            "name": "_pb_users_auth_",
            "type": "auth",
            "system": true
        }
        """

        let collection = try JSONDecoder().decode(CollectionModel.self, from: Data(json.utf8))

        #expect(collection.type == .auth)
        #expect(collection.system == true)
    }

    @Test("CollectionModel view type")
    func decodeViewCollection() throws {
        let json = """
        {
            "id": "view1",
            "name": "active_posts",
            "type": "view",
            "system": false
        }
        """

        let collection = try JSONDecoder().decode(CollectionModel.self, from: Data(json.utf8))

        #expect(collection.type == .view)
    }

    @Test("CollectionModel view type with viewQuery")
    func decodeViewCollectionWithViewQuery() throws {
        let json = """
        {
            "id": "view1",
            "name": "published_posts",
            "type": "view",
            "system": false,
            "viewQuery": "SELECT id, title, created FROM posts WHERE published = true"
        }
        """

        let collection = try JSONDecoder().decode(CollectionModel.self, from: Data(json.utf8))

        #expect(collection.type == .view)
        #expect(collection.name == "published_posts")
        #expect(collection.viewQuery == "SELECT id, title, created FROM posts WHERE published = true")
    }

    @Test("CollectionModel encoding roundtrip with viewQuery")
    func encodingRoundtripWithViewQuery() throws {
        let original = CollectionModel(
            id: "view1",
            name: "active_users",
            type: .view,
            system: false,
            viewQuery: "SELECT id, username FROM users WHERE verified = true"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(CollectionModel.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.type == original.type)
        #expect(decoded.viewQuery == original.viewQuery)
    }

    @Test("CollectionsResponse decoding")
    func decodeCollectionsResponse() throws {
        let json = """
        {
            "page": 1,
            "perPage": 30,
            "totalItems": 5,
            "totalPages": 1,
            "items": [
                {
                    "id": "col1",
                    "name": "posts",
                    "type": "base",
                    "system": false
                },
                {
                    "id": "col2",
                    "name": "users",
                    "type": "auth",
                    "system": true
                }
            ]
        }
        """

        let response = try JSONDecoder().decode(CollectionsResponse.self, from: Data(json.utf8))

        #expect(response.page == 1)
        #expect(response.totalItems == 5)
        #expect(response.items.count == 2)
        #expect(response.items[0].name == "posts")
        #expect(response.items[1].type == .auth)
    }
}

@Suite("Field")
struct FieldTests {

    @Test("FieldType raw values")
    func fieldTypeRawValues() {
        #expect(FieldType.text.rawValue == "text")
        #expect(FieldType.number.rawValue == "number")
        #expect(FieldType.bool.rawValue == "bool")
        #expect(FieldType.email.rawValue == "email")
        #expect(FieldType.url.rawValue == "url")
        #expect(FieldType.date.rawValue == "date")
        #expect(FieldType.file.rawValue == "file")
        #expect(FieldType.relation.rawValue == "relation")
        #expect(FieldType.json.rawValue == "json")
        #expect(FieldType.select.rawValue == "select")
    }

    @Test("Field decoding with options")
    func decodeFieldWithOptions() throws {
        let json = """
        {
            "id": "field1",
            "name": "category",
            "type": "select",
            "system": false,
            "required": true,
            "presentable": false,
            "options": {
                "maxSelect": 1,
                "values": ["tech", "sports", "news"]
            }
        }
        """

        let field = try JSONDecoder().decode(Field.self, from: Data(json.utf8))

        #expect(field.id == "field1")
        #expect(field.name == "category")
        #expect(field.type == .select)
        #expect(field.required == true)
        #expect(field.options?.maxSelect == 1)
        #expect(field.options?.values == ["tech", "sports", "news"])
    }

    @Test("Field decoding relation options")
    func decodeRelationField() throws {
        let json = """
        {
            "id": "field2",
            "name": "author",
            "type": "relation",
            "system": false,
            "options": {
                "collectionId": "users",
                "cascadeDelete": false,
                "maxSelect": 1,
                "displayFields": ["name", "email"]
            }
        }
        """

        let field = try JSONDecoder().decode(Field.self, from: Data(json.utf8))

        #expect(field.type == .relation)
        #expect(field.options?.collectionId == "users")
        #expect(field.options?.cascadeDelete == false)
        #expect(field.options?.displayFields == ["name", "email"])
    }

    @Test("Field decoding file options")
    func decodeFileField() throws {
        let json = """
        {
            "id": "field3",
            "name": "avatar",
            "type": "file",
            "system": false,
            "options": {
                "maxSelect": 1,
                "maxSize": 5242880,
                "mimeTypes": ["image/jpeg", "image/png"],
                "thumbs": ["100x100", "200x200"]
            }
        }
        """

        let field = try JSONDecoder().decode(Field.self, from: Data(json.utf8))

        #expect(field.type == .file)
        #expect(field.options?.maxSize == 5242880)
        #expect(field.options?.mimeTypes == ["image/jpeg", "image/png"])
        #expect(field.options?.thumbs == ["100x100", "200x200"])
    }

    @Test("Field encoding roundtrip")
    func encodingRoundtrip() throws {
        let original = Field(
            id: "test_field",
            name: "test",
            type: .text,
            system: false,
            required: true,
            presentable: false,
            options: FieldOptions(min: 1, max: 100)
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Field.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.type == original.type)
        #expect(decoded.required == original.required)
        #expect(decoded.options?.min == original.options?.min)
    }
}

@Suite("CollectionCreateRequest")
struct CollectionCreateRequestTests {

    @Test("CollectionCreateRequest encoding for base collection")
    func encodeBaseCollection() throws {
        let request = CollectionCreateRequest(
            name: "posts",
            type: .base,
            schema: [
                Field(id: "title", name: "title", type: .text, required: true)
            ],
            listRule: "@request.auth.id != ''"
        )

        let encoded = try JSONEncoder().encode(request)
        let json = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)

        #expect(json["name"]?.value as? String == "posts")
        #expect(json["type"]?.value as? String == "base")
        #expect(json["listRule"]?.value as? String == "@request.auth.id != ''")
    }

    @Test("CollectionCreateRequest encoding with viewQuery")
    func encodeViewCollectionWithViewQuery() throws {
        let request = CollectionCreateRequest(
            name: "published_posts",
            type: .view,
            viewQuery: "SELECT id, title, created FROM posts WHERE published = true",
            viewRule: ""
        )

        let encoded = try JSONEncoder().encode(request)
        let json = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)

        #expect(json["name"]?.value as? String == "published_posts")
        #expect(json["type"]?.value as? String == "view")
        #expect(json["viewQuery"]?.value as? String == "SELECT id, title, created FROM posts WHERE published = true")
    }

    @Test("CollectionCreateRequest encoding for auth collection")
    func encodeAuthCollection() throws {
        let request = CollectionCreateRequest(
            name: "users",
            type: .auth,
            listRule: "@request.auth.id != ''"
        )

        let encoded = try JSONEncoder().encode(request)
        let json = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)

        #expect(json["name"]?.value as? String == "users")
        #expect(json["type"]?.value as? String == "auth")
    }
}

@Suite("CollectionUpdateRequest")
struct CollectionUpdateRequestTests {

    @Test("CollectionUpdateRequest encoding")
    func encodeUpdateRequest() throws {
        let request = CollectionUpdateRequest(
            name: "updated_posts",
            listRule: "@request.auth.verified = true"
        )

        let encoded = try JSONEncoder().encode(request)
        let json = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)

        #expect(json["name"]?.value as? String == "updated_posts")
        #expect(json["listRule"]?.value as? String == "@request.auth.verified = true")
    }

    @Test("CollectionUpdateRequest encoding with viewQuery")
    func encodeUpdateRequestWithViewQuery() throws {
        let request = CollectionUpdateRequest(
            viewQuery: "SELECT id, title FROM posts WHERE published = true AND featured = true"
        )

        let encoded = try JSONEncoder().encode(request)
        let json = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)

        #expect(json["viewQuery"]?.value as? String == "SELECT id, title FROM posts WHERE published = true AND featured = true")
    }
}

/// Helper type for decoding arbitrary JSON values in tests
private struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let bool as Bool:
            try container.encode(bool)
        default:
            try container.encodeNil()
        }
    }
}
