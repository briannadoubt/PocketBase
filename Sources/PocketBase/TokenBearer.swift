//
//  TokenBearer.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Foundation

public protocol TokenBearer {
    var tokenKey: String { get }
    var token: String? { get set }
}
