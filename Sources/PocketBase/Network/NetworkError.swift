//
//  NetworkError.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public enum NetworkError: LocalizedError {
    case invalidRequest(reason: InvalidRequestReason)
    case unknownResponse(URLResponse)
    case invalidResponse(reason: InvalidResponseReason, statusCode: Int, data: Data, response: HTTPURLResponse)
    case invalidFilter(PocketBaseErrorResponse)
    case unauthorized(PocketBaseErrorResponse)
    case notFound(PocketBaseErrorResponse)
    
    public enum InvalidResponseReason: LocalizedError {
        case failedToParseInvalidFilterErrorResponse
        case failedToParseUnauthorizedErrorResponse
        case failedToParseNotFoundErrorResponse
        case unexpectedStatusCode(Int)
    }
    
    public enum InvalidRequestReason: LocalizedError {
        case missingURL
        case missingMethod
        case getRequestWithBody
        case missingParameters
        case missingHeaders
        case invalidJSONBody
        case invalidURLRequest
    }
}