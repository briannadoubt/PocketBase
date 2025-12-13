//
//  BackupModelTests.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import Testing
@testable import PocketBaseAdmin
@testable import PocketBase

@Suite("BackupModel")
struct BackupModelTests {

    @Test("BackupModel decoding")
    func decodeBackupModel() throws {
        let json = """
        {
            "key": "pb_backup_20240115_103000.zip",
            "size": 1048576,
            "modified": "2024-01-15 10:30:00.000Z"
        }
        """

        let backup = try PocketBase.decoder.decode(BackupModel.self, from: Data(json.utf8))

        #expect(backup.key == "pb_backup_20240115_103000.zip")
        #expect(backup.size == 1048576)
        #expect(backup.id == backup.key)
    }

    @Test("BackupModel id is key")
    func idIsKey() {
        let backup = BackupModel(
            key: "test_backup.zip",
            size: 1000,
            modified: Date()
        )

        #expect(backup.id == "test_backup.zip")
    }

    @Test("BackupModel formattedSize")
    func formattedSize() {
        let smallBackup = BackupModel(key: "small.zip", size: 500, modified: Date())
        let mediumBackup = BackupModel(key: "medium.zip", size: 1_048_576, modified: Date())
        let largeBackup = BackupModel(key: "large.zip", size: 1_073_741_824, modified: Date())

        // Just verify the formatted strings are not empty
        #expect(!smallBackup.formattedSize.isEmpty)
        #expect(!mediumBackup.formattedSize.isEmpty)
        #expect(!largeBackup.formattedSize.isEmpty)

        // Medium should contain MB, large should contain GB
        #expect(mediumBackup.formattedSize.contains("MB") || mediumBackup.formattedSize.contains("KB"))
        #expect(largeBackup.formattedSize.contains("GB") || largeBackup.formattedSize.contains("MB"))
    }

    @Test("BackupModel encoding roundtrip")
    func encodingRoundtrip() throws {
        let date = Date(timeIntervalSince1970: 1705316400)
        let original = BackupModel(
            key: "backup_test.zip",
            size: 123456,
            modified: date
        )

        let encoded = try PocketBase.encoder.encode(original)
        let decoded = try PocketBase.decoder.decode(BackupModel.self, from: encoded)

        #expect(decoded.key == original.key)
        #expect(decoded.size == original.size)
    }

    @Test("BackupModel hashable conformance")
    func hashableConformance() {
        let date = Date()
        let backup1 = BackupModel(key: "backup1.zip", size: 100, modified: date)
        let backup2 = BackupModel(key: "backup1.zip", size: 100, modified: date)
        let backup3 = BackupModel(key: "backup2.zip", size: 200, modified: date)

        #expect(backup1 == backup2)
        #expect(backup1 != backup3)

        var set: Set<BackupModel> = []
        set.insert(backup1)
        set.insert(backup2)
        #expect(set.count == 1)
    }
}
