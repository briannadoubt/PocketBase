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
    struct CRUDTests: NetworkResponseTestSuite {
        @Test("Create Record")
        func createRecord() async throws {
            let expectedRawr = Self.rawr
            let response = try PocketBase.encoder.encode(expectedRawr, configuration: .none)
            let baseURL = Self.baseURL
            let environment = testEnvironment(baseURL: baseURL, response: response)
            let collection = environment.pocketbase.collection(Rawr.self)
            
            let rawr = try await collection.create(Rawr(field: Self.field))
            #expect(rawr.id == expectedRawr.id)
            #expect(rawr.field == Self.field)
            
            try environment.assertNetworkRequest(
                url: baseURL.absoluteString + "/api/collections/rawrs/records",
                method: "POST",
                body: ["field": Self.field]
            )
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
            
            try environment.assertNetworkRequest(
                url: baseURL.absoluteString + "/api/collections/testers/records?expand=rawrs",
                method: "POST",
                body: ExpectedCreateAuthRecordBody()
            )
        }
        
        struct ExpectedCreateAuthRecordBody: Decodable, Equatable {
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
