//
//  UserDefaults+PocketBase.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/10/24.
//

import Foundation

public extension UserDefaults {
    static var pocketbase: UserDefaults? {
        UserDefaults(suiteName: "io.pocketbase")
    }
}
