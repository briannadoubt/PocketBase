//
//  Sort.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/25/24.
//

import Foundation

extension Collection {
    func sortParameter<T: Record>() -> String where Self.Element == SortDescriptor<T> {
        map { sortDescriptor in
            let orderPrefix = sortDescriptor.order == .reverse ? "-" : ""
            let keyPath = sortDescriptor.keyPath!
            let keyPathString = "\(keyPath)".components(separatedBy: ".").last!
            return "\(orderPrefix)\(keyPathString)"
        }
        .joined(separator: ",")
    }
}
