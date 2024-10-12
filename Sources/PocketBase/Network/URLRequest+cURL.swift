//
//  URLRequest+cURL.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/17/24.
//

import Foundation

extension URLRequest {
    public var cURL: String {
        let newLine: String
        newLine = "\\\n"
        var method: String
        method = "--request "
        method = method + "\(self.httpMethod ?? "GET") \(newLine)"
        let urlArgument = "--url "
        let url: String = urlArgument + "\'\(self.url?.absoluteString ?? "")\' \(newLine)"
        
        var cURL = "curl "
        var header = ""
        var data: String = ""
        
        if let httpHeaders = self.allHTTPHeaderFields, httpHeaders.keys.count > 0 {
            for (key,value) in httpHeaders {
                var headerFlag: String
                headerFlag = "--header "
                header += headerFlag + "\'\(key): \(value)\' \(newLine)"
            }
        }
        
        if
            let bodyData = httpBody,
            let bodyString = String(
                data: bodyData,
                encoding: .utf8
            ),
            !bodyString.isEmpty
        {
            data = "--data '\(bodyString)'"
        }
        
        cURL += method + url + header + data
        
        return cURL
    }
}
