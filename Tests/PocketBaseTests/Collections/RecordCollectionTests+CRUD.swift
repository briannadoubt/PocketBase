//
//  RecordCollectionTests+CRUD.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/24/24.
//

import Testing
@testable import PocketBase

extension RecordCollectionTests {
    @Suite("CRUD Tests")
    struct CRUDTests: AuthTestSuite {
        func assert<T: Decodable & Equatable>(
            lastRequest: URLRequest?,
            url: String,
            method: String,
            headers: [String: String] = ["Content-Type": "application/json"],
            body: T? = nil as Never?
        ) throws {
            guard let lastRequest else {
                #expect(lastRequest != nil)
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
        
        @Test("Create Auth Record")
        func createAuthRecord() async throws {
            let response = try PocketBase.encoder.encode(Self.tester, configuration: .cache)
            let baseURL = Self.baseURL
            let environment = testEnvironment(baseURL: baseURL, response: response)
            let collection = environment.pocketbase.collection(Tester.self)
            
            let tester = try await collection.create(
                Self.tester,
                password: Self.password,
                passwordConfirm: Self.password
            )
            #expect(tester.id == Self.tester.id)
            #expect(tester.username == Self.tester.username)
            
            try assert(
                lastRequest: environment.session.lastRequest,
                url: baseURL.absoluteString + "/api/collections/testers/records?expand=rawrs",
                method: "POST",
                body: ExpectedCreateTesterBody()
            )
        }
        
        struct ExpectedCreateTesterBody: Decodable, Equatable {
            var email: String?
            var rawrs: [String] = []
            var passwordConfirm: String = "Test1234"
            var emailVisibility: Bool = false
            var verified: Bool = false
            var username: String = "meowface"
            var password: String = "Test1234"
        }
    }
}
