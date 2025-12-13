//
//  LogModel.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import SwiftUI

/// Represents a log entry from the PocketBase logs API.
public struct LogModel: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let level: LogLevel
    public let message: String
    public let created: Date
    public let data: LogData

    public init(
        id: String,
        level: LogLevel,
        message: String,
        created: Date,
        data: LogData
    ) {
        self.id = id
        self.level = level
        self.message = message
        self.created = created
        self.data = data
    }
}

/// Log level enumeration matching PocketBase's log levels.
public enum LogLevel: Int, Codable, CaseIterable, Identifiable, Sendable, Hashable {
    case debug = -4
    case info = 0
    case warn = 4
    case error = 8

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warn: "WARN"
        case .error: "ERROR"
        }
    }

    public var numericValue: Int {
        rawValue
    }

    public var color: Color {
        switch self {
        case .debug: .gray
        case .info: .blue
        case .warn: .orange
        case .error: .red
        }
    }
}

/// Additional data associated with a log entry.
public struct LogData: Codable, Sendable, Hashable {
    public let type: String?
    public let auth: String?
    public let status: Int?
    public let execTime: Double?
    public let method: String?
    public let url: String?
    public let referer: String?
    public let remoteIp: String?
    public let userIp: String?
    public let userAgent: String?

    public init(
        type: String? = nil,
        auth: String? = nil,
        status: Int? = nil,
        execTime: Double? = nil,
        method: String? = nil,
        url: String? = nil,
        referer: String? = nil,
        remoteIp: String? = nil,
        userIp: String? = nil,
        userAgent: String? = nil
    ) {
        self.type = type
        self.auth = auth
        self.status = status
        self.execTime = execTime
        self.method = method
        self.url = url
        self.referer = referer
        self.remoteIp = remoteIp
        self.userIp = userIp
        self.userAgent = userAgent
    }
}

/// Statistics for logs grouped by date, used for charting.
public struct LogStat: Codable, Identifiable, Sendable, Hashable {
    public let date: Date
    public let total: Int

    public var id: Date { date }

    public init(date: Date, total: Int) {
        self.date = date
        self.total = total
    }
}

/// Response wrapper for paginated logs.
public struct LogsResponse: Codable, Sendable {
    public let page: Int
    public let perPage: Int
    public let totalItems: Int
    public let totalPages: Int
    public let items: [LogModel]

    public init(
        page: Int = 1,
        perPage: Int = 30,
        totalItems: Int = 0,
        totalPages: Int = 0,
        items: [LogModel] = []
    ) {
        self.page = page
        self.perPage = perPage
        self.totalItems = totalItems
        self.totalPages = totalPages
        self.items = items
    }
}
