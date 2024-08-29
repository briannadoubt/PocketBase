//
//  PocketBaseDemoApp.swift
//  PocketBaseDemo
//
//  Created by Brianna Zamora on 8/7/24.
//

import SwiftUI
import PocketBase
import PocketBaseUI

@main
struct PocketBaseDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .authenticated { username, email in
                    User(
                        username: username,
                        email: email
                    )
                }
        }
//        .pocketbase(.localhost)
    }
}
