//
//  PocketBase.swift
//  PocketBase
//
//  Created by Bri on 9/15/22.
//

import Alamofire
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// A client for PocketBase.
public class PocketBase: ObservableObject {
    
    /// Optional language code (default to `en-US`) that will be sent with the requests to the server as `Accept-Language` header.
    public var language: String?
    
    static var shared = PocketBase(baseUrl)
    
    public static let userDefaults = UserDefaults.standard
    
    private static let defaultBaseUrl = URL(string: "http://0.0.0.0:8090/")!
    static let baseUrlUserDefaultsKey = "io.pocketbase.baseUrl"
    
    /// The base PocketBase backend url address (eg. 'http://0.0.0.0.8090').
    public static var baseUrl: URL {
        get {
            userDefaults.url(forKey: baseUrlUserDefaultsKey) ?? defaultBaseUrl
        }
        set {
            userDefaults.set(newValue, forKey: baseUrlUserDefaultsKey)
        }
    }
    
    /// An instance of the service that handles the **Admin APIs**.
//    public let admins: Admins TODO: Implement Admins
    
    /// An instance of the service that handles the **User APIs**.
    public var users: Users?
    
    /// An instance of the service that handles the **Collection APIs**.
//    public let collections: Collections TODO: Implement Collections
    
    /// An instance of the service that handles the **Record APIs**.
    public var records: Records
    
    public var realtime: Realtime
    
    /// An instance of the service that handles uploading and dowloading files.
//    public let files: Files
    
    /// An instance of the service that handles the **Log APIs**.
//    public let logs: Logs TODO: Implement Logs
    
    /// An instance of the service that handles the **Settings APIs**.
//    public let settings: Settings TODO: Implement Settings
    
    /// Create a new PocketBase client instance.
    public init(_ baseUrl: URL, interceptor: Interceptor = UserBearerTokenPolicy().interceptor) {
        Self.baseUrl = baseUrl
        if #available(iOS 16, macOS 13, watchOS 9, tvOS 16, *) {
            language = Locale.current.language.languageCode?.identifier
        } else {
            language = Locale.current.languageCode
        }
        self.users = Users(baseUrl: baseUrl, interceptor: interceptor)
        self.records = Records(baseUrl: baseUrl, interceptor: interceptor)
        self.realtime = Realtime(baseUrl: baseUrl, interceptor: interceptor)
    }
}

public protocol BaseModel: Codable {
    var id: String? { get set }
    var created: String? { get set }
    var updated: String? { get set }
}

extension BaseModel {
    public var isNew: Bool { id == nil }
    public func export() -> Any {
        return self
    }
}

public protocol Model: BaseModel {
    var collectionId: String? { get set }
    var collectionName: String? { get set }
    var expand: String? { get set }
}

public struct ListResult<T: Codable>: Decodable {
    public let page: Int
    public let perPage: Int
    public let totalItems: Int
    public let totalPages: Int?
    public let items: [T]
}
