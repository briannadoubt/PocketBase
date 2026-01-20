//
//  RecordCollection+Auth.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/7/24.
//

extension RecordCollection where T: AuthRecord {
    @discardableResult
    public func login(with method: AuthMethod) async throws -> T {
        switch method {
        case .identity(let identity, let password):
            try await self.authWithPassword(
                identity,
                password: password
            ).record
        case .oauth:
            throw PocketBaseError.notImplemented
        }
    }

    public func logout() {
        pocketbase.authStore.clear()
        NotificationCenter.default.post(name: .pocketbaseDidSignOut, object: nil)
    }

    public enum AuthMethod: Sendable {
        case identity(
            _ identity: String,
            password: String
        )

        case oauth(OAuthProvider)
    }
}

public enum PocketBaseError: Error {
    case alreadyAuthenticated
    case notImplemented
    case invalidRecordData
}
