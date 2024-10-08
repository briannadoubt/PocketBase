//
//  RecordCollection+AuthWithOAuth2.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

// TODO: Implement OAuth2

//import Foundation
//
//public extension RecordCollection where T: AuthRecord {
//    @Sendable
//    func authWithOAuth2<CreateData: EncodableWithConfiguration>(
//        provider: String,
//        code: String,
//        codeVerifier: String,
//        redirectUrl: URL,
//        createData: CreateData
//    ) async throws -> AuthResponse<T> {
//        let response: AuthResponse<T> = try await post(
//            path: PocketBase.collectionPath(collection) + "auth-with-oauth2/",
//            query: {
//                var query: [URLQueryItem] = []
//                if !T.relations.isEmpty {
//                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
//                }
//                return query
//            }(),
//            headers: headers,
//            body: JSONSerialization.data(
//                withJSONObject: [
//                    "provider": provider,
//                    "code": code,
//                    "codeVerifier": codeVerifier,
//                    "redirectUrl": redirectUrl,
//                    "createData": createData
//                ]
//            )
//        )
//        try pocketbase.authStore.set(response)
//        return response
//    }
//}
