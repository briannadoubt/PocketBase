//
//  LoginView.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/13/24.
//

import PocketBase
import SwiftUI

public enum AuthState: Sendable, Equatable {
    case loading
    case signedIn
    case signedOut
}

public struct SignedOutView<T: AuthRecord>: View where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
    private let collection: RecordCollection<T>

    @Binding private var authState: AuthState
    
    private let newUser: CreateUser<T>
    
    public init(
        collection: RecordCollection<T>,
        authState: Binding<AuthState>,
        newUser: @escaping CreateUser<T>
    ) {
        self.collection = collection
        _authState = authState
        self.newUser = newUser
    }
    
    @State private var authMethods: AuthMethods?
    @State private var isNew = false
    
    @State private var loginIdentity: String = ""
    @State private var newEmail: String = ""
    @State private var newUsername: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    var identityLabel: String {
        guard let authMethods else {
            return ""
        }
        if authMethods.emailPassword && authMethods.usernamePassword {
            return "Email or Username"
        }
        if authMethods.usernamePassword {
            return "Username"
        }
        if authMethods.emailPassword {
            return "Email"
        }
        return ""
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                if let authMethods {
                    Picker("Login or Sign Up", selection: $isNew) {
                        Text("Login")
                            .tag(false)
                        Text("SignUp")
                            .tag(true)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    
                    if isNew {
                        if authMethods.emailPassword || authMethods.usernamePassword {
                            Section("Identity") {
                                if authMethods.emailPassword {
                                    TextField("Email", text: $newEmail)
                                }
                                if authMethods.usernamePassword {
                                    TextField("Username", text: $newUsername)
                                }
                            }
                            Section("Create Password") {
                                SecureField("Password", text: $password)
                                SecureField("Confirm Password", text: $confirmPassword)
                            }
                            Section {
                                SignUpButton<T>(
                                    newUser(newUsername, newEmail),
                                    collection: collection,
                                    authState: $authState,
                                    strategy: .identity(
                                        authMethods.emailPassword ? newEmail : newUsername,
                                        password: password
                                    )
                                )
                            }
                        }
                        if !authMethods.authProviders.isEmpty {
                            Section {
                                ForEach(authMethods.authProviders) { provider in
                                    SignUpButton<T>(
                                        newUser(newUsername, newEmail),
                                        collection: collection,
                                        authState: $authState,
                                        strategy: .oauth(provider)
                                    )
                                }
                            }
                        }
                    } else {
                        if authMethods.emailPassword || authMethods.usernamePassword {
                            Section("Identity") {
                                TextField(identityLabel, text: $loginIdentity)
                                SecureField("Password", text: $password)
                            }
                            Section {
                                LoginButton<T>(
                                    collection: collection,
                                    authState: $authState,
                                    strategy: .identity(loginIdentity, password: password)
                                )
                            }
                        }
                        
                        if !authMethods.authProviders.isEmpty {
                            Section {
                                ForEach(authMethods.authProviders) { provider in
                                    LoginButton<T>(
                                        collection: collection,
                                        authState: $authState,
                                        strategy: .oauth(provider)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("PocketBase Demo")
            .animation(.default, value: isNew)
            .task(id: "auth-methods") {
                await loadAuthMethods()
            }
            .refreshable {
                await loadAuthMethods()
            }
        }
    }

    private func loadAuthMethods() async {
        do {
            let authMethods = try await collection.listAuthMethods()
            self.authMethods = authMethods
        } catch {
            
        }
    }
}
