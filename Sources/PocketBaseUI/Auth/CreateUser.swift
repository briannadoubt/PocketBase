//
//  CreateUser.swift
//  PocketBase
//
//  Created by Brianna Zamora on 10/2/24.
//

import PocketBase

/// A callback type that takes a username and password and returns a new `AuthRecord` instance.
public typealias CreateUser<T: AuthRecord> = (
    _ username: String,
    _ email: String
) async throws -> T
