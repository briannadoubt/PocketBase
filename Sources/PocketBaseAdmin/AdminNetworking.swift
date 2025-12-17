//
//  AdminNetworking.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Shared networking functionality for admin API operations.
///
/// Provides common HTTP methods and authentication handling
/// for all admin subsystems.
public protocol AdminNetworking: Sendable, HasLogger {
    var pocketbase: PocketBase { get }
}

extension AdminNetworking {
    var encoder: JSONEncoder { PocketBase.encoder }
    var decoder: JSONDecoder { PocketBase.decoder }

    var headers: [String: String] {
        var headers: [String: String] = [
            "Content-Type": "application/json"
        ]
        if let token = pocketbase.authStore.token {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }

    func execute(
        method: String,
        path: String,
        query: [URLQueryItem] = [],
        headers customHeaders: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> Data {
        let url: URL = {
            let baseURL = pocketbase.url.appending(path: path)
            if query.isEmpty {
                return baseURL
            }
            return baseURL.appending(queryItems: query)
        }()

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Use custom headers if provided, otherwise use default headers
        let headersToUse = customHeaders ?? headers
        for (key, value) in headersToUse {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = body

        Self.logger.log("Requesting: \(request.cURL)")
        Self.logger.log("Body size: \(body?.count ?? 0) bytes")
        if let body {
            // Show first 500 bytes as string if possible
            if let preview = String(data: body.prefix(500), encoding: .utf8) {
                Self.logger.log("Body preview:\n\(preview)")
            } else {
                // Show as hex if not valid UTF-8
                let hexPreview = body.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " ")
                Self.logger.log("Body hex (first 100 bytes): \(hexPreview)")
            }
        }

        // Use the same approach as working RecordCollection code
        let (data, response) = try await URLSession.shared.data(for: request)

        if let responseString = String(data: data, encoding: .utf8) {
            Self.logger.log("Response: \(responseString)")
        } else {
            Self.logger.log("Response: cannot parse")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknownResponse(response)
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        default:
            throw NetworkError.invalidResponse(
                reason: .unexpectedStatusCode(httpResponse.statusCode),
                statusCode: httpResponse.statusCode,
                data: data,
                response: httpResponse
            )
        }
    }

    func get<Response: Decodable>(
        path: String,
        query: [URLQueryItem] = []
    ) async throws -> Response {
        let data = try await execute(method: "GET", path: path, query: query)
        return try decoder.decode(Response.self, from: data)
    }

    func post<Response: Decodable>(
        path: String,
        body: Data? = nil
    ) async throws -> Response {
        let data = try await execute(method: "POST", path: path, body: body)
        return try decoder.decode(Response.self, from: data)
    }

    func patch<Response: Decodable>(
        path: String,
        body: Data? = nil
    ) async throws -> Response {
        let data = try await execute(method: "PATCH", path: path, body: body)
        return try decoder.decode(Response.self, from: data)
    }

    func delete(path: String) async throws {
        _ = try await execute(method: "DELETE", path: path)
    }
}
