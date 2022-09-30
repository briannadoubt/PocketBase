//
//  Environment+baseUrl.swift
//  PocketBase
//
//  Created by Bri on 9/26/22.
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI

public struct PocketBaseURLKey: EnvironmentKey {
    public static let defaultValue: URL = PocketBase.baseUrl
}

public extension EnvironmentValues {
    var baseUrl: URL {
        get {
            self[PocketBaseURLKey.self]
        }
        set {
            PocketBase.userDefaults.set(newValue, forKey: PocketBase.baseUrlUserDefaultsKey)
            self[PocketBaseURLKey.self] = newValue
        }
    }
}
#endif
