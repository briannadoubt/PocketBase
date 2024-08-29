//
//  PocketBase+ChangeEmail.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

public extension RecordCollection where T: AuthRecord {
    @Sendable
    func requestEmailChange(
        _ type: T.Type,
        newEmail: String
    ) async throws {
        try await post(
            path: PocketBase.collectionPath(collection) + "request-email-change/",
            query: [],
            headers: headers,
            body: ["newEmail": newEmail]
        )
    }
    
    @Sendable
    func confirmEmailChange(
        _ type: T.Type,
        token: String,
        password: String
    ) async throws {
        try await post(
            path: PocketBase.collectionPath(collection) + "confirm-email-change/",
            query: [],
            headers: headers,
            body: [
                "token": token,
                "password": password
            ]
        )
    }
}
