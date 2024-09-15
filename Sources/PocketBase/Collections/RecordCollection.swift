//
//  File.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation
internal import HTTPTypes

public actor RecordCollection<T: Record>: NetworkInterfacing, Sendable {
    public var baseURL: URL {
        pocketbase.url
    }
    
    let pocketbase: PocketBase
    
    public var session: any NetworkSession {
        pocketbase.session
    }
    
    let collection: String
    
    public let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
        encoder.dateEncodingStrategy = .formatted(formatter)
        return encoder
    }()

    public let decoder: JSONDecoder = {
        let encoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
        encoder.dateDecodingStrategy = .formatted(formatter)
        return encoder
    }()
    
    public init(
        _ collection: String,
        _ pocketbase: PocketBase
    ) {
        self.collection = collection
        self.pocketbase = pocketbase
    }
    
    var headers: HTTPFields {
        var headers: HTTPFields = [:]
        headers[.contentType] = "application/json"
        if let token = pocketbase.authStore.token {
            headers[.authorization] = "Bearer \(token)"
        }
        return headers
    }
}
