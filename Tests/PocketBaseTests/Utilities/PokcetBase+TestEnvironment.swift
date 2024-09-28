//
//  PokcetBase+TestEnvironment.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/27/24.
//

import Testing
@testable import PocketBase

func testEnvironment(
    baseURL: URL,
    response: Data = Data(),
    suiteName: String = #function,
    service: String = #function
) -> PocketBase.TestEnvironment {
    let defaults = UserDefaultsSpy(suiteName: suiteName)
    let session = MockNetworkSession(data: response)
    let keychain = MockKeychain(service: service)
    let pocketbase = PocketBase(
        url: baseURL,
        defaults: defaults,
        session: session,
        authStore: AuthStore(
            keychain: keychain,
            defaults: defaults
        )
    )
    return PocketBase.TestEnvironment(
        defaults: defaults,
        session: session,
        keychain: keychain,
        pocketbase: pocketbase
    )
}

extension PocketBase {
    struct TestEnvironment {
        var defaults: UserDefaultsSpy?
        var session: MockNetworkSession
        var keychain: MockKeychain
        var pocketbase: PocketBase
        
        func assertNetworkRequest<T: Decodable & Equatable>(
            url: String,
            method: String,
            headers: [String: String] = ["Content-Type": "application/json"],
            body: T? = nil as Never?
        ) throws {
            guard let lastRequest = session.lastRequest else {
                #expect(session.lastRequest != nil)
                return
            }
            guard let absoluteString = lastRequest.url?.absoluteString else {
                #expect(lastRequest.url?.absoluteString != nil)
                return
            }
            #expect(absoluteString == url)
            if let body {
                guard let requestBody = lastRequest.httpBody else {
                    #expect(lastRequest.httpBody != nil)
                    return
                }
                let decodedBody = try PocketBase.decoder.decode(T.self, from: requestBody)
                #expect(decodedBody == body)
                #expect(lastRequest.httpMethod == method)
                #expect(lastRequest.allHTTPHeaderFields == headers)
            } else {
                #expect(lastRequest.httpBody == nil)
            }
        }
    }
}
