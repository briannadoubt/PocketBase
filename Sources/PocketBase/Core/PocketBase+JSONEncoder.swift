//
//  PocketBaseJSONEncoder.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

extension PocketBase {
    final public class JSONEncoder: Foundation.JSONEncoder {
        public override func encode<T: Encodable>(_ value: T) throws -> Data {
            let encoder = Encoder()
            try value.encode(to: encoder)
            return try encoder.encodedData
        }
    }
    
    final class Encoder: Swift.Encoder {
        private var storage: [String: Any] = [:]
        private var currentCodingPath: [CodingKey] = []
        
        private var keysToSkip: [String] = [
            "collectionId",
            "collectionName",
            "created",
            "updated",
            "emailVisibility",
            "verified",
            "expand",
        ]
        
        var encodedData: Data {
            get throws {
                try JSONSerialization.data(withJSONObject: storage, options: [.sortedKeys])
            }
        }

        var codingPath: [CodingKey] {
            currentCodingPath
        }

        var userInfo: [CodingUserInfoKey: Any] {
            return [:]
        }

        func container<Key>(keyedBy type: Key.Type) -> Swift.KeyedEncodingContainer<Key> where Key: CodingKey {
            return Swift.KeyedEncodingContainer(KeyedEncodingContainer<Key>(encoder: self))
        }

        func unkeyedContainer() -> Swift.UnkeyedEncodingContainer {
            UnkeyedEncodingContainer(currentCodingPath.last?.stringValue ?? "", encoder: self)
        }

        func singleValueContainer() -> any Swift.SingleValueEncodingContainer {
            SingleValueEncodingContainer(currentCodingPath.last?.stringValue ?? "", encoder: self)
        }
        
        fileprivate func store(_ value: Any, for key: String) {
            let shouldSkip = keysToSkip.contains(key)
            if shouldSkip {
                return
            }
            storage[key] = value
        }
        
        fileprivate func store<T>(arrayValue value: T, at index: Int, for key: String) {
            let shouldSkip = keysToSkip.contains(key)
            if shouldSkip {
                return
            }
            guard var array = storage[key] as? [T] else {
                storage[key] = [value]
                return
            }
            array.append(value)
            storage[key] = array
        }
    }
    
    final class UnkeyedEncodingContainer: Swift.UnkeyedEncodingContainer {
        func encode<T>(_ value: T) throws where T : Encodable {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: UInt64) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: UInt32) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: UInt16) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: UInt8) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: UInt) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: Int64) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: Int32) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: Int16) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: Int8) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: Int) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: Float) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: Double) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: String) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode(_ value: Bool) throws {
            encoder.store(arrayValue: value, at: count, for: key)
        }
        
        func encode<T: Sequence>(contentsOf sequence: T) throws where T.Element == String {
            encoder.store(sequence, for: key)
        }
        
        func nestedUnkeyedContainer() -> any Swift.UnkeyedEncodingContainer {
            UnkeyedEncodingContainer(key, encoder: encoder)
        }
        
        func superEncoder() -> any Swift.Encoder {
            encoder
        }
        
        var codingPath: [any CodingKey] = []
        
        var count: Int = 0
        
        private let key: String
        private let encoder: Encoder
        
        init(_ key: String, encoder: Encoder) {
            self.key = key
            self.encoder = encoder
        }
        
        func encodeNil() throws {
            encoder.store(arrayValue: NSNull(), at: count, for: key)
        }
        
        func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> Swift.KeyedEncodingContainer<NestedKey> {
            Swift.KeyedEncodingContainer(PocketBase.KeyedEncodingContainer(encoder: encoder))
        }
    }
    
    class SingleValueEncodingContainer: Swift.SingleValueEncodingContainer {
        
        private let key: String
        private let encoder: Encoder
        
        init(_ key: String, encoder: Encoder) {
            self.key = key
            self.encoder = encoder
        }
        
        var codingPath: [CodingKey] {
            encoder.codingPath
        }
        
        func encode<T>(_ value: T) throws where T : Encodable {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: UInt64) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: UInt32) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: UInt16) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: UInt8) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: UInt) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: Int64) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: Int32) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: Int16) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: Int8) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: Int) throws {
            encoder.store(value, for: key)
        }
        
        func encodeNil() throws {
            encoder.store(NSNull(), for: key)
        }
        
        func encode(_ value: String) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: Bool) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: Double) throws {
            encoder.store(value, for: key)
        }
        
        func encode(_ value: Float) throws {
            encoder.store(value, for: key)
        }
        
        func encode<T: Sequence>(contentsOf sequence: T) throws where T.Element == String {
            encoder.store(sequence, for: key)
        }
    }
    
    final class KeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private let encoder: Encoder

        init(encoder: Encoder) {
            self.encoder = encoder
        }

        var codingPath: [CodingKey] {
            encoder.codingPath
        }

        func encodeNil(forKey key: Key) throws {
            encoder.store(NSNull(), for: key.stringValue)
        }

        func encode(_ value: Bool, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: String, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: Double, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: Float, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: Int, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: Int8, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: Int16, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: Int32, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: Int64, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: UInt, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: UInt8, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: UInt16, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: UInt32, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode(_ value: UInt64, forKey key: Key) throws {
            encoder.store(value, for: key.stringValue)
        }

        func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            // Handle nested encodable objects
            let encoder = Encoder()
            try value.encode(to: encoder)
            encoder.store(try encoder.encodedData, for: key.stringValue)
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key
        ) -> Swift.KeyedEncodingContainer<NestedKey> {
            Swift.KeyedEncodingContainer(PocketBase.KeyedEncodingContainer(encoder: encoder))
        }

        func nestedUnkeyedContainer(forKey: Key) -> Swift.UnkeyedEncodingContainer {
            PocketBase.UnkeyedEncodingContainer(forKey.stringValue, encoder: encoder)
        }

        func superEncoder() -> Swift.Encoder {
            return encoder
        }

        func superEncoder(forKey key: Key) -> Swift.Encoder {
            return encoder
        }
    }
}
