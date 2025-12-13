//
//  CreateUser.swift
//  PocketBase
//
//  Created by Brianna Zamora on 10/2/24.
//

import PocketBase

/// A callback type that takes an email and username, and returns a new `AuthRecord` instance.
/// The password is handled separately by the collection's create method.
public typealias CreateUser<T: AuthRecord> = (
    _ username: String,
    _ email: String
) async throws -> T
