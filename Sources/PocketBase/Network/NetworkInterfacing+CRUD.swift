//
//  NetworkInterfacing+CRUD.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/6/24.
//

import Foundation
internal import HTTPTypes

extension NetworkInterfacing {
    // MARK: GET
    
    func list<Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields
    ) async throws -> [Response] {
        try await decoder.decode(
            [Response].self,
            from: execute(
                method: .get,
                path: path,
                query: query,
                headers: headers
            )
        )
    }
    
    func get<Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields
    ) async throws -> Response {
        try await decoder.decode(
            Response.self,
            from: execute(
                method: .get,
                path: path,
                query: query,
                headers: headers
            )
        )
    }
    
    // MARK: POST
    
    func post(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields
    ) async throws {
        try await execute(
            method: .post,
            path: path,
            query: query,
            headers: headers
        )
    }
    
    func post<Body: EncodableWithConfiguration>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws where Body.EncodingConfiguration == RecordCollectionEncodingConfiguration {
        try await execute(
            method: .post,
            path: path,
            query: query,
            headers: headers,
            body: self.encoder.encode(body, configuration: .remote)
        )
    }
    
    func post(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: any Encodable & Sendable
    ) async throws {
        try await execute(
            method: .post,
            path: path,
            query: query,
            headers: headers,
            body: self.encoder.encode(body)
        )
    }
    
    func post<Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields
    ) async throws -> Response {
        try await decoder.decode(
            Response.self,
            from: execute(
                method: .post,
                path: path,
                query: query,
                headers: headers
            )
        )
    }
    
    func post<Response: Decodable & Sendable, Body: EncodableWithConfiguration & Sendable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws -> Response where Body.EncodingConfiguration == RecordCollectionEncodingConfiguration {
        let response = try await execute(
            method: .post,
            path: path,
            query: query,
            headers: headers,
            body: encoder.encode(body, configuration: .remote)
        )
        return try decoder.decode(Response.self, from: response)
    }
    
    func post<Response: Decodable & Sendable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Data
    ) async throws -> Response {
        let response = try await execute(
            method: .post,
            path: path,
            query: query,
            headers: headers,
            body: body
        )
        return try decoder.decode(Response.self, from: response)
    }
    
    // MARK: PATCH
    
    func patch(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields
    ) async throws {
        try await execute(
            method: .patch,
            path: path,
            query: query,
            headers: headers
        )
    }
    
    func patch<Body: Encodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws {
        try await execute(
            method: .patch,
            path: path,
            query: query,
            headers: headers,
            body: encoder.encode(body)
        )
    }
    
    func patch<Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields
    ) async throws -> Response {
        try await decoder.decode(
            Response.self,
            from: execute(
                method: .patch,
                path: path,
                query: query,
                headers: headers
            )
        )
    }
    
    func patch<Body: Encodable, Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws -> Response {
        try await decoder.decode(
            Response.self,
            from: execute(
                method: .patch,
                path: path,
                query: query,
                headers: headers,
                body: encoder.encode(body)
            )
        )
    }
    
    func patch<Body: EncodableWithConfiguration, Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws -> Response where Body.EncodingConfiguration == RecordCollectionEncodingConfiguration {
        try await decoder.decode(
            Response.self,
            from: execute(
                method: .patch,
                path: path,
                query: query,
                headers: headers,
                body: encoder.encode(body, configuration: .remote)
            )
        )
    }
    
    // MARK: DELETE
    
    func delete(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields
    ) async throws {
        try await execute(
            method: .delete,
            path: path,
            query: query,
            headers: headers
        )
    }
    
    func delete<Body: Encodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws {
        try await execute(
            method: .delete,
            path: path,
            query: query,
            headers: headers,
            body: encoder.encode(body)
        )
    }
    
    func delete<Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields
    ) async throws -> Response {
        try await decoder.decode(
            Response.self,
            from: execute(
                method: .delete,
                path: path,
                query: query,
                headers: headers
            )
        )
    }
    
    func delete<Body: Encodable, Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws -> Response {
        try await decoder.decode(
            Response.self,
            from: execute(
                method: .delete,
                path: path,
                query: query,
                headers: headers,
                body: encoder.encode(body)
            )
        )
    }
}
