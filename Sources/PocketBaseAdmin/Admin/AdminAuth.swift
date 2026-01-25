//
//  AdminAuth.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Admin authentication operations.
public actor AdminAuth: AdminNetworking {
    public let pocketbase: PocketBase

    public init(pocketbase: PocketBase) {
        self.pocketbase = pocketbase
    }

    /// Authenticate an admin with email and password.
    ///
    /// - Parameters:
    ///   - email: The admin's email address.
    ///   - password: The admin's password.
    /// - Returns: Admin authentication response with token and admin record.
    /// - Throws: PocketBaseError if authentication fails.
    @discardableResult
    public func authWithPassword(
        _ email: String,
        password: String
    ) async throws -> AdminAuthResponse {
        struct RequestBody: Encodable {
            let identity: String
            let password: String
        }

        let body = RequestBody(identity: email, password: password)
        let bodyData = try encoder.encode(body)

        let response: AdminAuthResponse = try await post(
            path: "/api/admins/auth-with-password",
            body: bodyData
        )

        // Store the auth token (admin authentication doesn't use the record storage)
        pocketbase.authStore.set(token: response.token)

        return response
    }

    /// Refresh the current admin's authentication token.
    ///
    /// - Returns: Refreshed admin authentication response.
    /// - Throws: PocketBaseError if refresh fails.
    @discardableResult
    public func refresh() async throws -> AdminAuthResponse {
        let response: AdminAuthResponse = try await post(
            path: "/api/admins/auth-refresh"
        )

        // Update stored token
        pocketbase.authStore.set(token: response.token)

        return response
    }

    /// Request a password reset email for an admin.
    ///
    /// - Parameter email: The admin's email address.
    /// - Throws: PocketBaseError if the request fails.
    public func requestPasswordReset(_ email: String) async throws {
        struct RequestBody: Encodable {
            let email: String
        }

        let body = RequestBody(email: email)
        let bodyData = try encoder.encode(body)

        let _: EmptyResponse = try await post(
            path: "/api/admins/request-password-reset",
            body: bodyData
        )
    }

    /// Confirm a password reset using the token from the email.
    ///
    /// - Parameters:
    ///   - token: The password reset token from the email.
    ///   - password: The new password.
    ///   - passwordConfirm: Confirmation of the new password.
    /// - Throws: PocketBaseError if confirmation fails.
    public func confirmPasswordReset(
        token: String,
        password: String,
        passwordConfirm: String
    ) async throws {
        struct RequestBody: Encodable {
            let token: String
            let password: String
            let passwordConfirm: String
        }

        let body = RequestBody(
            token: token,
            password: password,
            passwordConfirm: passwordConfirm
        )
        let bodyData = try encoder.encode(body)

        let _: EmptyResponse = try await post(
            path: "/api/admins/confirm-password-reset",
            body: bodyData
        )
    }
}

/// Empty response for operations that return no content.
private struct EmptyResponse: Decodable {}
