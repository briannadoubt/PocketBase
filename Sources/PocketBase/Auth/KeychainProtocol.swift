//
//  KeychainProtocol.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/28/24.
//

@preconcurrency import KeychainAccess

public protocol KeychainProtocol: AnyObject, Sendable {
    init(service: String)
    subscript(_ key: String) -> String? { get set }
    var service: String { get }
}

extension Keychain: KeychainProtocol, @unchecked @retroactive Sendable {}

/// This exists so that we don't have to import `KeychainAccess` anywhere else.
public typealias DefaultKeychain = Keychain
