//
//  Authentication.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/13/24.
//

import PocketBase
import SwiftUI

/// <#Description#>
public struct Authentication<T: AuthRecord, Loading: View, SignedOut: View, Content: View>: View where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
    public typealias SignedOutBuilder = (
        _ collection: RecordCollection<T>,
        _ authState: Binding<AuthState>
    ) -> SignedOut
    
    /// <#Description#>
    /// - Parameters:
    ///   - loading: <#loading description#>
    ///   - signedOut: <#signedOut description#>
    ///   - content: <#content description#>
    public init(
        @ViewBuilder loading: @escaping () -> Loading,
        @ViewBuilder signedOut: @escaping SignedOutBuilder,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.loading = loading
        self.signedOut = signedOut
        self.content = content
    }
    
    @ViewBuilder private var loading: () -> Loading
    @ViewBuilder private var signedOut: SignedOutBuilder
    @ViewBuilder private var content: () -> Content
    
    @State private var authState: AuthState = .loading

    @Environment(\.pocketbase) private var pocketbase
    
    private var collection: RecordCollection<T> {
        pocketbase.collection(T.self)
    }
    
    /// <#Description#>
    public var body: some View {
        Group {
            switch authState {
            case .loading:
                loading()
                    .task {
                        guard
                            ((try? await collection.authRefresh()) != nil),
                            pocketbase.authStore.isValid
                        else {
                            authState = .signedOut
                            return
                        }
                        authState = .signedIn
                    }
            case .signedOut:
                signedOut(collection, $authState)
            case .signedIn:
                content()
            }
        }
        .environment(\.pocketbase, pocketbase)
        .animation(.default, value: authState)
        .task {
            for await _ in NotificationCenter.default.notifications(named: .pocketbaseDidSignOut).map({ $0.name }) {
                await MainActor.run {
                    authState = .signedOut
                }
            }
        }
    }
}

public typealias CreateUser<T: AuthRecord> = (_ username: String, _ email: String) -> T

extension Authentication where Loading == ProgressView<Text, EmptyView>, SignedOut == SignedOutView<T> {
    /// <#Description#>
    /// - Parameters:
    ///   - newUser: <#newUser description#>
    ///   - content: <#content description#>
    public init(
        newUser: @escaping CreateUser<T>,
        content: @escaping () -> Content
    ) {
        self.init {
            ProgressView("Loading...")
        } signedOut: { collection, authState in
            SignedOutView(collection: collection, authState: authState, newUser: newUser)
        } content: {
            content()
        }
    }
}
