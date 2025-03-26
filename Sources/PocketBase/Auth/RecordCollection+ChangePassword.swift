//
//  PocketBase+ChangePassword.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

public extension RecordCollection where T: AuthRecord {
    @Sendable
    func requestPasswordReset(
        email: String
    ) async throws {
        try await client.post(
            path: PocketBase.collectionPath(collection) + "request-password-reset",
            headers: client.headers,
            body: ["email": email]
        )
    }
    
    @Sendable
    func confirmPasswordReset(
        token: String,
        password: String,
        passwordConfirm: String
    ) async throws {
        try await client.post(
            path: PocketBase.collectionPath(collection) + "confirm-password-reset",
            headers: client.headers,
            body: [
                "token": token,
                "password": password,
                "passwordConfirm": passwordConfirm
            ]
        )
    }
}
