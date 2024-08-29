//
//  LinkedAuthProvider.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public struct LinkedAuthProvider: Decodable, Sendable {
    var id: String
    var created: Date
    var updated: Date
    var recordId: String
    var collectionId: String
    var provider: String
    var providerId: String
}
