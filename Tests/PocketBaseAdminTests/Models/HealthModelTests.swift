//
//  HealthModelTests.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import Testing
@testable import PocketBaseAdmin
@testable import PocketBase

@Suite("HealthModel")
struct HealthModelTests {

    @Test("HealthStatus decoding")
    func decodeHealthStatus() throws {
        let json = """
        {
            "code": 200,
            "message": "API is healthy.",
            "data": {
                "canBackup": true,
                "version": "0.22.0"
            }
        }
        """

        let status = try JSONDecoder().decode(HealthStatus.self, from: Data(json.utf8))

        #expect(status.code == 200)
        #expect(status.message == "API is healthy.")
        #expect(status.data.canBackup == true)
        #expect(status.data.version == "0.22.0")
    }

    @Test("HealthData with missing version")
    func decodeHealthDataMissingVersion() throws {
        let json = """
        {
            "canBackup": false
        }
        """

        let data = try JSONDecoder().decode(HealthData.self, from: Data(json.utf8))

        #expect(data.canBackup == false)
        #expect(data.version == nil)
    }

    @Test("HealthStatus encoding roundtrip")
    func encodingRoundtrip() throws {
        let original = HealthStatus(
            code: 200,
            message: "OK",
            data: HealthData(canBackup: true, version: "1.0.0")
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HealthStatus.self, from: encoded)

        #expect(decoded.code == original.code)
        #expect(decoded.message == original.message)
        #expect(decoded.data.canBackup == original.data.canBackup)
        #expect(decoded.data.version == original.data.version)
    }

    @Test("HealthStatus hashable conformance")
    func hashableConformance() {
        let status1 = HealthStatus(code: 200, message: "OK", data: HealthData(canBackup: true))
        let status2 = HealthStatus(code: 200, message: "OK", data: HealthData(canBackup: true))
        let status3 = HealthStatus(code: 500, message: "Error", data: HealthData(canBackup: false))

        #expect(status1 == status2)
        #expect(status1 != status3)
    }
}
