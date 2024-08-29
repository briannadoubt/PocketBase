//
//  File.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation
internal import HTTPTypes

public struct RecordCollection<T: Record>: Identifiable, NetworkInterfacing, Sendable {
    public var baseURL: URL {
        pocketbase.url
    }
    
    let pocketbase: PocketBase
    
    public var session: any NetworkSession {
        pocketbase.session
    }
    
    public var id: String {
        collection
    }
    
    let collection: String
    
    public let encoder: JSONEncoder = PocketBase.JSONEncoder()
    public let decoder: JSONDecoder = PocketBase.JSONDecoder()
    
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
