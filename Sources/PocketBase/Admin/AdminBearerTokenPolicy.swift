//
//  AdminBearerTokenPolicy.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Alamofire
import Foundation

class AdminBearerTokenPolicy: AdminBearerTokenAdapter, ExponentialBackoffRetrier {
    var exponentialBackoffBase: Int = 1
    var exponentialBackoffScale: Double = 2
    var interceptor: Interceptor { Interceptor(adapter: self, retrier: self) }
}
