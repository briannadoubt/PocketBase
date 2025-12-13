//
//  SettingsModels.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

/// Complete settings model from the PocketBase server.
public struct SettingsModel: Codable, Sendable, Hashable {
    public var meta: Meta?
    public var adminAuthToken: Int?
    public var adminPasswordResetToken: Int?
    public var adminFileToken: Int?
    public var recordAuthToken: Int?
    public var recordPasswordResetToken: Int?
    public var recordEmailChangeToken: Int?
    public var recordVerificationToken: Int?
    public var recordFileToken: Int?
    public var logs: LogsSettings?
    public var smtp: SMTPSettings?
    public var s3: S3Settings?
    public var backups: BackupsSettings?

    public init(
        meta: Meta? = nil,
        adminAuthToken: Int? = nil,
        adminPasswordResetToken: Int? = nil,
        adminFileToken: Int? = nil,
        recordAuthToken: Int? = nil,
        recordPasswordResetToken: Int? = nil,
        recordEmailChangeToken: Int? = nil,
        recordVerificationToken: Int? = nil,
        recordFileToken: Int? = nil,
        logs: LogsSettings? = nil,
        smtp: SMTPSettings? = nil,
        s3: S3Settings? = nil,
        backups: BackupsSettings? = nil
    ) {
        self.meta = meta
        self.adminAuthToken = adminAuthToken
        self.adminPasswordResetToken = adminPasswordResetToken
        self.adminFileToken = adminFileToken
        self.recordAuthToken = recordAuthToken
        self.recordPasswordResetToken = recordPasswordResetToken
        self.recordEmailChangeToken = recordEmailChangeToken
        self.recordVerificationToken = recordVerificationToken
        self.recordFileToken = recordFileToken
        self.logs = logs
        self.smtp = smtp
        self.s3 = s3
        self.backups = backups
    }
}

/// Token duration wrapper providing a `duration` property.
public struct TokenDuration: Codable, Sendable, Hashable {
    public let duration: Int

    public init(_ duration: Int) {
        self.duration = duration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.duration = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(duration)
    }
}

/// Application metadata settings.
public struct Meta: Codable, Sendable, Hashable {
    public var appName: String?
    public var appUrl: String?
    public var hideControls: Bool?
    public var senderName: String?
    public var senderAddress: String?

    public init(
        appName: String? = nil,
        appUrl: String? = nil,
        hideControls: Bool? = nil,
        senderName: String? = nil,
        senderAddress: String? = nil
    ) {
        self.appName = appName
        self.appUrl = appUrl
        self.hideControls = hideControls
        self.senderName = senderName
        self.senderAddress = senderAddress
    }
}

/// Logs configuration settings.
public struct LogsSettings: Codable, Sendable, Hashable {
    public var maxDays: Int?
    public var minLevel: Int?
    public var logIp: Bool?

    public init(
        maxDays: Int? = nil,
        minLevel: Int? = nil,
        logIp: Bool? = nil
    ) {
        self.maxDays = maxDays
        self.minLevel = minLevel
        self.logIp = logIp
    }
}

/// SMTP email configuration settings.
public struct SMTPSettings: Codable, Sendable, Hashable {
    public var enabled: Bool?
    public var host: String?
    public var port: Int?
    public var username: String?
    public var password: String?
    public var authMethod: String?
    public var tls: Bool?
    public var localName: String?

    public init(
        enabled: Bool? = nil,
        host: String? = nil,
        port: Int? = nil,
        username: String? = nil,
        password: String? = nil,
        authMethod: String? = nil,
        tls: Bool? = nil,
        localName: String? = nil
    ) {
        self.enabled = enabled
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.authMethod = authMethod
        self.tls = tls
        self.localName = localName
    }
}

/// S3 storage configuration settings.
public struct S3Settings: Codable, Sendable, Hashable {
    public var enabled: Bool?
    public var bucket: String?
    public var region: String?
    public var endpoint: String?
    public var accessKey: String?
    public var secret: String?
    public var forcePathStyle: Bool?

    public init(
        enabled: Bool? = nil,
        bucket: String? = nil,
        region: String? = nil,
        endpoint: String? = nil,
        accessKey: String? = nil,
        secret: String? = nil,
        forcePathStyle: Bool? = nil
    ) {
        self.enabled = enabled
        self.bucket = bucket
        self.region = region
        self.endpoint = endpoint
        self.accessKey = accessKey
        self.secret = secret
        self.forcePathStyle = forcePathStyle
    }
}

/// Backup configuration settings.
public struct BackupsSettings: Codable, Sendable, Hashable {
    public var cron: String?
    public var cronTimezone: String?
    public var s3: S3Settings?

    public init(
        cron: String? = nil,
        cronTimezone: String? = nil,
        s3: S3Settings? = nil
    ) {
        self.cron = cron
        self.cronTimezone = cronTimezone
        self.s3 = s3
    }
}
