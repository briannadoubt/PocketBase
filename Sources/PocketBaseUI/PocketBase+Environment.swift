//
//  Environment.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/13/24.
//

import PocketBase
import SwiftUI

extension EnvironmentValues {
    /// <#Description#>
    @Entry public var pocketbase = PocketBase.localhost
}

public extension Scene {
    /// <#Description#>
    /// - Parameter url: <#url description#>
    /// - Returns: <#description#>
    @SceneBuilder func pocketbase(url: URL) -> some Scene {
        pocketbase(PocketBase(url: url))
    }
    
    /// <#Description#>
    /// - Parameter pocketbase: <#pocketbase description#>
    /// - Returns: <#description#>
    @SceneBuilder func pocketbase(_ pocketbase: PocketBase) -> some Scene {
        environment(\.pocketbase, pocketbase)
    }
}

public extension View {
    /// <#Description#>
    /// - Parameter url: <#url description#>
    /// - Returns: <#description#>
    @ViewBuilder func pocketbase(url: URL) -> some View {
        pocketbase(PocketBase(url: url))
    }
    
    /// <#Description#>
    /// - Parameter pocketbase: <#pocketbase description#>
    /// - Returns: <#description#>
    @ViewBuilder func pocketbase(_ pocketbase: PocketBase) -> some View {
        environment(\.pocketbase, pocketbase)
    }
}
