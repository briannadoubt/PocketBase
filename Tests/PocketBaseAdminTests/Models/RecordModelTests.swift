//
//  RecordModelTests.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import Testing
@testable import PocketBaseAdmin
@testable import PocketBase

@Suite("RecordModel")
struct RecordModelTests {

    @Test("RecordModel decoding with standard fields")
    func decodeRecordModel() throws {
        let json = """
        {
            "id": "rec123",
            "collectionId": "col456",
            "collectionName": "posts",
            "created": "2024-01-15 10:30:00.000Z",
            "updated": "2024-01-15 11:00:00.000Z",
            "title": "Hello World",
            "count": 42,
            "active": true
        }
        """

        let record = try PocketBase.decoder.decode(RecordModel.self, from: Data(json.utf8))

        #expect(record.id == "rec123")
        #expect(record.collectionId == "col456")
        #expect(record.collectionName == "posts")
        #expect(record.content["title"] == .string("Hello World"))
        #expect(record.content["count"] == .int(42))
        #expect(record.content["active"] == .bool(true))
    }

    @Test("RecordModel subscript access")
    func subscriptAccess() throws {
        let json = """
        {
            "id": "rec123",
            "collectionId": "col456",
            "collectionName": "posts",
            "customField": "customValue"
        }
        """

        let record = try PocketBase.decoder.decode(RecordModel.self, from: Data(json.utf8))

        #expect(record["customField"] == .string("customValue"))
        #expect(record["nonexistent"] == nil)
    }

    @Test("RecordModel auth collection convenience accessors")
    func authCollectionAccessors() throws {
        let json = """
        {
            "id": "user123",
            "collectionId": "users",
            "collectionName": "_pb_users_auth_",
            "email": "test@example.com",
            "username": "testuser",
            "verified": true,
            "emailVisibility": false
        }
        """

        let record = try PocketBase.decoder.decode(RecordModel.self, from: Data(json.utf8))

        #expect(record.email == .string("test@example.com"))
        #expect(record.username == .string("testuser"))
        #expect(record.verified == .bool(true))
        #expect(record.emailVisibility == .bool(false))
    }

    @Test("RecordModel encoding preserves dynamic fields")
    func encodingPreservesDynamicFields() throws {
        let original = RecordModel(
            id: "rec123",
            collectionId: "col456",
            collectionName: "posts",
            content: [
                "title": .string("Test Post"),
                "views": .int(100)
            ]
        )

        let encoded = try PocketBase.encoder.encode(original)
        let decoded = try PocketBase.decoder.decode(RecordModel.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.content["title"] == .string("Test Post"))
        #expect(decoded.content["views"] == .int(100))
    }

    @Test("RecordsResponse decoding")
    func decodeRecordsResponse() throws {
        let json = """
        {
            "page": 2,
            "perPage": 20,
            "totalItems": 50,
            "totalPages": 3,
            "items": [
                {
                    "id": "rec1",
                    "collectionId": "col1",
                    "collectionName": "posts",
                    "title": "First"
                }
            ]
        }
        """

        let response = try PocketBase.decoder.decode(RecordsResponse.self, from: Data(json.utf8))

        #expect(response.page == 2)
        #expect(response.perPage == 20)
        #expect(response.totalItems == 50)
        #expect(response.totalPages == 3)
        #expect(response.items.count == 1)
        #expect(response.items.first?.id == "rec1")
    }
}

@Suite("JSONValue")
struct JSONValueTests {

    @Test("JSONValue null decoding")
    func decodeNull() throws {
        let json = "null"
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
        #expect(value == .null)
    }

    @Test("JSONValue bool decoding")
    func decodeBool() throws {
        let trueJson = "true"
        let falseJson = "false"

        let trueValue = try JSONDecoder().decode(JSONValue.self, from: Data(trueJson.utf8))
        let falseValue = try JSONDecoder().decode(JSONValue.self, from: Data(falseJson.utf8))

        #expect(trueValue == .bool(true))
        #expect(falseValue == .bool(false))
    }

    @Test("JSONValue int decoding")
    func decodeInt() throws {
        let json = "42"
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
        #expect(value == .int(42))
    }

    @Test("JSONValue double decoding")
    func decodeDouble() throws {
        let json = "3.14159"
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
        #expect(value == .double(3.14159))
    }

    @Test("JSONValue string decoding")
    func decodeString() throws {
        let json = "\"hello world\""
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
        #expect(value == .string("hello world"))
    }

    @Test("JSONValue URL detection")
    func decodeURL() throws {
        let json = "\"https://example.com/path\""
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))

        if case .url(let url) = value {
            #expect(url.absoluteString == "https://example.com/path")
        } else {
            Issue.record("Expected URL but got \(value)")
        }
    }

    @Test("JSONValue date detection")
    func decodeDate() throws {
        let json = "\"2024-01-15 10:30:00.000Z\""
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))

        if case .date = value {
            // Successfully parsed as date
        } else {
            Issue.record("Expected date but got \(value)")
        }
    }

    @Test("JSONValue array decoding")
    func decodeArray() throws {
        let json = "[1, 2, 3]"
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))

        #expect(value == .array([.int(1), .int(2), .int(3)]))
    }

    @Test("JSONValue dictionary decoding")
    func decodeDictionary() throws {
        let json = "{\"name\": \"test\", \"count\": 5}"
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))

        if case .dictionary(let dict) = value {
            #expect(dict["name"] == .string("test"))
            #expect(dict["count"] == .int(5))
        } else {
            Issue.record("Expected dictionary but got \(value)")
        }
    }

    @Test("JSONValue encoding roundtrip")
    func encodingRoundtrip() throws {
        let values: [JSONValue] = [
            .null,
            .bool(true),
            .int(42),
            .double(3.14),
            .string("test"),
            .array([.int(1), .string("two")]),
            .dictionary(["key": .bool(false)])
        ]

        for original in values {
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(JSONValue.self, from: encoded)
            #expect(decoded == original, "Roundtrip failed for \(original)")
        }
    }

    @Test("JSONValue hashable conformance")
    func hashableConformance() {
        var set: Set<JSONValue> = []
        set.insert(.int(1))
        set.insert(.int(1))
        set.insert(.string("test"))

        #expect(set.count == 2)
    }
}
