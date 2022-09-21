//
//  PocketBase.swift
//  PocketBase
//
//  Created by Bri on 9/15/22.
//

import Foundation
import KeychainAccess
import Alamofire

/// A client for PocketBase.
public actor PocketBase {
    
    /// Optional language code (default to `en-US`) that will be sent with the requests to the server as `Accept-Language` header.
    public var language: String?
    
    /// The base PocketBase backend url address (eg. 'http://127.0.0.1.8090').
    public let baseUrl: URL
    
    /// An instance of the service that handles the **Admin APIs**.
//    public let admins: Admins TODO: Implement Admins
    
    /// An instance of the service that handles the **User APIs**.
    public let users: Users
    
    /// An instance of the service that handles the **Realtime APIs**.
    public let realtime: Realtime
    
    /// An instance of the service that handles the **Collection APIs**.
//    public let collections: Collections TODO: Implement Collections
    
    /// An instance of the service that handles the **Record APIs**.
    public let records: Records
    
    /// An instance of the service that handles uploading and dowloading files.
//    public let files: Files
    
    /// An instance of the service that handles the **Log APIs**.
//    public let logs: Logs TODO: Implement Logs
    
    /// An instance of the service that handles the **Settings APIs**.
//    public let settings: Settings TODO: Implement Settings
    
    /// Create a new PocketBase client instance.
    /// - Parameters:
    ///   - baseUrl: The base PocketBase backend url address (eg. 'http://127.0.0.1.8090').
    ///   - language: Optional language code (default to `en-US`) that will be sent with the requests to the server as `Accept-Language` header.
    ///   - interceptor: The request's optional interceptor, defaults to `UserBearerTokenPolicy().interceptor`. Use the interceptor to apply retry policies or attach headers as necessary.
    public init(
        baseUrl: URL,
        language: String? = Locale.current.languageCode,
        interceptor: Interceptor = UserBearerTokenPolicy().interceptor
    ) {
        self.baseUrl = baseUrl
        self.language = language
        self.users = Users(interceptor: interceptor)
        self.records = Records()
        self.realtime = Realtime(interceptor: interceptor)
    }
}

public protocol BaseModel: Codable {
    var id: UUID? { get set }
    var created: Date { get set }
    var updated: Date { get set }
}

extension BaseModel {
    public var isNew: Bool { id == nil }
    public func export() -> Any {
        return self
    }
}

public protocol Model: BaseModel {
    var collectionId: String { get set }
    var collectionName: String { get set }
    var expand: String { get set }
}

public struct ListResult<AnyModel: BaseModel>: Decodable {
    public let page: Int
    public let perPage: Int
    public let totalItems: Int
    public let totalPages: Int?
    public let items: [AnyModel]
}

public actor Records {
    
}
