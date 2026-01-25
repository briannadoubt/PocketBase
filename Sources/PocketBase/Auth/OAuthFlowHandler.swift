//
//  OAuthFlowHandler.swift
//  PocketBase
//
//  OAuth flow handler using ASWebAuthenticationSession for iOS/macOS
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
final class OAuthFlowHandler: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var continuation: CheckedContinuation<String, Error>?
    private var authSession: ASWebAuthenticationSession?

    /// Launch OAuth flow and extract authorization code from callback
    ///
    /// - Parameters:
    ///   - authUrl: The OAuth provider's authorization URL
    ///   - redirectScheme: The URL scheme to intercept (e.g., "myapp")
    ///   - preferEphemeralSession: Whether to use ephemeral browser session (default: true for security)
    /// - Returns: The authorization code from the OAuth callback
    func authenticate(
        authUrl: URL,
        redirectScheme: String,
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
                        self.continuation?.resume(throwing: PocketBaseError.oauthCancelled)
                    } else {
                        self.continuation?.resume(throwing: PocketBaseError.oauthFailed(error))
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    self.continuation?.resume(throwing: PocketBaseError.oauthFailed(
                        NSError(domain: "OAuthFlowHandler", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "No callback URL received"
                        ])
                    ))
                    return
                }

                // Extract code from callback URL
                do {
                    let code = try self.extractCode(from: callbackURL)
                    self.continuation?.resume(returning: code)
                } catch {
                    self.continuation?.resume(throwing: error)
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = preferEphemeralSession

            if !session.start() {
                continuation.resume(throwing: PocketBaseError.oauthFailed(
                    NSError(domain: "OAuthFlowHandler", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to start authentication session"
                    ])
                ))
            }

            self.authSession = session
        }
    }

    /// Extract authorization code from OAuth callback URL
    ///
    /// - Parameter url: The callback URL (e.g., myapp://callback?code=abc123)
    /// - Returns: The authorization code
    private func extractCode(from url: URL) throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let codeItem = queryItems.first(where: { $0.name == "code" }),
              let code = codeItem.value else {
            throw PocketBaseError.oauthFailed(
                NSError(domain: "OAuthFlowHandler", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "No authorization code found in callback URL"
                ])
            )
        }
        return code
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
