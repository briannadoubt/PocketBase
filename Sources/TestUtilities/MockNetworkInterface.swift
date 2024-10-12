//
//  MockNetworkInterface.swift
//  PocketBase
//
//  Created by Brianna Zamora on 10/12/24.
//

@testable import PocketBase

public actor MockNetworkInterface: NetworkInterfacing {
    public var baseURL: URL
    public var session: any NetworkSession
    public var decoder = JSONDecoder()
    public var encoder = JSONEncoder()
    
    public init(baseURL: URL, session: MockNetworkSession) {
        self.baseURL = baseURL
        self.session = session
    }
}
