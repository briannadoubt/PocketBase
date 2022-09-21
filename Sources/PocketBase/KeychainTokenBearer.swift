//
//  KeychainTokenBearer.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import KeychainAccess

/// A token bearer that saves the token to the device's Keychain.
public protocol KeychainTokenBearer: TokenBearer { }

public extension KeychainTokenBearer {
    var keychain: Keychain { Keychain() }
    var token: String? {
        get {
            keychain[string: tokenKey]
        }
        set {
            keychain[string: tokenKey] = newValue
        }
    }
}
