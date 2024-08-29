//
//  QueryParameter.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/2/24.
//

import Foundation

public protocol QueryParameter {
    var queryItem: URLQueryItem { get }
}
