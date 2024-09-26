//
//  PocketBase+Verification.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

public extension RecordCollection where T: AuthRecord {
    @Sendable
    func requestVerification(
        email: String
    ) async throws {
        try await post(
            path: PocketBase.collectionPath(collection) + "request-verification",
            query: [],
            headers: headers,
            body: ["email": email]
        )
    }
    
    @Sendable
    func confirmVerification(
        token: String,
        password: String,
        passwordConfirm: String
    ) async throws {
        try await post(
            path: PocketBase.collectionPath(collection) + "confirm-verification",
            query: [],
            headers: headers,
            body: [
                "token": token,
                "password": password,
                "passwordConfirm": passwordConfirm
            ]
        )
    }
}
