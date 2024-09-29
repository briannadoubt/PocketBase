//
//  PocketBase+LinkedAuthProviders.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection where T: AuthRecord {
    @Sendable
    func listLinkedAuthProviders(
        id recordId: String
    ) async throws -> [LinkedAuthProvider] {
        try await get(
            path: PocketBase.recordsPath(collection) + "external-auths",
            headers: headers
        )
    }
    
    func unlinkExternalAuthProvider(
        id recordId: String,
        provider: String // TODO: Make semantic provider enum
    ) async throws {
        try await delete(
            path: PocketBase.recordsPath(collection) + "external-auths/\(provider)",
            headers: headers
        )
    }
}
