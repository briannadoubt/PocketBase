//
//  Records.swift
//  PocketBase
//
//  Created by Bri on 9/21/22.
//

import Alamofire
import Foundation

/// An object used to interact with the PocketBase **Records API**.
public actor Records {
    
    /// Used to make HTTP requests.
    let http = HTTP.shared
    
    /// Used for retry policies and authorization headers.
    let interceptor: Interceptor?
    
    /// An object used to interact with the PocketBase **Records API**.
    /// - Parameter interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    public init(interceptor: Interceptor? = nil) {
        self.interceptor = interceptor
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
    public func list<T: Decodable>(_ collection: String, page: Int = 1, perPage: Int = 30, sort: String? = nil, filter: String? = nil, expand: String? = nil) async throws -> ListResult<T> {
        try await http.request(Request.list(collection: collection, page: page, perPage: perPage, sort: sort, filter: filter, expand: expand), interceptor: interceptor)
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
        try await http.request(Request.view(recordId: recordId, collection: collection, expand: expand), interceptor: interceptor)
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
        try await http.request(
            Request.create(record: record, collection: collection, expand: expand),
            interceptor: interceptor
        )
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
            Request.update(record: record, collection: collection, recordId: recordId, expand: expand),
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
        try await http.request(Request.delete(recordId: recordId, collection: collection), interceptor: interceptor)
    }
    
    
    /// Network Request Composition
    private enum Request: URLRequestConvertible {
        
        /// Returns a paginated collection Records list.
        ///
        /// Depending on the collection's listRule value, the access to this action may or may not have been restricted.
        /// - Parameters:
        ///  - collection: The collection name or id.
        ///  - page: The page of records.
        ///  - perPage: The number of pages returned per page.
        ///  - sort: Specify the ORDER BY fields.
        ///  - filter: Filter expression to filter/search the returned records list.
        ///  - expand: Auto expand nested record relations.
        case list(collection: String, page: Int, perPage: Int, sort: String?, filter: String?, expand: String?)
        
        /// Returns a single collection Record by its ID.
        ///
        /// Depending on the collection's viewRule value, the access to this action may or may not have been restricted.
        /// - Parameters:
        ///   - recordId: ID of the record to view.
        ///   - collection: ID or name of the record's collection.
        ///   - expand: Auto expand nested record relations.
        case view(recordId: String, collection: String, expand: String)
        
        /// Creates a new collection Record.
        ///
        /// Depending on the collection's createRule value, the access to this action may or may not have been restricted.
        ///
        /// The object will be encoded into a dictionary and uploaded to PocketBase. Then, PocketBase will return an object that contains various types of metadata (such as the `collectionId`, `collectionName`, etc) that is serialized into the new object.
        /// - Parameters:
        ///   - record: The `Codable` object that will be processed.
        ///   - collection: ID or name of the record's collection.
        ///   - expand: Auto expand relations when returning the created record.
        case create(record: Encodable, collection: String, expand: String)
        
        /// Updates an existing collection Record.
        ///
        /// Depending on the collection's updateRule value, the access to this action may or may not have been restricted.
        /// - Parameters:
        ///   - record: The `Codable` object that will be updated.
        ///   - collection: ID or name of the record's collection.
        ///   - recordId: ID of the record to update.\
        ///   - expand: Auto expand relations when returning the created record.
        case update(record: Encodable, collection: String, recordId: String, expand: String)
        
        /// Deletes a single collection Record by its ID.
        ///
        /// Depending on the collection's deleteRule value, the access to this action may or may not have been restricted.
        /// - Parameters:
        ///  - recordId: ID of the record to update.
        ///  - collection: ID of the record to update.
        case delete(recordId: String, collection: String)
        
        /// The url representing a collection on PocketBase.
        /// - Parameter collection: The name or ID of a collection.
        /// - Returns:A url representing a collection on PocketBase.
        private func collectionUrl(_ collection: String) -> URL {
            let baseUrl = URL(string: "http://10.0.0.77:8090")!
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
        ///   - recordId: The ID of the record to be deleted.
        ///   - collection: The name or ID of a collection.
        /// - Returns: A url representing a record on PocketBase.
        private func recordUrl(recordId: String, collection: String) -> URL {
            let collectionUrl = collectionUrl(collection)
            if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *) {
                return collectionUrl.appending(path: recordId)
            } else {
                return collectionUrl.appendingPathComponent(recordId)
            }
        }
        
        /// The generated URL for a given request.
        var url: URL {
            switch self {
            case .list(let collection, let page, let perPage, let sort, let filter, let expand):
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
                return components.url(relativeTo: collectionUrl(collection))!
                
            case .view(let recordId, let collection, let expand):
                var components = URLComponents()
                components.queryItems = [URLQueryItem(name: "expand", value: expand)]
                let url = recordUrl(recordId: recordId, collection: collection)
                return components.url(relativeTo: url)!
                
            case .create(_, let collection, let expand):
                var components = URLComponents()
                components.queryItems = [URLQueryItem(name: "expand", value: expand)]
                return components.url(relativeTo: collectionUrl(collection))!
                
            case .update(_, let collection, let recordId, let expand):
                var components = URLComponents()
                components.queryItems = [URLQueryItem(name: "expand", value: expand)]
                let url = recordUrl(recordId: recordId, collection: collection)
                return components.url(relativeTo: url)!
                
            case .delete(let recordId, let collection):
                return recordUrl(recordId: recordId, collection: collection)
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
            return headers
        }
        
        /// Convert the current case to a `URLRequest`.
        func asURLRequest() throws -> URLRequest {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            switch self {
            case .list, .view, .delete:
                break
            case .create(let record, _, _), .update(let record, _, _, _):
                let body = try JSONEncoder().encode(record)
                urlRequest.httpBody = body
            }
            return urlRequest
        }
    }
}
