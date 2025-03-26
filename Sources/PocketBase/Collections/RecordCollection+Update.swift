//
//  RecordCollection+Update.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection {
    /// Update a given record by passing in an updated record.
    ///
    /// ```swift
    /// let pocketbase = PocketBase()
    /// let cats = pocketbase.collection(Cat.self)
    /// var cat = try await cats.view("some-id-meow-meow") // cat.age is 4, arbitrarily.
    /// cat.age += 1 // cat.age is now 5
    /// let updatedCat = try await cats.update(cat)
    /// // updatedCat.age is 5
    /// ```
    ///
    /// - note: Depending on the collection's `updateRule` value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - record: The record to be updated, with the updates pre-applied locally.
    /// - Returns: Returns a single collection record by its ID.
    @Sendable
    @discardableResult
    func update(_ record: T) async throws -> T {
        try await client.patch(
            path: PocketBase.recordPath(collection, record.id, trailingSlash: false),
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            headers: client.headers,
            body: record
        )
    }
}
