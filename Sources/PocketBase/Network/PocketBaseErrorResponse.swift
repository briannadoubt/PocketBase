//
//  PocketBaseErrorResponse.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public struct PocketBaseErrorResponse: Decodable, Sendable {
    public var code: Int
    public var message: String
    public var errorDetails: String?
}
