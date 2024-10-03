//
//  AuthenticationModifier.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/13/24.
//

import SwiftUI
import PocketBase

extension View {
    /// Create an authentication flow with the default PocketBase auth flow UI.
    ///
    /// Attach this to a top-level view. The parent view will be replaced with the signed out view until authentication is successful.
    ///
    /// ```swift
    /// @main
    /// struct CatApp: App {
    ///     var body: some Scene {
    ///     WindowGroup {
    ///         ContentView()
    ///             .authenticated { username, email in // <~ The username/email that is entered into the input fields of the `SignedOutView`.
    ///                 User(
    ///                     username: username,
    ///                     email: email
    ///                 )
    ///             }
    ///         }
    ///         .pocketbase(.localhost)
    ///     }
    /// }
    /// ```
    ///
    /// - note: For a production app, you will probably want to use `.authenticated(as:loading:signedOut)` to customize this flow to your business.
    /// - Parameter newUser: A callback that enables defining a fresh `AuthRecord` instance when a "sign up" action occurs.
    /// - Returns: A flow that blocks the parent view until authentication is successful.
    public func authenticated<T: AuthRecord>(
        newUser: @escaping CreateUser<T>
    ) -> some View {
        modifier(
            AuthenticationModifier(
                newUser: newUser
            )
        )
    }
    
    /// Create a custom authentication flow for PocketBase.
    ///
    /// Attach this to a top-level view. The parent view will be replaced with the signed out view until authentication is successful.
    ///
    /// ```swift
    /// @main
    /// struct CatApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///                 .authenticated(as: User.self) {
    ///                     ProgressView("Loading...")
    ///                 } signedOut: { collection, authState in
    ///                     CustomLoginScreen(
    ///                         collection: collection,
    ///                         authState: authState
    ///                     )
    ///                 }
    ///         }
    ///         .pocketbase(.localhost)
    ///     }
    /// }
    ///
    /// struct CustomLoginScreen: View {
    ///    @Environment(\.pocketbase) private var pocketbase // <~ get the `PocketBase` instance from the environment to make mutations
    ///
    ///    var collection: RecordCollection<User>
    ///    @Binding var authState: AuthState
    ///
    ///    var body: some View {
    ///        // All your fancy styling here
    ///
    ///        SignUpButton(
    ///            User.self,
    ///            collection: collection,
    ///            authState: $authState,
    ///            strategy: .identity(
    ///                "meowface",
    ///                password: "Test1234"
    ///            )
    ///        )
    ///    }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The `AuthRecord` type for this flow.
    ///   - loading: The view shown when loading the initial login state.
    ///   - signedOut: The sign-in/sign-up form used to authenticate an `AuthRecord` type.
    /// - Returns: A flow that blocks the parent view until authentication is successful.
    public func authenticated<T: AuthRecord, Loading: View, SignedOut: View>(
        as type: T.Type = T.self,
        loading: @escaping () -> Loading,
        signedOut: @escaping (
            _ collection: RecordCollection<T>,
            _ authState: Binding<AuthState>
        ) -> SignedOut
    ) -> some View {
        modifier(
            AuthenticationModifier(
                loading: loading,
                signedOut: signedOut
            )
        )
    }
}

private struct AuthenticationModifier<T: AuthRecord, Loading: View, SignedOut: View>: ViewModifier {
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

private extension AuthenticationModifier where Loading == ProgressView<Text, EmptyView>, SignedOut == SignedOutView<T> {
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
