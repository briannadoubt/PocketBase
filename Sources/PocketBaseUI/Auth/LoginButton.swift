//
//  LoginButton.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/13/24.
//

import PocketBase
import SwiftUI

public struct LoginButton<T: AuthRecord>: View, HasLogger {
    private let collection: RecordCollection<T>
    @Binding private var authState: AuthState
    private var strategy: RecordCollection<T>.AuthMethod
    
    public init(
        collection: RecordCollection<T>,
        authState: Binding<AuthState>,
        strategy: RecordCollection<T>.AuthMethod
    ) {
        self.collection = collection
        _authState = authState
        self.strategy = strategy
    }

    public var body: some View {
        Button {
            Task {
                do {
                    switch strategy {
                    case .identity(let identity, let password):
                        try await collection.authWithPassword(
                            identity,
                            password: password
                        )
                        authState = .signedIn
                    case .oauth:
                        fatalError("Not implemented")
                    }
                } catch {
                    print(error)
                }
            }
        } label: {
            switch strategy {
            case .identity:
                Label("Login", systemImage: "person.crop.circle.fill")
            case .oauth(let provider):
                Label("Login with \(provider.name)", systemImage: provider.name)
            }
        }
    }
}
