//
//  NetworkInterfacing+CRUD.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/6/24.
//

import Foundation
package import HTTPTypes

package extension NetworkInterfacing {
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
        do {
            return try await decoder.decode(
                Response.self,
                from: execute(
                    method: .post,
                    path: path,
                    query: query,
                    headers: headers
                )
            )
        } catch {
            throw error
        }
    }
    
    func post<Response: Decodable & Sendable, Body: EncodableWithConfiguration & Sendable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws -> Response where Body.EncodingConfiguration == PocketBase.EncodingConfiguration {
        try await decoder.decode(
            Response.self,
            from: execute(
                method: .post,
                path: path,
                query: query,
                headers: headers,
                body: encoder.encode(body, configuration: .remoteBody)
            )
        )
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
    
    func post<Body: Encodable, Response: Decodable & Sendable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws -> Response {
        let response = try await execute(
            method: .post,
            path: path,
            query: query,
            headers: headers,
            body: self.encoder.encode(body)
        )
        return try decoder.decode(Response.self, from: response)
    }
    
    // MARK: PATCH
    
    func patch<Body: EncodableWithConfiguration, Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Body
    ) async throws -> Response where Body.EncodingConfiguration == PocketBase.EncodingConfiguration {
        try await decoder.decode(
            Response.self,
            from: execute(
                method: .patch,
                path: path,
                query: query,
                headers: headers,
                body: encoder.encode(body, configuration: .remoteBody)
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
}
