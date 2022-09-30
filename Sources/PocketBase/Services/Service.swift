//
//  Service.swift
//  PocketBase
//
//  Created by Bri on 9/26/22.
//

import Foundation
import Alamofire

public protocol Service: ObservableObject {
    var baseUrl: URL { get }
    init(baseUrl: URL, interceptor: Interceptor)
}

public extension Service {
    /// Used to make HTTP requests.
    var http: HTTP { HTTP() }
}
