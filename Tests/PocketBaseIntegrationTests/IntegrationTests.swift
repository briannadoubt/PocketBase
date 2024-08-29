//
//  IntegrationTests.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/11/24.
//

import PocketBase
import Testing
import SwiftData

@Model
@AuthCollection("users")
final class User {
    init(username: String) {
        self.username = username
    }
}

@Model
@BaseCollection("posts")
final class Post {
    var title: String
    
    @Relationship var owner: User?
    
    init(title: String) {
        self.title = title
    }
}

extension Tag {
    @Tag static var integration: Self
    @Tag static var localhostRequired: Self
}

@Test("Happy path through PocketBase", .tags(.integration, .localhostRequired))
func happyPath() async throws {
    // Initialize pocketbase
    let pb = PocketBase(url: URL(string: "http://localhost:8090")!)
    
    // Define the user collection
    let users = await pb.collection(User.self)
    
    // Logout as setup for previously failed tests (for development)
    users.logout()
    
    await #expect(throws: NetworkError.self, performing: {
        // Shouldn't be logged in yet
        try await users.authRefresh()
    })
    
    // Create a new user
    let password = "Test1234%"
    var user = try await users.create(
        User(username: "meowface"),
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
    await #expect(pb.authStore.isValid == false)
    await #expect(pb.authStore.token == nil)
    await #expect(try pb.authStore.record() as User? == nil)
    
    // Login
    user = try await users.login(with: .identity(user.username, password: password))
    
    // Auth store should now be valid with data
    await #expect(pb.authStore.isValid == true)
    await #expect(pb.authStore.token?.isEmpty == false)
    
    // Should now be logged in and this shouldn't throw
    try await users.authRefresh()
    
    // Create a post
    let posts = await pb.collection(Post.self)
    var post = try await posts.create(Post(title: "Hello World"))
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
    users.logout()
    await #expect(throws: NetworkError.self, performing: {
        // Shouldn't be logged in anymore
        try await users.authRefresh()
    })
    
    // Auth store should be empty after logout
    await #expect(pb.authStore.isValid == false)
    await #expect(pb.authStore.token == nil)
    
    // Login again to delete the user
    user = try await users.login(with: .identity(user.username, password: password))
    
    // Auth store should now be valid with data (again)
    await #expect(pb.authStore.isValid == true)
    await #expect(pb.authStore.token?.isEmpty == false)
    
    // Delete user
    try await users.delete(user)
    
    // Auth store should be empty after deleting user
    await #expect(pb.authStore.isValid == false)
    await #expect(pb.authStore.token == nil)
}
