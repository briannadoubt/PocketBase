//
//  PocketBaseJSONDecoder.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

extension PocketBase {
    class JSONDecoder: Foundation.JSONDecoder, @unchecked Sendable {
        override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
            let topLevelDecoder = try super.decode(TopLevelDecoder.self, from: data)
            let pocketBaseDecoder = Decoder(decoder: topLevelDecoder.decoder)
            return try T(from: pocketBaseDecoder)
        }
    }
    
    // Top-level decoder that wraps another decoder
    private struct TopLevelDecoder: Swift.Decodable {
        let decoder: Swift.Decoder
        
        init(from decoder: Swift.Decoder) throws {
            self.decoder = decoder
        }
    }
    
    class Decoder: Swift.Decoder {
        private let decoder: Swift.Decoder
        
        init(decoder: Swift.Decoder) {
            self.decoder = decoder
        }
        
        var codingPath: [CodingKey] {
            return decoder.codingPath
        }
        
        var userInfo: [CodingUserInfoKey: Any] {
            return decoder.userInfo
        }
        
        func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> Swift.KeyedDecodingContainer<Key> {
            let container = try decoder.container(keyedBy: type)
            return Swift.KeyedDecodingContainer(KeyedDecodingContainer(container))
        }
        
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            return try decoder.unkeyedContainer()
        }
        
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            return try decoder.singleValueContainer()
        }
    }
    
    class KeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
        private let container: Swift.KeyedDecodingContainer<K>
        
        init(_ container: Swift.KeyedDecodingContainer<K>) {
            self.container = container
        }
        
        var codingPath: [CodingKey] {
            return container.codingPath
        }
        
        var allKeys: [K] {
            return container.allKeys.compactMap { key in
                if let newKey = K(stringValue: key.stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "@"))) {
                    return newKey
                }
                return key
            }
        }
        
        func contains(_ key: K) -> Bool {
            return container.contains(modify(key))
        }
        
        func decodeNil(forKey key: K) throws -> Bool {
            return try container.decodeNil(forKey: modify(key))
        }
        
        func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: String.Type, forKey key: K) throws -> String {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: Double.Type, forKey key: K) throws -> Double {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: Float.Type, forKey key: K) throws -> Float {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: Int.Type, forKey key: K) throws -> Int {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
            return try container.decode(type, forKey: modify(key))
        }
        
        func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
            try container.decode(type, forKey: modify(key))
        }
        
        func decode(_ type: Date.Type, forKey key: K) throws -> Date {
            try container.decode(Date.self, forKey: modify(key))
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> Swift.KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try container.nestedContainer(keyedBy: type, forKey: modify(key))
        }
        
        func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
            return try container.nestedUnkeyedContainer(forKey: modify(key))
        }
        
        func superDecoder() throws -> Swift.Decoder {
            return try container.superDecoder()
        }
        
        func superDecoder(forKey key: K) throws -> Swift.Decoder {
            return try container.superDecoder(forKey: modify(key))
        }
        
        func modify(_ key: K) -> K {
            if let newKey = K(stringValue: key.stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "@"))) {
                return newKey
            }
            return key
        }
    }
}
