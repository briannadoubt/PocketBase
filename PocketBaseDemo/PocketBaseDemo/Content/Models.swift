//
//  Models.swift
//  PocketBaseDemo
//
//  Created by Brianna Zamora on 8/13/24.
//

import PocketBase

@AuthCollection("users")
struct User {}

@BaseCollection("rawrs")
struct Rawr {
    var field: String
}
