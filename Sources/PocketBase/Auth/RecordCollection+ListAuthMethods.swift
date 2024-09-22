//
//  PocketBase+ListAuthMethods.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection where T: AuthRecord {
    @Sendable
    func listAuthMethods() async throws -> AuthMethods {
        try await get(
            path: PocketBase.collectionPath(collection) + "auth-methods",
            headers: headers
        )
    }
}
