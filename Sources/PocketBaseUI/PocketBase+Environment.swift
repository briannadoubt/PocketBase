//
//  Environment.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/13/24.
//

import PocketBase
import SwiftUI

extension EnvironmentValues {
    @Entry public var pocketbase = PocketBase.localhost
}

public extension Scene {
    @SceneBuilder func pocketbase(url: URL) -> some Scene {
        pocketbase(PocketBase(url: url))
    }
    
    @SceneBuilder func pocketbase(_ pocketbase: PocketBase) -> some Scene {
        environment(\.pocketbase, pocketbase)
    }
}

public extension View {
    @ViewBuilder func pocketbase(url: URL) -> some View {
        pocketbase(PocketBase(url: url))
    }
    
    @ViewBuilder func pocketbase(_ pocketbase: PocketBase) -> some View {
        environment(\.pocketbase, pocketbase)
    }
}
