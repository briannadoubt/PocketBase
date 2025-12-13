//
//  LogModelTests.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import Testing
@testable import PocketBaseAdmin
@testable import PocketBase

@Suite("LogModel")
struct LogModelTests {

    @Test("LogLevel raw values match PocketBase API")
    func logLevelRawValues() {
        #expect(LogLevel.debug.rawValue == -4)
        #expect(LogLevel.info.rawValue == 0)
        #expect(LogLevel.warn.rawValue == 4)
        #expect(LogLevel.error.rawValue == 8)
    }

    @Test("LogLevel display names")
    func logLevelDisplayNames() {
        #expect(LogLevel.debug.displayName == "DEBUG")
        #expect(LogLevel.info.displayName == "INFO")
        #expect(LogLevel.warn.displayName == "WARN")
        #expect(LogLevel.error.displayName == "ERROR")
    }

    @Test("LogModel decoding from JSON")
    func decodeLogModel() throws {
        let json = """
        {
            "id": "log123",
            "level": 0,
            "message": "Request completed",
            "created": "2024-01-15 10:30:00.000Z",
            "data": {
                "type": "request",
                "status": 200,
                "method": "GET",
                "url": "/api/collections"
            }
        }
        """

        let log = try PocketBase.decoder.decode(LogModel.self, from: Data(json.utf8))

        #expect(log.id == "log123")
        #expect(log.level == .info)
        #expect(log.message == "Request completed")
        #expect(log.data.type == "request")
        #expect(log.data.status == 200)
        #expect(log.data.method == "GET")
        #expect(log.data.url == "/api/collections")
    }

    @Test("LogData decoding with optional fields")
    func decodeLogDataPartial() throws {
        let json = """
        {
            "type": "request"
        }
        """

        let data = try JSONDecoder().decode(LogData.self, from: Data(json.utf8))

        #expect(data.type == "request")
        #expect(data.auth == nil)
        #expect(data.status == nil)
        #expect(data.execTime == nil)
    }

    @Test("LogsResponse decoding")
    func decodeLogsResponse() throws {
        let json = """
        {
            "page": 1,
            "perPage": 30,
            "totalItems": 100,
            "totalPages": 4,
            "items": []
        }
        """

        let response = try JSONDecoder().decode(LogsResponse.self, from: Data(json.utf8))

        #expect(response.page == 1)
        #expect(response.perPage == 30)
        #expect(response.totalItems == 100)
        #expect(response.totalPages == 4)
        #expect(response.items.isEmpty)
    }

    @Test("LogStat decoding")
    func decodeLogStat() throws {
        let json = """
        {
            "date": "2024-01-15 00:00:00.000Z",
            "total": 42
        }
        """

        let stat = try PocketBase.decoder.decode(LogStat.self, from: Data(json.utf8))

        #expect(stat.total == 42)
        #expect(stat.id == stat.date)
    }

    @Test("LogModel encoding roundtrip")
    func encodeDecodeRoundtrip() throws {
        let original = LogModel(
            id: "abc123",
            level: .warn,
            message: "Test warning",
            created: Date(timeIntervalSince1970: 1705316400),
            data: LogData(
                type: "test",
                status: 500,
                method: "POST"
            )
        )

        let encoded = try PocketBase.encoder.encode(original)
        let decoded = try PocketBase.decoder.decode(LogModel.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.level == original.level)
        #expect(decoded.message == original.message)
        #expect(decoded.data.type == original.data.type)
        #expect(decoded.data.status == original.data.status)
    }
}
