//
//  AuthResponse.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public struct AuthResponse<T: AuthRecord>: Decodable, EncodableWithConfiguration, Sendable, Hashable where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
    public func encode(to encoder: any Encoder, configuration: RecordCollectionEncodingConfiguration) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(record, forKey: .record, configuration: configuration)
        try container.encodeIfPresent(meta, forKey: .meta)
    }
    
    public typealias EncodingConfiguration = RecordCollectionEncodingConfiguration
    
    var token: String
    var record: T
    var meta: MetaOAuth2Response?
}
