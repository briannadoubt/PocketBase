//
//  NetworkInterfacing.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/2/24.
//

import Foundation
internal import HTTPTypes

public protocol NetworkInterfacing: Actor, HasLogger {
    var baseURL: URL { get }
    var session: any NetworkSession { get }
    var decoder: JSONDecoder { get }
    var encoder: JSONEncoder { get }
}

extension NetworkInterfacing {
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
        case 400:
            do {
                let errorResponse = try decoder.decode(PocketBaseErrorResponse.self, from: data)
                throw NetworkError.invalidFilter(errorResponse)
            } catch {
                throw NetworkError.invalidResponse(
                    reason: .failedToParseInvalidFilterErrorResponse,
                    statusCode: response.statusCode,
                    data: data,
                    response: response
                )
            }
        case 403:
            do {
                let errorResponse = try decoder.decode(PocketBaseErrorResponse.self, from: data)
                throw NetworkError.unauthorized(errorResponse)
            } catch {
                throw NetworkError.invalidResponse(
                    reason: .failedToParseUnauthorizedErrorResponse,
                    statusCode: response.statusCode,
                    data: data,
                    response: response
                )
            }
        case 404:
            do {
                let errorResponse = try decoder.decode(PocketBaseErrorResponse.self, from: data)
                throw NetworkError.notFound(errorResponse)
            } catch {
                throw NetworkError.invalidResponse(
                    reason: .failedToParseNotFoundErrorResponse,
                    statusCode: response.statusCode,
                    data: data,
                    response: response
                )
            }
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
        Self.logger.log("Requesting: \(request.prettyCURL)")
    }
    
    private func debugResponse(_ data: Data) {
        if let debugResponse = String(data: data, encoding: .utf8) {
            Self.logger.log("Response: \(debugResponse)")
        } else {
            Self.logger.log("Response: cannot parse")
        }
    }
}

extension URLRequest {
    public var cURL: String {
        cURL()
    }
    
    public var prettyCURL: String {
        cURL(pretty: true)
    }
    
    private func cURL(pretty: Bool = false) -> String {
        let newLine: String
        if pretty {
            newLine = "\\\n"
        } else {
            newLine = ""
        }
        var method: String
        if pretty {
            method = "--request "
        } else {
            method = "-X "
        }
        method = method + "\(self.httpMethod ?? "GET") \(newLine)"
        let urlArgument = pretty ? "--url " : ""
        let url: String = urlArgument + "\'\(self.url?.absoluteString ?? "")\' \(newLine)"
        
        var cURL = "curl "
        var header = ""
        var data: String = ""
        
        if let httpHeaders = self.allHTTPHeaderFields, httpHeaders.keys.count > 0 {
            for (key,value) in httpHeaders {
                var headerFlag: String
                if pretty {
                    headerFlag = "--header "
                } else {
                    headerFlag = "-H "
                }
                header += headerFlag + "\'\(key): \(value)\' \(newLine)"
            }
        }
        
        if
            let bodyData = httpBody,
            let bodyString = String(
                data: bodyData,
                encoding: .utf8
            ),
            !bodyString.isEmpty
        {
            data = "--data '\(bodyString)'"
        }
        
        cURL += method + url + header + data
        
        return cURL
    }
}
