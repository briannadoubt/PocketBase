//
//  PocketBase+Paths.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

extension PocketBase {
    static func collectionPath(_ collectionIdOrName: String) -> String {
        "/api/collections/" + collectionIdOrName + "/"
    }
    
    static func recordsPath(_ collectionIdOrName: String) -> String {
        collectionPath(collectionIdOrName) + "records/"
    }
    
    static func recordPath(_ collectionIdOrName: String, _ recordId: String) -> String {
        recordsPath(collectionIdOrName) + "/" + recordId
    }
}
