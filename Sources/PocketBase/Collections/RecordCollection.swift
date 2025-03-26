//
//  RecordCollection.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation

public actor RecordCollection<T: Record>: Sendable, HasLogger {
    let pocketbase: PocketBase
    let client: NetworkClient
    let collection: String
    
    public init(
        _ collection: String,
        _ pocketbase: PocketBase
    ) {
        self.collection = collection
        self.client = NetworkClient(pocketbase)
        self.pocketbase = pocketbase
    }
}
