//
//  PocketBase.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/2/24.
//

@_exported import Foundation
import MultipartKit

/// Interface with PocketBase
public struct PocketBase: Sendable, HasLogger {
    public let url: URL
    
    public let authStore: AuthStore
    let realtime: Realtime
    
    let session: any NetworkSession
    
    public init(
        url: URL,
        defaults: UserDefaults? = UserDefaults.pocketbase,
        session: any NetworkSession = URLSession.shared,
        authStore: AuthStore = AuthStore()
    ) {
        Self.logger.trace(#function)
        self.url = url
        self.realtime = Realtime(baseUrl: url)
        self.session = session
        Self.set(url: url, defaults: defaults)
        self.authStore = authStore
    }
    
    public init(
        fromStoredURL defaults: UserDefaults? = UserDefaults.pocketbase,
        session: any NetworkSession = URLSession.shared,
        authStore: AuthStore = AuthStore()
    ) {
        Self.logger.trace(#function)
        let url: URL
        if let cachedURL = defaults?.url(forKey: PocketBase.urlKey) {
            url = cachedURL
        } else {
            Self.logger.fault("Please configure a PocketBase URL in UserDefaults with the key \"io.pocketbase.url\". This can be accomplished using `PocketBase.set(url:)`, creating your own instance with `PocketBase(url:)`, or by setting the PocketBase instance within the app’s SwiftUI environment with `.pocketbase(url:)`. By default, localhost is used if no URL is configured.")
            url = .localhost
        }
        self.init(url: url, defaults: defaults, session: session, authStore: authStore)
    }
    
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
        encoder.dateEncodingStrategy = .formatted(formatter)
        return encoder
    }()
    
    package static let formEncoder: FormDataEncoder = {
        let encoder = FormDataEncoder()
        return encoder
    }()

    public static let decoder: JSONDecoder = {
        let encoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
        encoder.dateDecodingStrategy = .formatted(formatter)
        return encoder
    }()
    
    public func collection<T: Record>(_ type: T.Type) -> RecordCollection<T> {
        Self.logger.trace(#function)
        return RecordCollection(T.collection, self)
    }
}

extension PocketBase {
    public static let localhost = PocketBase(
        url: URL.localhost
    )
    
    public static func set(url: URL, defaults: UserDefaults? = UserDefaults.pocketbase) {
        Self.logger.trace(#function)
        defaults?.set(url, forKey: Self.urlKey)
    }
    
    public static let urlKey: String = "io.pocketbase.url"
    public static let lastEventKey: String = "io.pocketbase.lastEvent"
}

extension PocketBase {
    public enum EncodingConfiguration {
        case remoteBody
        case none
    }
    
    package static let multipartEncodingBoundary = UUID().uuidString
}

extension URL {
    public static let localhost = URL(string: "http://localhost:8090")!
}

@available(*, deprecated, renamed: "PocketBase", message: "Requires a capitol 'B'")
public struct Pocketbase {}
