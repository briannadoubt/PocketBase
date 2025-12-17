//
//  NetworkError.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public enum NetworkError: LocalizedError, Equatable {
    case invalidRequest(reason: InvalidRequestReason)
    case unknownResponse(URLResponse)
    case invalidResponse(reason: InvalidResponseReason, statusCode: Int, data: Data, response: HTTPURLResponse)
    case invalidFilter(PocketBaseErrorResponse)
    case unauthorized(PocketBaseErrorResponse)
    case notFound(PocketBaseErrorResponse)

    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let reason):
            return "Invalid request: \(reason.errorDescription ?? reason.localizedDescription)"
        case .unknownResponse:
            return "Unknown response from server"
        case .invalidResponse(let reason, let statusCode, let data, _):
            // Try to parse the error message from the response data
            if let errorResponse = try? JSONDecoder().decode(PocketBaseErrorResponse.self, from: data) {
                return "Server error (\(statusCode)): \(errorResponse.formattedErrors)"
            }
            // Try to get raw string from data
            if let rawString = String(data: data, encoding: .utf8), !rawString.isEmpty {
                return "Server error (\(statusCode)): \(rawString)"
            }
            return "Server error (\(statusCode)): \(reason.errorDescription ?? reason.localizedDescription)"
        case .invalidFilter(let response):
            return "Invalid filter: \(response.message)"
        case .unauthorized(let response):
            return "Unauthorized: \(response.message)"
        case .notFound(let response):
            return "Not found: \(response.message)"
        }
    }

    public enum InvalidResponseReason: LocalizedError, Equatable {
        case failedToParseInvalidFilterErrorResponse
        case failedToParseUnauthorizedErrorResponse
        case failedToParseNotFoundErrorResponse
        case unexpectedStatusCode(Int)

        public var errorDescription: String? {
            switch self {
            case .failedToParseInvalidFilterErrorResponse:
                return "Failed to parse invalid filter error"
            case .failedToParseUnauthorizedErrorResponse:
                return "Failed to parse unauthorized error"
            case .failedToParseNotFoundErrorResponse:
                return "Failed to parse not found error"
            case .unexpectedStatusCode(let code):
                return "Unexpected status code: \(code)"
            }
        }
    }

    public enum InvalidRequestReason: LocalizedError, Equatable {
        case missingURL
        case missingMethod
        case getRequestWithBody
        case missingParameters
        case missingHeaders
        case invalidJSONBody
        case invalidURLRequest

        public var errorDescription: String? {
            switch self {
            case .missingURL: return "Missing URL"
            case .missingMethod: return "Missing HTTP method"
            case .getRequestWithBody: return "GET request cannot have body"
            case .missingParameters: return "Missing parameters"
            case .missingHeaders: return "Missing headers"
            case .invalidJSONBody: return "Invalid JSON body"
            case .invalidURLRequest: return "Invalid URL request"
            }
        }
    }
}
