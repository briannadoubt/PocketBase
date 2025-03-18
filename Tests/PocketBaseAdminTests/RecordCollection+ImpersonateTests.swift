//
//  RecordCollection+ImpersonateTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/18/25.
//

import Testing
@testable import PocketBaseAdmin
import TestUtilities
import PocketBase

@Suite("Impersonation Tests")
struct RecordCollectionImpersonateTests: NetworkResponseTestSuite {
    @Test("Impersonate")
    func impersonate() async throws {
        let expectedAuthResponse = Self.authResponse
        let response = try PocketBase.encoder.encode(expectedAuthResponse, configuration: .none)
        let baseURL = Self.baseURL
        let environment = PocketBase.TestEnvironment(baseURL: baseURL, response: response)
        let collection = environment.pocketbase.collection(Tester.self)
        
        let authResponse = try await collection.impersonate(Self.tester.id)
        
        #expect(authResponse.record.id == expectedAuthResponse.record.id)
        #expect(authResponse.record.username == expectedAuthResponse.record.username)
        
        try environment.assertNetworkRequest(
            url: baseURL.absoluteString + "/api/collections/testers/impersonate/\(Self.tester.id)?expand=rawrs",
            method: .post,
            body: ImpersonateBody(duration: 0)
        )
    }
}
