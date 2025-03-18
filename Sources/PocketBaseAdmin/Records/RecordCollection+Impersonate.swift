//
//  RecordCollection+Impersonate.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/17/25.
//

import PocketBase

extension RecordCollection where T: AuthRecord {
    public func impersonate(
        _ authRecordID: String,
        duration: Int = 0
    ) async throws -> AuthResponse<T> {
        let response: AuthResponse<T> = try await post(
            path: PocketBase.collectionPath(collection) + "impersonate/" + authRecordID,
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            headers: headers,
            body: ImpersonateBody(duration: duration)
        )
        try pocketbase.authStore.set(response)
        return response
    }
}

struct ImpersonateBody: EncodableWithConfiguration, Decodable, Equatable, Sendable {
    func encode(to encoder: any Encoder, configuration: PocketBase.EncodingConfiguration) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
    }
    
    enum CodingKeys: String, CodingKey {
        case duration
    }
    
    typealias EncodingConfiguration = PocketBase.EncodingConfiguration
    
    var duration: Int
}
