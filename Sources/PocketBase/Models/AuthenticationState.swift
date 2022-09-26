//
//  AuthenticationState.swift
//  PocketBase
//
//  Created by Bri on 9/23/22.
//

import Foundation
import SwiftUI

public enum AuthenticationState<Profile: Model> {
    case initial
    case loading(message: String?)
    case loggedIn(token: String)
    case loggedOut
}
