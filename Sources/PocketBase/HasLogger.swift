//
//  HasLogger.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/18/24.
//

import os

public protocol HasLogger {
    static var logger: Logger { get }
}

extension HasLogger {
    public static var logger: Logger {
        Logger(subsystem: "PocketBase", category: String(describing: Self.self))
    }
}
