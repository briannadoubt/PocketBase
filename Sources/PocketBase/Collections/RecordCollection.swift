//
//  File.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation
internal import HTTPTypes

public actor RecordCollection<T: Record>: NetworkInterfacing, Sendable {
    var baseURL: URL {
        pocketbase.url
    }
    
    let pocketbase: PocketBase
    
    var session: any NetworkSession {
        pocketbase.session
    }
    
    let collection: String
    
    let encoder: JSONEncoder = {
        PocketBase.encoder
    }()

    let decoder: JSONDecoder = {
        PocketBase.decoder
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
    
    package var multipartHeaders: HTTPFields {
        {
            var headers = headers
            headers[.contentType] = "multipart/form-data; boundary=Boundary-\(PocketBase.multipartEncodingBoundary)"
            return headers
        }()
    }
}
