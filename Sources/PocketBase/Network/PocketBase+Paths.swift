//
//  PocketBase+Paths.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

extension PocketBase {
    package static func collectionPath(_ collectionIdOrName: String, trailingSlash: Bool = true) -> String {
        "/api/collections/" + collectionIdOrName + (trailingSlash ? "/" : "")
    }
    
    package static func recordsPath(_ collectionIdOrName: String, trailingSlash: Bool = true) -> String {
        collectionPath(collectionIdOrName) + "records" + (trailingSlash ? "/" : "")
    }
    
    package static func recordPath(_ collectionIdOrName: String, _ recordId: String, trailingSlash: Bool = true) -> String {
        recordsPath(collectionIdOrName, trailingSlash: false) + "/" + recordId + (trailingSlash ? "/" : "")
    }
    
    public static func filePath(_ collectionIdOrName: String, _ recordId: String, _ fileName: String) -> String {
        "/api/files/\(collectionIdOrName)/\(recordId)/\(fileName)"
    }
}
