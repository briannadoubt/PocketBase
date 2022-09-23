//
//  UserBearerTokenPolicy.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Alamofire
import Foundation

public final class UserBearerTokenPolicy: UserBearerTokenAdapter, ExponentialBackoffRetrier {
    public var exponentialBackoffBase: Int = 1
    public var exponentialBackoffScale: Double = 2
    public var interceptor: Interceptor { Interceptor(adapter: self, retrier: self) }
    
    public init(exponentialBackoffBase: Int = 1, exponentialBackoffScale: Double = 2) {
        self.exponentialBackoffBase = exponentialBackoffBase
        self.exponentialBackoffScale = exponentialBackoffScale
    }
}
