//
//  AuthenticationModifier.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/13/24.
//

import SwiftUI
import PocketBase

extension View {
    /// <#Description#>
    /// - Parameter newUser: <#newUser description#>
    /// - Returns: <#description#>
    public func authenticated<T: AuthRecord>(
        newUser: @escaping CreateUser<T>
    ) -> some View where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
        modifier(
            AuthenticationModifier(
                newUser: newUser
            )
        )
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - Type: <#Type description#>
    ///   - loading: <#loading description#>
    ///   - signedOut: <#signedOut description#>
    /// - Returns: <#description#>
    public func authenticated<T: AuthRecord, Loading: View, SignedOut: View>(
        as Type: T.Type,
        loading: @escaping () -> Loading,
        signedOut: @escaping (
            _ collection: RecordCollection<T>,
            _ authState: Binding<AuthState>
        ) -> SignedOut
    ) -> some View where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
        modifier(
            AuthenticationModifier(
                loading: loading,
                signedOut: signedOut
            )
        )
    }
}

private struct AuthenticationModifier<T: AuthRecord, Loading: View, SignedOut: View>: ViewModifier where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
    @ViewBuilder private var loading: () -> Loading
    
    typealias SignedOutBuilder = Authentication<T, Loading, SignedOut, Content>.SignedOutBuilder
    @ViewBuilder private var signedOut: SignedOutBuilder
    
    init(
        @ViewBuilder loading: @escaping () -> Loading,
        @ViewBuilder signedOut: @escaping SignedOutBuilder
    ) {
        self.loading = loading
        self.signedOut = signedOut
    }

    func body(content: Content) -> some View {
        Authentication(
            loading: loading,
            signedOut: signedOut,
            content: {
                content
            }
        )
    }
}

extension AuthenticationModifier where Loading == ProgressView<Text, EmptyView>, SignedOut == SignedOutView<T> {
    init(newUser: @escaping CreateUser<T>) {
        self.init {
            ProgressView("Loading...")
        } signedOut: { collection, authState in
            SignedOutView(
                collection: collection,
                authState: authState,
                newUser: newUser
            )
        }
    }
}
