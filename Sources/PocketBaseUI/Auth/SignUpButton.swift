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
    private var strategy: RecordCollection<T>.AuthMethod

    public init(
        _ newRecord: @escaping CreateUser<T>,
        collection: RecordCollection<T>,
        authState: Binding<AuthState>,
        strategy: RecordCollection<T>.AuthMethod
    ) {
        self.newRecord = newRecord
        self.collection = collection
        _authState = authState
        self.strategy = strategy
    }
    
    func signUp() {
        Task {
            do {
                switch strategy {
                case .identity(let identity, let password):
                    let newRecord = try await newRecord(identity, password)
                    try await collection.create(
                        newRecord,
                        password: password,
                        passwordConfirm: password
                    )
                    try await collection.authWithPassword(
                        identity,
                        password: password
                    )
                case .oauth:
                    Self.logger.fault("OAuth is not implemented yet")
                }
                authState = .signedIn
            } catch {
                Self.logger.error("Failed to sign up: \(error)")
            }
        }
    }
    
    public var body: some View {
        Button(action: signUp) {
            switch strategy {
            case .identity:
                Label("Sign Up", systemImage: "person.crop.circle.fill")
            case .oauth(let provider):
                Label("Sign Up with \(provider.name)", systemImage: provider.name)
            }
        }
    }
}
