//
//  RecordCollectionTests+CRUD.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/24/24.
//

import Testing
@testable import PocketBase
import TestUtilities

extension RecordCollectionTests {
    @Suite("CRUD Tests")
    struct CRUDTests: NetworkResponseTestSuite {
        @Test("Create Record")
        func createRecord() async throws {
            let expectedRawr = Self.rawr
            let response = try PocketBase.encoder.encode(expectedRawr, configuration: .none)
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(baseURL: baseURL, response: response)
            let collection = environment.pocketbase.collection(Rawr.self)
            
            let rawr = try await collection.create(Rawr(field: Self.field))
            #expect(rawr.id == expectedRawr.id)
            #expect(rawr.field == Self.field)
            
            try environment.assertNetworkRequest(
                url: baseURL.absoluteString + "/api/collections/rawrs/records?expand=testers_via_rawrs",
                method: .post,
                body: ["field": Self.field]
            )
        }
        
        @Test("Create Auth Record")
        func createAuthRecord() async throws {
            let response = try PocketBase.encoder.encode(Tester(id: Self.id, username: Self.username), configuration: .none)
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(baseURL: baseURL, response: response)
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
                method: .post,
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
        
        @Test("Delete Record")
        func deleteRecord() async throws {
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(baseURL: baseURL)
            let collection = environment.pocketbase.collection(Rawr.self)
            
            try await collection.delete(Self.rawr)
            
            try environment.assertNetworkRequest(
                url: baseURL.absoluteString + "/api/collections/rawrs/records/meow1234",
                method: .delete
            )
        }
        
        @Test("Delete Auth Record")
        func deleteAuthRecord() async throws {
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(baseURL: baseURL)
            let collection = environment.pocketbase.collection(Tester.self)
            
            environment.session.data = try PocketBase.encoder.encode(Self.authResponse, configuration: .none)
            try await collection.login(with: .identity(Self.username, password: Self.password))
            
            try await collection.delete(Self.tester)
            
            try environment.assertNetworkRequest(
                url: baseURL.absoluteString + "/api/collections/testers/records/meow1234",
                method: .delete
            )
        }
        
        @Test("List Records")
        func listRecords() async throws {
            let baseURL = Self.baseURL
            let expectedListResponse = RecordCollection<Rawr>.ListResponse(
                page: 0,
                perPage: 1,
                totalItems: 1,
                totalPages: 1,
                items: [Self.rawr]
            )
            let response = try PocketBase.encoder.encode(
                expectedListResponse,
                configuration: .none
            )
            let environment = PocketBase.TestEnvironment(
                baseURL: baseURL,
                response: response
            )
            let collection = environment.pocketbase.collection(Rawr.self)
            
            let listResponse = try await collection.list(
                page: 0,
                perPage: 1,
                sort: [.init(\Rawr.created, order: .reverse)],
                filter: #Filter<Rawr>({ $0.id == "meow1234" })
            )
            
            #expect(listResponse.page == expectedListResponse.page)
            #expect(listResponse.perPage == expectedListResponse.perPage)
            #expect(listResponse.totalItems == expectedListResponse.totalItems)
            #expect(listResponse.totalPages == expectedListResponse.totalPages)
            #expect(listResponse.items.map(\.id) == expectedListResponse.items.map(\.id))
            
            try environment.assertNetworkRequest(
                url: baseURL.absoluteString + "/api/collections/rawrs/records?page=0&perPage=1&sort=-created&filter=(id%3D'meow1234')&expand=testers_via_rawrs",
                method: .get
            )
        }
        
        @Test("Update Record")
        func updateRecord() async throws {
            let baseURL = Self.baseURL
            let expectedField = "updated"
            let updatedRawr = Rawr(id: Self.id, field: expectedField)
            let response = try PocketBase.encoder.encode(updatedRawr, configuration: .none)
            let environment = PocketBase.TestEnvironment(
                baseURL: baseURL,
                response: response
            )
            let collection = environment.pocketbase.collection(Rawr.self)
            
            let rawr = try await collection.update(updatedRawr)
            #expect(rawr.field == expectedField)
            
            try environment.assertNetworkRequest(
                url: baseURL.absoluteString + "/api/collections/rawrs/records/meow1234?expand=testers_via_rawrs",
                method: .patch,
                body: ["field": "updated"]
            )
        }
        
        @Test("View Record")
        func viewRecord() async throws {
            let baseURL = Self.baseURL
            let environment = PocketBase.TestEnvironment(
                baseURL: baseURL,
                response: try PocketBase.encoder.encode(Self.rawr, configuration: .none)
            )
            let collection = environment.pocketbase.collection(Rawr.self)
            
            let rawr = try await collection.view(id: Self.id)
            #expect(rawr.id == Self.id)
            #expect(rawr.field == Self.field)
            
            try environment.assertNetworkRequest(
                url: baseURL.absoluteString + "/api/collections/rawrs/records/meow1234?expand=testers_via_rawrs",
                method: .get
            )
        }
    }
}
