//
//  NetworkInterfacing.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/2/24.
//

import Foundation
package import HTTPTypes

package protocol NetworkInterfacing: Actor, HasLogger {
    var baseURL: URL { get }
    var session: any NetworkSession { get }
    var decoder: JSONDecoder { get }
    var encoder: JSONEncoder { get }
}

package extension NetworkInterfacing {
    // MARK: Execution
    
    @discardableResult
    func execute(
        method: HTTPRequest.Method,
        path: String,
        query: [URLQueryItem] = [],
        headers: HTTPFields,
        body: Data? = nil
    ) async throws -> Data {
        let (data, response) = try await session.data(
            for: {
                var request = URLRequest(
                    url: {
                        let url = baseURL.appending(path: path)
                        if query.isEmpty {
                            return url
                        }
                        return url.appending(queryItems: query)
                    }()
                )
                request.httpMethod = method.rawValue
                for header in headers {
                    request.setValue(header.value, forHTTPHeaderField: header.name.rawName)
                }
                request.httpBody = body
                debugRequest(request: request)
                return request
            }()
        )
        debugResponse(data)
        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.unknownResponse(response)
        }
        switch response.statusCode {
        case 200..<300:
            return data
        default:
            throw NetworkError.invalidResponse(
                reason: .unexpectedStatusCode(response.statusCode),
                statusCode: response.statusCode,
                data: data,
                response: response
            )
        }
    }
    
    private func debugRequest(request: URLRequest) {
        Self.logger.log("Requesting: \(request.cURL)")
    }
    
    private func debugResponse(_ data: Data) {
        if let debugResponse = String(data: data, encoding: .utf8) {
            Self.logger.log("Response: \(debugResponse)")
        } else {
            Self.logger.log("Response: cannot parse")
        }
    }
}
