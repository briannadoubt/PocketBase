//
//  PocketBase+Paths.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

extension PocketBase {
    static func collectionPath(_ collectionIdOrName: String, trailingSlash: Bool = true) -> String {
        "/api/collections/" + collectionIdOrName + (trailingSlash ? "/" : "")
    }
    
    static func recordsPath(_ collectionIdOrName: String, trailingSlash: Bool = true) -> String {
        collectionPath(collectionIdOrName) + "records" + (trailingSlash ? "/" : "")
    }
    
    static func recordPath(_ collectionIdOrName: String, _ recordId: String, trailingSlash: Bool = true) -> String {
        recordsPath(collectionIdOrName, trailingSlash: false) + "/" + recordId + (trailingSlash ? "/" : "")
    }
}
