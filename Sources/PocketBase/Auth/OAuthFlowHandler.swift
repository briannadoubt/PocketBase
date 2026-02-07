//
//  OAuthFlowHandler.swift
//  PocketBase
//
//  OAuth flow handler using ASWebAuthenticationSession
//

import Foundation

#if canImport(AuthenticationServices)
import AuthenticationServices

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

@available(iOS 12.0, macOS 10.15, *)
@MainActor
protocol OAuthAuthenticating {
    func authenticate(
        authUrl: URL,
        redirectScheme: String,
        expectedState: String?,
        preferEphemeralSession: Bool
    ) async throws -> String
}

@available(iOS 12.0, macOS 10.15, *)
@MainActor
final class OAuthFlowHandler: NSObject, ASWebAuthenticationPresentationContextProviding, OAuthAuthenticating {
    private var continuation: CheckedContinuation<String, Error>?
    private var authSession: ASWebAuthenticationSession?
    
    nonisolated static let errorDomain = "io.pocketbase.oauth"
    
    enum ErrorCode: Int {
        case noCallbackURL = 1
        case failedToStartSession = 2
        case providerError = 3
        case missingCode = 4
        case stateMismatch = 5
    }

    /// Launch OAuth flow and extract authorization code from callback
    ///
    /// - Parameters:
    ///   - authUrl: The OAuth provider's authorization URL
    ///   - redirectScheme: The URL scheme to intercept (e.g., "myapp")
    ///   - expectedState: The expected state to validate against callback state
    ///   - preferEphemeralSession: Whether to use ephemeral browser session (default: true for security)
    /// - Returns: The authorization code from the OAuth callback
    func authenticate(
        authUrl: URL,
        redirectScheme: String,
        expectedState: String? = nil,
        preferEphemeralSession: Bool = true
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let session = ASWebAuthenticationSession(
                url: authUrl,
                callbackURLScheme: redirectScheme
            ) { [weak self] callbackURL, error in
                guard let self = self else { return }

                if let error = error {
                    // User cancelled the flow
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self.complete(.failure(PocketBaseError.oauthCancelled))
                    } else {
                        self.complete(.failure(PocketBaseError.oauthFailed(error)))
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    self.complete(.failure(PocketBaseError.oauthFailed(Self.error(
                        code: .noCallbackURL,
                        description: "No callback URL received"
                    ))))
                    return
                }

                // Extract code from callback URL
                do {
                    let code = try Self.parseAuthorizationCode(
                        from: callbackURL,
                        expectedState: expectedState
                    )
                    self.complete(.success(code))
                } catch {
                    self.complete(.failure(error))
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = preferEphemeralSession
            self.authSession = session

            if !session.start() {
                self.complete(.failure(PocketBaseError.oauthFailed(Self.error(
                    code: .failedToStartSession,
                    description: "Failed to start authentication session"
                ))))
            }
        }
    }
    
    private func complete(_ result: Result<String, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        authSession = nil
        switch result {
        case .success(let code):
            continuation.resume(returning: code)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
    
    nonisolated static func parseAuthorizationCode(
        from callbackURL: URL,
        expectedState: String?
    ) throws -> String {
        guard
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems
        else {
            throw PocketBaseError.oauthFailed(error(
                code: .missingCode,
                description: "Invalid callback URL"
            ))
        }
        
        func value(for key: String) -> String? {
            queryItems.first(where: { $0.name == key })?.value
        }
        
        if let providerError = value(for: "error") {
            let providerDescription = value(for: "error_description") ?? "OAuth provider returned '\(providerError)'"
            throw PocketBaseError.oauthFailed(error(
                code: .providerError,
                description: providerDescription
            ))
        }
        
        if let expectedState {
            let callbackState = value(for: "state")
            guard callbackState == expectedState else {
                throw PocketBaseError.oauthFailed(error(
                    code: .stateMismatch,
                    description: "State mismatch in OAuth callback"
                ))
            }
        }
        
        guard let code = value(for: "code"), code.isEmpty == false else {
            throw PocketBaseError.oauthFailed(error(
                code: .missingCode,
                description: "No authorization code found in callback URL"
            ))
        }
        return code
    }

    nonisolated static func error(
        code: ErrorCode,
        description: String
    ) -> NSError {
        NSError(
            domain: errorDomain,
            code: code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        // ASWebAuthenticationSession calls this from main thread
        return MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
        #elseif os(macOS)
        return MainActor.assumeIsolated {
            NSApplication.shared.windows.first ?? ASPresentationAnchor()
        }
        #else
        return ASPresentationAnchor()
        #endif
    }
}

#endif
