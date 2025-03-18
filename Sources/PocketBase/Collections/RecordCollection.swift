//
//  RecordCollection.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation
package import HTTPTypes

public actor RecordCollection<T: Record>: NetworkInterfacing, Sendable {
    package var baseURL: URL {
        pocketbase.url
    }
    
    package let pocketbase: PocketBase
    
    package var session: any NetworkSession {
        pocketbase.session
    }
    
    package let collection: String
    
    package let encoder: JSONEncoder = {
        PocketBase.encoder
    }()

    package let decoder: JSONDecoder = {
        PocketBase.decoder
    }()
    
    public init(
        _ collection: String,
        _ pocketbase: PocketBase
    ) {
        self.collection = collection
        self.pocketbase = pocketbase
    }
    
    package var headers: HTTPFields {
        var headers: HTTPFields = [:]
        headers[.contentType] = "application/json"
        if let token = pocketbase.authStore.token {
            headers[.authorization] = "Bearer \(token)"
        }
        return headers
    }
}
