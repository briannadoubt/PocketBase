//
//  Client.swift
//  PocketBase
//
//  Created by Bri on 9/24/22.
//

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, macOS 12.0, watchOS 7.0, tvOS 14.0, *)
@propertyWrapper
public struct Client: DynamicProperty {
    @StateObject private var pocketBase: PocketBase
    public var wrappedValue: PocketBase {
        pocketBase
    }
    public init(_ baseUrl: URL?) {
        _pocketBase = StateObject(wrappedValue: PocketBase(baseUrl!))
    }
}
#endif
