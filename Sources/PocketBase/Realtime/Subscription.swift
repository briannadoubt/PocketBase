//
//  Subscription.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/18/24.
//

import Foundation
import AsyncAlgorithms

public struct Subscription: Sendable {
    public let type: any BaseRecord.Type
    public let channel = AsyncChannel<any Event>()
    init(_ type: any BaseRecord.Type) {
        self.type = type
    }
}
