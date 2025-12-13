//
//  SignUpButton.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/24/24.
//

import SwiftUI
import PocketBase
import os

public struct SignUpButton<T: AuthRecord>: View, HasLogger {
    let newRecord: CreateUser<T>
    let collection: RecordCollection<T>
    @Binding private var authState: AuthState
    private let email: String
    private let username: String
    private let password: String
    private let oauthProvider: OAuthProvider?

    /// Initialize for email/password sign up
    public init(
        _ newRecord: @escaping CreateUser<T>,
        collection: RecordCollection<T>,
        authState: Binding<AuthState>,
        email: String,
        username: String,
        password: String
    ) {
        self.newRecord = newRecord
        self.collection = collection
        _authState = authState
        self.email = email
        self.username = username
        self.password = password
        self.oauthProvider = nil
    }

    /// Initialize for OAuth sign up
    public init(
        _ newRecord: @escaping CreateUser<T>,
        collection: RecordCollection<T>,
        authState: Binding<AuthState>,
        provider: OAuthProvider
    ) {
        self.newRecord = newRecord
        self.collection = collection
        _authState = authState
        self.email = ""
        self.username = ""
        self.password = ""
        self.oauthProvider = provider
    }

    func signUp() {
        Task {
            do {
                if let provider = oauthProvider {
                    // OAuth sign up - not implemented yet
                    Self.logger.fault("OAuth is not implemented yet for provider: \(provider.name)")
                    return
                }

                let record = try await newRecord(username, email)
                try await collection.create(
                    record,
                    password: password,
                    passwordConfirm: password
                )
                // Use email or username as identity for login
                let identity = email.isEmpty ? username : email
                try await collection.authWithPassword(
                    identity,
                    password: password
                )
                await MainActor.run {
                    authState = .signedIn
                }
            } catch {
                Self.logger.error("Failed to sign up: \(error)")
            }
        }
    }

    public var body: some View {
        Button(action: signUp) {
            if let provider = oauthProvider {
                Label("Sign Up with \(provider.name)", systemImage: provider.name)
            } else {
                Label("Sign Up", systemImage: "person.crop.circle.fill")
            }
        }
    }
}
