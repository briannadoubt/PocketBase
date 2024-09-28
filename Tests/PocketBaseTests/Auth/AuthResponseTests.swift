//
//  AuthResponseTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/20/24.
//

import Testing
@testable import PocketBase

@Suite("AuthResponse Tests")
struct AuthResponseTests {
    let fake = "fake"
    let tester = Tester(username: "meowface")
    var response: AuthResponse<Tester> {
        AuthResponse(
            token: fake,
            record: tester,
            meta: nil
        )
    }
    
    @Test("AuthResponse Initializer")
    func initializer() {
        let response = response
        #expect(response.token == fake)
        #expect(response.record == tester)
        #expect(response.meta == nil)
    }
    
    @Test("Encode to data")
    func encode() throws {
        let response = response
        let data = try JSONEncoder().encode(response, configuration: .cache)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            Issue.record("Failed to decode JSON")
            return
        }
        guard let token = dictionary["token"] as? String else {
            Issue.record("Failed to decode token")
            return
        }
        #expect(token == fake)
        
        guard let record = dictionary["record"] as? [String: Any] else {
            Issue.record("Failed to decode record")
            return
        }
        do {
            let recordData = try JSONSerialization.data(withJSONObject: record, options: [])
            do {
                let decodedTester = try JSONDecoder().decode(Tester.self, from: recordData)
                
                #expect(decodedTester == tester)
            } catch {
                Issue.record(error, "Failed to decode record")
            }
        } catch {
            Issue.record(error, "Failed to re-encode record")
        }
    }
}
