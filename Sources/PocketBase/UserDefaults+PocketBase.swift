//
//  UserDefaults+PocketBase.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation

//public protocol UserDefaultsProtocol: Sendable {
//    static var pocketbase: UserDefaultsProtocol? { get }
//    
//    init?(suiteName: String?)
//    
//    func url(forKey: String) -> URL?
//    func value(forKey: String) -> Any?
//    func setValue(_ value: Any?, forKey: String)
//    func removeObject(forKey: String)
//    func set(_ value: Any?, forKey: String)
//    func string(forKey: String) -> String?
//    func data(forKey: String) -> Data?
//}
//
//extension UserDefaults: UserDefaultsProtocol, @unchecked @retroactive Sendable {}

public extension UserDefaults {
    static let pocketbaseSuiteName = "io.pocketbase"
    static var pocketbase: UserDefaults? {
        UserDefaults(suiteName: Self.pocketbaseSuiteName)
    }
}
