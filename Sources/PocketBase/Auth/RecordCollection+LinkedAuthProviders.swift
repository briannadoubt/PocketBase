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
            path: PocketBase.recordsPath(collection) + "\(recordId)/external-auths",
            headers: headers
        )
    }

    /// List OAuth providers linked to the currently authenticated user
    ///
    /// Convenience method that doesn't require passing the user ID
    ///
    /// - Returns: Array of linked OAuth providers
    /// - Throws: `PocketBaseError.alreadyAuthenticated` if no user is logged in
    @Sendable
    func currentUserLinkedProviders() async throws -> [LinkedAuthProvider] {
        guard let currentUser: T = try pocketbase.authStore.record() else {
            throw PocketBaseError.alreadyAuthenticated
        }
        return try await listLinkedAuthProviders(id: currentUser.id)
    }

    func unlinkExternalAuthProvider(
        id recordId: String,
        provider: OAuthProviderName
    ) async throws {
        try await delete(
            path: PocketBase.recordsPath(collection) + "\(recordId)/external-auths/\(provider.rawValue)",
            headers: headers
        )
    }

    /// Unlink an OAuth provider from the currently authenticated user
    ///
    /// Convenience method that doesn't require passing the user ID
    ///
    /// - Parameter provider: The OAuth provider to unlink
    /// - Throws: `PocketBaseError.alreadyAuthenticated` if no user is logged in
    func unlinkExternalAuthProvider(
        provider: OAuthProviderName
    ) async throws {
        guard let currentUser: T = try pocketbase.authStore.record() else {
            throw PocketBaseError.alreadyAuthenticated
        }
        try await unlinkExternalAuthProvider(id: currentUser.id, provider: provider)
    }
}
