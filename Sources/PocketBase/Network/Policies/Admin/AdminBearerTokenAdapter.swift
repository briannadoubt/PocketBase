//
//  AdminBearerTokenAdapter.swift
//  PocketBase
//
//  Created by Bri on 9/20/22.
//

import Alamofire
import Foundation

protocol AdminBearerTokenAdapter: RequestAdapter, KeychainTokenBearer { }

extension AdminBearerTokenAdapter {
    
    var tokenKey: String { "pb_user_auth" }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        guard let token = token else {
            completion(.failure(URLError(.clientCertificateRequired)))
            return
        }
        urlRequest.headers.add( .authorization(bearerToken: "Admin " + token))
        completion(.success(urlRequest))
    }
}
