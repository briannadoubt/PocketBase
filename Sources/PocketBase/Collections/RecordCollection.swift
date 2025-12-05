//
//  File.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation
internal import HTTPTypes

public actor RecordCollection<T: Record>: NetworkInterfacing, Sendable {
    var baseURL: URL {
        pocketbase.url
    }

    let pocketbase: PocketBase

    var session: any NetworkSession {
        pocketbase.session
    }

    let collection: String

    let encoder: JSONEncoder = {
        PocketBase.encoder
    }()

    /// Decoder configured with the PocketBase base URL in userInfo.
    ///
    /// This allows RecordFile hydration to include the base URL for direct URL access.
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
        decoder.dateDecodingStrategy = .formatted(formatter)
        decoder.userInfo[RecordFile.baseURLUserInfoKey] = pocketbase.url
        return decoder
    }

    public init(
        _ collection: String,
        _ pocketbase: PocketBase
    ) {
        self.collection = collection
        self.pocketbase = pocketbase
    }

    var headers: HTTPFields {
        var headers: HTTPFields = [:]
        headers[.contentType] = "application/json"
        if let token = pocketbase.authStore.token {
            headers[.authorization] = "Bearer \(token)"
        }
        return headers
    }
}
