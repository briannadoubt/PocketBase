//
//  AuthRecord.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

public protocol AuthRecord: Record {
    var username: String { get }
    var email: String? { get }
    var verified: Bool { get }
    var emailVisibility: Bool { get }
}
