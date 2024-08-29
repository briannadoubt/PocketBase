//
//  PocketBase+AuthRefresh.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection where T: AuthRecord {
    @Sendable
    @discardableResult
    func authRefresh(
        expand: [String] = [],
        fields: [String] = []
    ) async throws -> AuthResponse<T> {
        do {
            let response: AuthResponse<T> = try await post(
                path: PocketBase.collectionPath(collection) + "auth-refresh",
                query: {
                    var query: [URLQueryItem] = []
                    if !expand.isEmpty {
                        query.append(URLQueryItem(name: "expand", value: expand.joined(separator: ",")))
                    }
                    if !fields.isEmpty {
                        query.append(URLQueryItem(name: "fields", value: fields.joined(separator: ",")))
                    }
                    return query
                }(),
                headers: headers
            )
            try pocketbase.authStore.set(response: response)
            return response
        } catch {
            pocketbase.authStore.clear()
            throw error
        }
    }
}
