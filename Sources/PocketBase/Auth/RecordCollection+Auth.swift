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
        case .oauth(let provider):
            throw PocketBaseError.oauthFlowRequired(provider)
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

public enum PocketBaseError: Error, Equatable, LocalizedError {
    case alreadyAuthenticated
    case notImplemented
    case invalidRecordData
    case oauthFlowRequired(OAuthProvider)
    case oauthCancelled
    case oauthFailed(Error)

    public static func == (lhs: PocketBaseError, rhs: PocketBaseError) -> Bool {
        switch (lhs, rhs) {
        case (.alreadyAuthenticated, .alreadyAuthenticated):
            return true
        case (.notImplemented, .notImplemented):
            return true
        case (.invalidRecordData, .invalidRecordData):
            return true
        case (.oauthFlowRequired(let lProvider), .oauthFlowRequired(let rProvider)):
            return lProvider == rProvider
        case (.oauthCancelled, .oauthCancelled):
            return true
        case (.oauthFailed, .oauthFailed):
            // Can't compare errors reliably, just check the case
            return true
        default:
            return false
        }
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .alreadyAuthenticated:
            return "Already authenticated. Please log out before attempting to log in again."
        case .notImplemented:
            return "This feature is not yet implemented."
        case .invalidRecordData:
            return "The record data provided is invalid or incomplete."
        case .oauthFlowRequired(let provider):
            return "OAuth authentication is required for '\(provider.name)'. Use loginWithOAuth() instead of login()."
        case .oauthCancelled:
            return "OAuth authentication was cancelled by the user."
        case .oauthFailed(let error):
            return "OAuth authentication failed: \(error.localizedDescription)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .alreadyAuthenticated:
            return "A user session is already active."
        case .notImplemented:
            return "The requested functionality has not been implemented yet."
        case .invalidRecordData:
            return "The record does not conform to the expected schema."
        case .oauthFlowRequired(let provider):
            return "The '\(provider.name)' provider requires browser-based OAuth flow."
        case .oauthCancelled:
            return "The user closed the authentication window or denied access."
        case .oauthFailed(let error):
            return error.localizedDescription
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .alreadyAuthenticated:
            return "Call logout() before attempting to authenticate again."
        case .notImplemented:
            return "Check the documentation for alternative approaches or wait for a future update."
        case .invalidRecordData:
            return "Verify that all required fields are present and match the collection schema."
        case .oauthFlowRequired:
            return "Use the loginWithOAuth() method with a redirect scheme configured in your app's Info.plist."
        case .oauthCancelled:
            return "Try logging in again and complete the authorization process."
        case .oauthFailed:
            return "Check your internet connection and OAuth provider configuration. Ensure the provider is enabled in PocketBase admin settings."
        }
    }
}
