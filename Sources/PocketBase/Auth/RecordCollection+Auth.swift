//
//  RecordCollection+Auth.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/7/24.
//

extension RecordCollection where T: AuthRecord {
    public func login(with method: AuthMethod) async throws -> T {
        switch method {
        case .identity(let identity, let password, let expand, let fields):
            try await self.authWithPassword(
                identity,
                password: password,
                expand: expand,
                fields: fields
            ).record
        case .oauth:
            throw PocketBaseError.notImplemented
        }
    }

    public func logout() {
        pocketbase.authStore.clear()
        NotificationCenter.default.post(name: .pocketbaseDidSignOut, object: nil)
    }

    public enum PocketBaseError: Error {
        case alreadyAuthenticated
        case notImplemented
    }

    public enum AuthMethod {
        case identity(
            _ username: String,
            password: String,
            expand: [String] = [],
            fields: [String] = []
        )

        case oauth(OAuthProvider)
    }
}
