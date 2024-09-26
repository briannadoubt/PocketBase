//
//  PocketBase+ChangeEmail.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

public extension RecordCollection where T: AuthRecord {
    func requestEmailChange(
        newEmail: String
    ) async throws {
        try await post(
            path: PocketBase.collectionPath(collection) + "request-email-change",
            headers: headers,
            body: ["newEmail": newEmail]
        )
    }
    
    func confirmEmailChange(
        token: String,
        password: String
    ) async throws {
        try await post(
            path: PocketBase.collectionPath(collection) + "confirm-email-change",
            headers: headers,
            body: [
                "token": token,
                "password": password
            ]
        )
    }
}
