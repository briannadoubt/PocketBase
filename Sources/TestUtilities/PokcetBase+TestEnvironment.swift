//
//  PokcetBase+TestEnvironment.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/27/24.
//

import Testing
@testable import PocketBase
import HTTPTypes

extension PocketBase {
    public struct TestEnvironment {
        public var defaults: UserDefaultsSpy?
        public var session: MockNetworkSession
        public var keychain: MockKeychain
        public var pocketbase: PocketBase
        
        public init(
            baseURL: URL,
            response: Data = Data(),
            suiteName: String = UUID().uuidString,
            service: String = UUID().uuidString
        ) {
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
            self.init(
                defaults: defaults,
                session: session,
                keychain: keychain,
                pocketbase: pocketbase
            )
        }
        
        public init(
            defaults: UserDefaultsSpy?,
            session: MockNetworkSession,
            keychain: MockKeychain,
            pocketbase: PocketBase
        ) {
            self.defaults = defaults
            self.session = session
            self.keychain = keychain
            self.pocketbase = pocketbase
        }
        
        public func assertNetworkRequest<T: Decodable & Equatable>(
            url: String,
            method: HTTPRequest.Method,
            headers: [String: String] = ["Content-Type": "application/json"],
            body: T? = nil as Never?,
            sourceLocation: Testing.SourceLocation = #_sourceLocation
        ) throws {
            guard let lastRequest = session.lastRequest else {
                #expect(session.lastRequest != nil, sourceLocation: sourceLocation)
                return
            }
            guard let absoluteString = lastRequest.url?.absoluteString else {
                #expect(lastRequest.url?.absoluteString != nil, sourceLocation: sourceLocation)
                return
            }
            #expect(absoluteString == url, sourceLocation: sourceLocation)
            if let body {
                guard let requestBody = lastRequest.httpBody else {
                    #expect(lastRequest.httpBody != nil, sourceLocation: sourceLocation)
                    return
                }
                let decodedBody = try PocketBase.decoder.decode(T.self, from: requestBody)
                #expect(decodedBody == body, sourceLocation: sourceLocation)
                #expect(lastRequest.httpMethod == method.rawValue, sourceLocation: sourceLocation)
                #expect(lastRequest.allHTTPHeaderFields == headers, sourceLocation: sourceLocation)
            } else {
                #expect(lastRequest.httpBody == nil, sourceLocation: sourceLocation)
            }
        }
    }
}
