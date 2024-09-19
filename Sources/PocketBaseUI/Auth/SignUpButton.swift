//
//  SignUpButton.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/24/24.
//

import SwiftUI
import PocketBase
import os

public struct SignUpButton<T: AuthRecord>: View, HasLogger where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
    let newRecord: T
    let collection: RecordCollection<T>
    @Binding private var authState: AuthState
    private var strategy: RecordCollection<T>.AuthMethod

    public init(
        _ newRecord: T,
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
                case .identity(let identity, let password, let fields):
                    try await collection.create(
                        newRecord,
                        password: password,
                        passwordConfirm: password
                    )
                    try await collection.authWithPassword(
                        identity,
                        password: password,
                        fields: fields
                    )
                case .oauth:
                    fatalError("OAuth is not implemented yet")
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
