//
//  Models.swift
//  PocketBaseDemo
//
//  Created by Brianna Zamora on 8/13/24.
//

import PocketBase

@AuthCollection("users")
struct User {
    init(username: String, email: String?) {
        self.username = username
        self.email = email
    }
}

@BaseCollection("posts")
struct Post {
    var title: String
    var body: String
    @Relation var author: User?
}

@BaseCollection("rawrs")
struct Rawr {
    var field: String
    @Relation var owner: User?
}
