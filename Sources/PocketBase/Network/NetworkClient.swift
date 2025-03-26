//
//  NetworkClient.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/23/25.
//

import Foundation
package import HTTPTypes

package actor NetworkClient: Sendable, NetworkInterfacing {
    let pocketbase: PocketBase
    
    package init(_ pocketbase: PocketBase) {
        self.pocketbase = pocketbase
    }
    
    package var session: any NetworkSession {
        pocketbase.session
    }
    
    package var baseURL: URL {
        pocketbase.url
    }
    
    package let encoder: JSONEncoder = {
        PocketBase.encoder
    }()

    package let decoder: JSONDecoder = {
        PocketBase.decoder
    }()
    
    package var headers: HTTPFields {
        var headers: HTTPFields = [:]
        headers[.contentType] = "application/json"
        if let token = pocketbase.authStore.token {
            headers[.authorization] = "Bearer \(token)"
        }
        return headers
    }
    
    package var multipartHeaders: HTTPFields {
        var headers = headers
        headers[.contentType] = "multipart/form-data; boundary=Boundary-\(PocketBase.multipartEncodingBoundary)"
        return headers
    }
}
