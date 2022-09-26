//
//  Records.swift
//  PocketBase
//
//  Created by Bri on 9/21/22.
//

import Alamofire
import AlamofireEventSource
import Foundation

public protocol Service: Actor {
    var baseUrl: URL { get }
    var interceptor: Interceptor? { get }
    init(baseUrl: URL)
}

public extension Service {
    /// Used to make HTTP requests.
    var http: HTTP { HTTP() }
    
    var interceptor: Interceptor? {
        UserBearerTokenPolicy().interceptor
    }
}

/// An object used to interact with the PocketBase **Records API**.
public actor Records: Service {
    
    /// The baseURL for all requests to PocketBase.
    public let baseUrl: URL
    
    /// An object used to interact with the PocketBase **Records API**.
    /// - Parameters:
    ///  - baseUrl: The baseURL for all requests to PocketBase.
    ///  - interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    public init(baseUrl: URL) {
        self.baseUrl = baseUrl
    }
    
    /// Returns a paginated collection Records list.
    ///
    /// Depending on the collection's listRule value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - collection: The collection name or id.
    ///   - page: The page of records.
    ///   - perPage: The number of pages returned per page.
    ///   - sort: Specify the ORDER BY fields.
    ///   - filter: Filter expression to filter/search the returned records list.
    ///   - expand: Auto expand nested record relations.
    /// - Returns: A list of decoded data.
    public func list<T: Decodable>(
        _ collection: String,
        page: Int = 1,
        perPage: Int = 30,
        sort: String? = nil,
        filter: String? = nil,
        expand: String? = nil
    ) async throws -> ListResult<T> {
        print("PocketBase: Requesting list of", "\"\(T.self)\"", "at", baseUrl.absoluteString + ":", "collection:", String(describing: collection) + ",", "page:", "\(page),", "perPage:", "\(perPage),", "sort:", "\(sort ?? "(No Sort)"),", "filter:", "\(filter ?? "(No Filter)"),", "expand:", "\(expand ?? "(No Expand)"),")
        return try await http.request(
            Request.list(
                baseUrl: baseUrl,
                collection: collection,
                page: page,
                perPage: perPage,
                sort: sort,
                filter: filter,
                expand: expand
            ),
            interceptor: interceptor
        )
    }
    
    /// Returns a single collection Record by its ID.
    ///
    /// Depending on the collection's viewRule value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - recordId: ID of the record to view.
    ///   - collection: ID or name of the record's collection.
    ///   - expand: Auto expand nested record relations.
    /// - Returns: A decoded object representing the requested record.
    public func view<T: Decodable>(_ recordId: String, collection: String, expand: String) async throws -> T {
        try await http.request(Request.view(baseUrl: baseUrl, recordId: recordId, collection: collection, expand: expand), interceptor: interceptor)
    }
    
    /// Creates a new collection Record.
    ///
    /// Depending on the collection's createRule value, the access to this action may or may not have been restricted.
    ///
    /// The object will be encoded into a dictionary and uploaded to PocketBase. Then, PocketBase will return an object that contains various types of metadata (such as the `collectionId`, `collectionName`, etc) that is serialized into the new object.
    /// - Parameters:
    ///   - record: The `Codable` object that will be created.
    ///   - collection: ID or name of the record's collection.
    ///   - expand: Auto expand relations when returning the created record.
    /// - Returns: A remotely represented object that was successfully saved to PocketBase.
    public func create<T: Codable>(_ record: T, collection: String, expand: String) async throws -> T {
        try await http.request(Request.create(baseUrl: baseUrl, record: record, collection: collection, expand: expand),
            interceptor: interceptor)
    }
    
    /// Updates an existing collection Record.
    ///
    /// Depending on the collection's updateRule value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - record: The `Codable` object that will be updated.
    ///   - collection: ID or name of the record's collection.
    ///   - recordId: ID of the record to update.
    /// - Returns: The updated object.
    public func update<T: Codable>(_ record: T, collection: String, recordId: String, expand: String) async throws -> T {
        try await http.request(
            Request.update(baseUrl: baseUrl, record: record, collection: collection, recordId: recordId, expand: expand),
            interceptor: interceptor
        )
    }
    
    /// Deletes a single collection Record by its ID.
    ///
    /// Depending on the collection's deleteRule value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///  - recordId: ID of the record to update.
    ///  - collection: ID of the record to update.
    public func delete(recordId: String, collection: String) async throws {
        try await http.request(Request.delete(baseUrl: baseUrl, recordId: recordId, collection: collection), interceptor: interceptor)
    }
    
    
    /// Network Request Composition
    private enum Request: URLRequestConvertible {
        
        /// Returns a paginated collection Records list.
        ///
        /// Depending on the collection's listRule value, the access to this action may or may not have been restricted.
        /// - Parameters:
        ///  - baseUrl: The baseUrl upon which the request URL will be built.
        ///  - collection: The collection name or id.
        ///  - page: The page of records.
        ///  - perPage: The number of pages returned per page.
        ///  - sort: Specify the ORDER BY fields.
        ///  - filter: Filter expression to filter/search the returned records list.
        ///  - expand: Auto expand nested record relations.
        case list(baseUrl: URL, collection: String, page: Int, perPage: Int, sort: String?, filter: String?, expand: String?)
        
        /// Returns a single collection Record by its ID.
        ///
        /// Depending on the collection's viewRule value, the access to this action may or may not have been restricted.
        /// - Parameters:
        ///  - baseUrl: The baseUrl upon which the request URL will be built.
        ///  - recordId: ID of the record to view.
        ///  - collection: ID or name of the record's collection.
        ///  - expand: Auto expand nested record relations.
        case view(baseUrl: URL, recordId: String, collection: String, expand: String)
        
        /// Creates a new collection Record.
        ///
        /// Depending on the collection's createRule value, the access to this action may or may not have been restricted.
        ///
        /// The object will be encoded into a dictionary and uploaded to PocketBase. Then, PocketBase will return an object that contains various types of metadata (such as the `collectionId`, `collectionName`, etc) that is serialized into the new object.
        /// - Parameters:
        ///  - baseUrl: The baseUrl upon which the request URL will be built.
        ///  - record: The `Codable` object that will be processed.
        ///  - collection: ID or name of the record's collection.
        ///  - expand: Auto expand relations when returning the created record.
        case create(baseUrl: URL, record: Encodable, collection: String, expand: String)
        
        /// Updates an existing collection Record.
        ///
        /// Depending on the collection's updateRule value, the access to this action may or may not have been restricted.
        /// - Parameters:
        ///  - baseUrl: The baseUrl upon which the request URL will be built.
        ///  - record: The `Codable` object that will be updated.
        ///  - collection: ID or name of the record's collection.
        ///  - recordId: ID of the record to update.\
        ///  - expand: Auto expand relations when returning the created record.
        case update(baseUrl: URL, record: Encodable, collection: String, recordId: String, expand: String)
        
        /// Deletes a single collection Record by its ID.
        ///
        /// Depending on the collection's deleteRule value, the access to this action may or may not have been restricted.
        /// - Parameters:
        ///  - recordId: ID of the record to update.
        ///  - collection: ID of the record to update.
        case delete(baseUrl: URL, recordId: String, collection: String)
        
        /// The url representing a collection on PocketBase.
        /// - Parameters:
        ///  - baseUrl: The baseUrl upon which the request URL will be built.
        ///  - collection: The name or ID of a collection.
        /// - Returns:A url representing a collection on PocketBase.
        private func collectionUrl(baseUrl: URL, collection: String) -> URL {
            if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *) {
                return baseUrl
                    .appending(path: "api")
                    .appending(path: "collections")
                    .appending(path: collection)
                    .appending(path: "records")
            } else {
                return baseUrl
                    .appendingPathComponent("api")
                    .appendingPathComponent("collections")
                    .appendingPathComponent(collection)
                    .appendingPathComponent("records")
            }
        }
        
        /// The url representing a record on PocketBase.
        /// - Parameters:
        ///   - baseUrl: The baseUrl upon which the request URL will be built.
        ///   - collection: The name or ID of a collection.
        ///   - recordId: The ID of the record to be deleted.
        /// - Returns: A url representing a record on PocketBase.
        private func recordUrl(baseUrl: URL, collection: String, recordId: String) -> URL {
            let collectionUrl = collectionUrl(baseUrl: baseUrl, collection: collection)
            if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *) {
                return collectionUrl.appending(path: recordId)
            } else {
                return collectionUrl.appendingPathComponent(recordId)
            }
        }
        
        /// The generated URL for a given request.
        var url: URL {
            switch self {
            case .list(let baseUrl, let collection, let page, let perPage, let sort, let filter, let expand):
                var components = URLComponents()
                var queryItems: [URLQueryItem] = []
                queryItems.append(contentsOf: [
                    URLQueryItem(name: "page", value: "\(page)"),
                    URLQueryItem(name: "perPage", value: "\(perPage)")
                ])
                if let sort {
                    queryItems.append(URLQueryItem(name: "sort", value: sort))
                }
                if let filter {
                    queryItems.append(URLQueryItem(name: "filter", value: filter))
                }
                if let expand {
                    queryItems.append(URLQueryItem(name: "expand", value: expand))
                }
                components.queryItems = queryItems
                guard let url = components.url(relativeTo: collectionUrl(baseUrl: baseUrl, collection: collection)) else {
                    fatalError()
                }
                return url
                
            case .view(let baseUrl, let recordId, let collection, let expand):
                var components = URLComponents()
                components.queryItems = [URLQueryItem(name: "expand", value: expand)]
                let url = recordUrl(baseUrl: baseUrl, collection: collection, recordId: recordId)
                return components.url(relativeTo: url)!
                
            case .create(let baseUrl, _, let collection, let expand):
                var components = URLComponents()
                components.queryItems = [URLQueryItem(name: "expand", value: expand)]
                return components.url(relativeTo: collectionUrl(baseUrl: baseUrl, collection: collection))!
                
            case .update(let baseUrl, _, let collection, let recordId, let expand):
                var components = URLComponents()
                components.queryItems = [URLQueryItem(name: "expand", value: expand)]
                let url = recordUrl(baseUrl: baseUrl, collection: collection, recordId: recordId)
                return components.url(relativeTo: url)!
                
            case .delete(let baseUrl, let recordId, let collection):
                return recordUrl(baseUrl: baseUrl, collection: collection, recordId: recordId)
            }
        }
        
        /// The HTTP Method used for a given request.
        var method: HTTPMethod {
            switch self {
            case .list, .view:
                return .get
            case .create:
                return .post
            case .update:
                return .patch
            case .delete:
                return .delete
            }
        }
        
        /// The HTTP Headers used for a given request.
        var headers: HTTPHeaders {
            var headers = HTTPHeaders()
            headers.add(.defaultAcceptEncoding)
            headers.add(.defaultUserAgent)
            headers.add(.defaultAcceptLanguage)
            headers.add(.contentType("application/json"))
            return headers
        }
        
        /// Convert the current case to a `URLRequest`.
        func asURLRequest() throws -> URLRequest {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            switch self {
            case .list, .view, .delete:
                break
            case .create(_, let record, _, _), .update(_, let record, _, _, _):
                let body = try JSONEncoder().encode(record)
                urlRequest.httpBody = body
            }
            return urlRequest
        }
    }
}
