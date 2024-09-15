//
//  IntegrationTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/11/24.
//

import PocketBase
import Testing
import SwiftData
import Foundation

@AuthCollection("users")
struct User {
    @BackRelation var posts: [Post] = []
}

@BaseCollection("posts")
struct Post {
    var title: String
    @Relation var owner: User?
    @Relation var tags: [Tag]?
}

@BaseCollection("tags")
struct Tag {
    var name: String
    @BackRelation var posts: [Post] = []
}

extension Testing.Tag {
    @Tag static var integration: Self
    @Tag static var localhostRequired: Self
}

@Test(
    "Happy path through PocketBase",
    .tags(.integration, .localhostRequired)
)
func happyPath() async throws {
    // Initialize pocketbase
    let pb = PocketBase(url: URL(string: "http://localhost:8090")!)
    
    // Define the user collection
    let users = pb.collection(User.self)
    
    // Logout as setup for previously failed tests (for development)
    await users.logout()
    
    await #expect(throws: NetworkError.self, performing: {
        // Shouldn't be logged in yet
        try await users.authRefresh()
    })
    
    // Create a new user
    let password = "Test1234%"
    var user = try await users.create(
        User(),
        password: password,
        passwordConfirm: password
    )
    #expect(user.collectionId.isEmpty == false)
    #expect(user.username == "meowface")
    #expect(user.email == nil)
    #expect(user.verified == false)
    #expect(user.emailVisibility == false)
    
    await #expect(throws: NetworkError.self, performing: {
        // Still shouldn't be logged in yet
        try await users.authRefresh()
    })
    
    // Auth store should be empty prior to authentication
    #expect(pb.authStore.isValid == false)
    #expect(pb.authStore.token == nil)
    #expect(try pb.authStore.record() as User? == nil)
    
    // Login
    user = try await users.login(with: .identity(user.username, password: password))
    
    // Auth store should now be valid with data
    #expect(pb.authStore.isValid == true)
    #expect(pb.authStore.token?.isEmpty == false)
    
    // Should now be logged in and this shouldn't throw
    try await users.authRefresh()
    
    // Create a post
    let posts = pb.collection(Post.self)
    var post = try await posts.create(Post(title: "Hello World", owner: user.id))
    var allPosts = try await posts.list()
    #expect(allPosts.items.count == 1)
    #expect(allPosts.items.first == post)
    #expect(post.id != nil)
    #expect(post.title == "Hello World")
    
    // Update a post
    post.title = "Updated Title"
    post = try await posts.update(post)
    #expect(post.title == "Updated Title")
    
    // View the same post
    let theSamePost = try await posts.view(id: post.id)
    #expect(post == theSamePost)
    
    // Delete the post
    try await posts.delete(post)
    allPosts = try await posts.list()
    #expect(allPosts.items.count == 0)
    
    // Logout and assert
    await users.logout()
    await #expect(throws: NetworkError.self, performing: {
        // Shouldn't be logged in anymore
        try await users.authRefresh()
    })
    
    // Auth store should be empty after logout
    #expect(pb.authStore.isValid == false)
    #expect(pb.authStore.token == nil)
    
    // Login again to delete the user
    user = try await users.login(with: .identity(user.username, password: password))
    
    // Auth store should now be valid with data (again)
    #expect(pb.authStore.isValid == true)
    #expect(pb.authStore.token?.isEmpty == false)
    
    // Delete user
    try await users.delete(user)
    
    // Auth store should be empty after deleting user
    #expect(pb.authStore.isValid == false)
    #expect(pb.authStore.token == nil)
}
