//
//  UserBearerTokenAdapter.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Alamofire
import Foundation

public protocol UserBearerTokenAdapter: RequestAdapter, KeychainTokenBearer { }

public extension UserBearerTokenAdapter {
    
    var tokenKey: String { "pb_user_auth" }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        guard let token = token else {
            completion(.failure(URLError(.clientCertificateRequired)))
            return
        }
        urlRequest.headers.add( .authorization(bearerToken: "User " + token))
        completion(.success(urlRequest))
    }
}
