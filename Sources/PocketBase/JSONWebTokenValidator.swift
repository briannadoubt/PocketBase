//
//  JSONWebTokenValidator.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Foundation

/// Validated a JSON Web Token
protocol JSONWebTokenValidator { }

/// Errors thrown during JSON Web Token validation.
enum JWTDecodingError: Error {
    case badToken
    case other
}

extension JSONWebTokenValidator {
    
    /// Checks if the store has valid (aka. existing and unexpired) token.
    public func isValid(token: String?) throws -> Bool {
        if let token {
            return try !isJWTExpired(token)
        }
        return false
    }
    
    /// Checks whether a JWT is expired or not. Tokens without `exp` payload key are considered valid. Tokens with empty payload (eg. invalid token strings) are considered expired.
    /// - Parameters:
    ///  - jwt: The token to check.
    ///  - expirationThreshold: Time in seconds that will be subtracted from the token `exp` property.
    private func isJWTExpired(_ jwt: String, expirationThreshold: TimeInterval = 0) throws -> Bool {
        let payload = try parse(jwt: jwt)
        if
            !payload.isEmpty,
            let exp = payload["exp"] as? Date,
            (exp.timeIntervalSince1970 - expirationThreshold) > Date().timeIntervalSince1970
        {
            return false
        }
        return true
    }
    
    /// Parse the JSON Web Token payload into its' separate parts.
    /// - Parameter jwt: The JSON Web Token string.
    /// - Returns: A dictionary containing the JSON Web Token parts.
    private func parse(jwt: String) throws -> [String: Any] {
        /// Convert a base64 encoded `String` into an instance of base64 encoded `Data`.
        /// - Parameter base64: The base64 encoded `String`.
        /// - Throws: Throws a `JWTDecodingError.badToken` if decoding the input base64 `String` fails.
        /// - Returns: An instance of base64 encoded `Data`.
        func base64Decode(_ base64: String) throws -> Data {
            let base64 = base64
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            guard let decoded = Data(base64Encoded: padded) else {
                throw JWTDecodingError.badToken
            }
            return decoded
        }
        /// Decode a given part of a JSON Web Token.
        /// - Parameter part: The part of the JSON Web Token to be decoded.
        /// - Throws: Throws a `JWTDecodingError.other` if decoding the input base64 `String` fails.
        /// - Returns: The decoded part of the JSON Web Token.
        func decodePart(_ part: String) throws -> [String: Any] {
            let bodyData = try base64Decode(part)
            let json = try JSONSerialization.jsonObject(with: bodyData, options: [])
            guard let payload = json as? [String: Any] else {
                throw JWTDecodingError.other
            }
            return payload
        }
        // Separate input JSON Web Token to its' parts
        let jwtParts = jwt.components(separatedBy: ".")
        // Extract the payload part
        let payload = jwtParts[1]
        // Decode the payload and return it.
        return try decodePart(payload)
    }
}
