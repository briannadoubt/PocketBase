//
//  PocketBase.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/2/24.
//

@_exported import Foundation
import SwiftData

/// Interface with PocketBase
public struct PocketBase: Sendable {
    public let url: URL
    
    public let authStore = AuthStore()
    public let realtime: Realtime
    
    let session: NetworkSession
    
    public init(url: URL, session: NetworkSession = URLSession.shared) {
        self.url = url
        self.realtime = Realtime(baseUrl: url)
        self.session = session
        Self.set(url: url)
    }
    
    public init(
        fromStoredURL url: URL = {
            guard let url = UserDefaults.pocketbase?.url(forKey: PocketBase.urlKey) else {
                preconditionFailure("Please configure a PocketBase URL in UserDefaults with the key \"io.pocketbase.url\". This can be accomplished using `PocketBase.set(url:)`, creating your own instance with `PocketBase(url:)`, or by setting the PocketBase instance within the app’s SwiftUI environment with `.pocketbase(url:)`. By default, localhost is used if no URL is configured.")
            }
            return url
        }()
    ) {
        self.init(url: url)
    }
    
    public func collection<T: Record>(_ type: T.Type) -> RecordCollection<T> {
        RecordCollection(T.collection, self)
    }
}

extension PocketBase {
    public static let localhost = PocketBase(url: URL.localhost)
    
    public static func set(url: URL) {
        UserDefaults.pocketbase?.set(url, forKey: Self.urlKey)
    }
    
    public static let urlKey: String = "io.pocketbase.url"
    public static let lastEventKey: String = "io.pocketbase.lastEvent"
}

extension URL {
    public static let localhost = URL(string: "http://localhost:8090")!
}
