//
//  SettingsModelTests.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import Testing
@testable import PocketBaseAdmin
@testable import PocketBase

@Suite("SettingsModel")
struct SettingsModelTests {

    @Test("SettingsModel decoding")
    func decodeSettingsModel() throws {
        let json = """
        {
            "meta": {
                "appName": "My App",
                "appUrl": "https://myapp.com"
            },
            "adminAuthToken": 1209600,
            "recordAuthToken": 1209600,
            "logs": {
                "maxDays": 7,
                "minLevel": 0
            }
        }
        """

        let settings = try JSONDecoder().decode(SettingsModel.self, from: Data(json.utf8))

        #expect(settings.meta?.appName == "My App")
        #expect(settings.meta?.appUrl == "https://myapp.com")
        #expect(settings.adminAuthToken == 1209600)
        #expect(settings.recordAuthToken == 1209600)
        #expect(settings.logs?.maxDays == 7)
    }

    @Test("SettingsModel with all fields")
    func decodeFullSettingsModel() throws {
        let json = """
        {
            "meta": {
                "appName": "Test App",
                "appUrl": "https://test.com",
                "hideControls": false,
                "senderName": "Admin",
                "senderAddress": "admin@test.com"
            },
            "adminAuthToken": 1209600,
            "adminPasswordResetToken": 1800,
            "adminFileToken": 120,
            "recordAuthToken": 1209600,
            "recordPasswordResetToken": 1800,
            "recordEmailChangeToken": 1800,
            "recordVerificationToken": 604800,
            "recordFileToken": 120,
            "logs": {
                "maxDays": 7,
                "minLevel": 0,
                "logIp": true
            },
            "smtp": {
                "enabled": true,
                "host": "smtp.example.com",
                "port": 587,
                "tls": true
            },
            "s3": {
                "enabled": false
            },
            "backups": {
                "cron": "0 0 * * *",
                "cronTimezone": "UTC"
            }
        }
        """

        let settings = try JSONDecoder().decode(SettingsModel.self, from: Data(json.utf8))

        #expect(settings.meta?.senderName == "Admin")
        #expect(settings.adminPasswordResetToken == 1800)
        #expect(settings.recordVerificationToken == 604800)
        #expect(settings.smtp?.enabled == true)
        #expect(settings.smtp?.port == 587)
        #expect(settings.backups?.cron == "0 0 * * *")
    }

    @Test("SettingsModel encoding roundtrip")
    func encodingRoundtrip() throws {
        let original = SettingsModel(
            meta: Meta(appName: "Test", appUrl: "https://test.com"),
            adminAuthToken: 3600,
            logs: LogsSettings(maxDays: 30)
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SettingsModel.self, from: encoded)

        #expect(decoded.meta?.appName == original.meta?.appName)
        #expect(decoded.adminAuthToken == original.adminAuthToken)
        #expect(decoded.logs?.maxDays == original.logs?.maxDays)
    }
}

@Suite("TokenDuration")
struct TokenDurationTests {

    @Test("TokenDuration decoding from int")
    func decodeFromInt() throws {
        let json = "3600"
        let duration = try JSONDecoder().decode(TokenDuration.self, from: Data(json.utf8))
        #expect(duration.duration == 3600)
    }

    @Test("TokenDuration encoding to int")
    func encodeToInt() throws {
        let duration = TokenDuration(7200)
        let encoded = try JSONEncoder().encode(duration)
        let decoded = try JSONDecoder().decode(Int.self, from: encoded)
        #expect(decoded == 7200)
    }

    @Test("TokenDuration roundtrip")
    func roundtrip() throws {
        let original = TokenDuration(86400)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TokenDuration.self, from: encoded)
        #expect(decoded.duration == original.duration)
    }
}

@Suite("Meta")
struct MetaTests {

    @Test("Meta decoding")
    func decodeMeta() throws {
        let json = """
        {
            "appName": "My Application",
            "appUrl": "https://app.example.com",
            "hideControls": true,
            "senderName": "No Reply",
            "senderAddress": "noreply@example.com"
        }
        """

        let meta = try JSONDecoder().decode(Meta.self, from: Data(json.utf8))

        #expect(meta.appName == "My Application")
        #expect(meta.appUrl == "https://app.example.com")
        #expect(meta.hideControls == true)
        #expect(meta.senderName == "No Reply")
        #expect(meta.senderAddress == "noreply@example.com")
    }

    @Test("Meta partial decoding")
    func decodePartialMeta() throws {
        let json = """
        {
            "appName": "Partial App"
        }
        """

        let meta = try JSONDecoder().decode(Meta.self, from: Data(json.utf8))

        #expect(meta.appName == "Partial App")
        #expect(meta.appUrl == nil)
        #expect(meta.hideControls == nil)
    }
}

@Suite("SMTPSettings")
struct SMTPSettingsTests {

    @Test("SMTPSettings decoding")
    func decodeSMTPSettings() throws {
        let json = """
        {
            "enabled": true,
            "host": "smtp.gmail.com",
            "port": 587,
            "username": "user@gmail.com",
            "password": "app_password",
            "authMethod": "PLAIN",
            "tls": true,
            "localName": "localhost"
        }
        """

        let smtp = try JSONDecoder().decode(SMTPSettings.self, from: Data(json.utf8))

        #expect(smtp.enabled == true)
        #expect(smtp.host == "smtp.gmail.com")
        #expect(smtp.port == 587)
        #expect(smtp.tls == true)
        #expect(smtp.authMethod == "PLAIN")
    }
}

@Suite("S3Settings")
struct S3SettingsTests {

    @Test("S3Settings decoding")
    func decodeS3Settings() throws {
        let json = """
        {
            "enabled": true,
            "bucket": "my-bucket",
            "region": "us-east-1",
            "endpoint": "https://s3.amazonaws.com",
            "accessKey": "AKIAIOSFODNN7EXAMPLE",
            "secret": "secret-key",
            "forcePathStyle": false
        }
        """

        let s3 = try JSONDecoder().decode(S3Settings.self, from: Data(json.utf8))

        #expect(s3.enabled == true)
        #expect(s3.bucket == "my-bucket")
        #expect(s3.region == "us-east-1")
        #expect(s3.forcePathStyle == false)
    }
}

@Suite("BackupsSettings")
struct BackupsSettingsTests {

    @Test("BackupsSettings decoding")
    func decodeBackupsSettings() throws {
        let json = """
        {
            "cron": "0 0 * * *",
            "cronTimezone": "America/New_York",
            "s3": {
                "enabled": true,
                "bucket": "backups-bucket"
            }
        }
        """

        let backups = try JSONDecoder().decode(BackupsSettings.self, from: Data(json.utf8))

        #expect(backups.cron == "0 0 * * *")
        #expect(backups.cronTimezone == "America/New_York")
        #expect(backups.s3?.enabled == true)
        #expect(backups.s3?.bucket == "backups-bucket")
    }
}

@Suite("LogsSettings")
struct LogsSettingsTests {

    @Test("LogsSettings decoding")
    func decodeLogsSettings() throws {
        let json = """
        {
            "maxDays": 14,
            "minLevel": -4,
            "logIp": true
        }
        """

        let logs = try JSONDecoder().decode(LogsSettings.self, from: Data(json.utf8))

        #expect(logs.maxDays == 14)
        #expect(logs.minLevel == -4)
        #expect(logs.logIp == true)
    }
}
