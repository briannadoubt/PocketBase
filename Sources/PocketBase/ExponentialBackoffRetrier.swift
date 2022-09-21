//
//  ExponentialBackoffRetrier.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Alamofire
import Foundation

public protocol ExponentialBackoffRetrier: RequestRetrier {
    var exponentialBackoffBase: Int { get set }
    var exponentialBackoffScale: Double { get set }
}

public extension ExponentialBackoffRetrier {
    
    var retryableHTTPMethods: [HTTPMethod] { [.get, .connect] }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard
            request.retryCount == 0,
            let httpMethod = request.request?.method,
            retryableHTTPMethods.contains(httpMethod)
        else {
            completion(.doNotRetry)
            return
        }
        let timeDelay = pow(Double(exponentialBackoffBase), Double(request.retryCount)) * exponentialBackoffScale
        completion(.retryWithDelay(timeDelay))
    }
}
