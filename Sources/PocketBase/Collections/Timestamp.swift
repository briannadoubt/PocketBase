//
//  Timestamp.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/11/24.
//

import Foundation

@propertyWrapper
public struct Timestamp: Codable, Hashable, Sendable, RawRepresentable {
    
    static let distantPast: Date = .distantPast
    public var date: Date = Self.distantPast
    
    public var wrappedValue: Date { date }
    
    var formatter: DateFormatter {
        let formatter = DateFormatter()
        // make the formatter work with 2024-08-12 04:23:09.150Z
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
        return formatter
    }
    
    public init?(rawValue: String) {
        self.date = formatter.date(from: rawValue) ?? Self.distantPast
    }
    
    public init() {}
    
    public var rawValue: String {
        formatter.string(from: date)
    }
}
