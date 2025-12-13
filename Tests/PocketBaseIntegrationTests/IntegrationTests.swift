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
import TestUtilities

#if os(macOS)
import PocketBaseServerLib
#endif

@AuthCollection("users")
struct User {
    @BackRelation(\Post.owner) var posts: [Post] = []
}

@BaseCollection("posts")
struct Post {
    var title: String
    @Relation var owner: User?
    @Relation var tags: [Tag]?
    @BackRelation(\Comment.post) var postComments: [Comment] = []
}

@BaseCollection("tags")
struct Tag {
    var name: String
    @BackRelation(\Post.tags) var posts: [Post] = []
}

@BaseCollection("comments")
struct Comment {
    var text: String
    @Relation var post: Post?
    @Relation var author: User?
}

extension Testing.Tag {
    @Tag static var integration: Self
    @Tag static var localhostRequired: Self
}

// MARK: - Shared Container Setup

/// Tracks whether the container started successfully
/// Integration tests will be skipped if this is false
nonisolated(unsafe) var containerAvailable = false

/// Suite that manages the shared PocketBase container for all integration tests
@Suite("PocketBase Integration Tests", .serialized)
struct PocketBaseIntegrationTests {

    /// Start the shared container before any tests run
    init() async throws {
        #if os(macOS)
        do {
            try await PocketBaseServerLauncher.shared.start(
                port: 8090,
                dataPath: "./pb_data_test",
                verbose: true,
                clear: true  // Start with a clean database
            )
            containerAvailable = true
        } catch {
            // Container failed to start (likely missing entitlements when running via `swift test`)
            // Tests will be skipped
            print("[PocketBaseIntegrationTests] Container failed to start: \(error.localizedDescription)")
            print("[PocketBaseIntegrationTests] Integration tests will be skipped. Run from Xcode to execute integration tests.")
            containerAvailable = false
        }
        #endif
    }
}

@Test(
    "Happy path through PocketBase",
    .tags(.integration, .localhostRequired),
    .enabled(if: containerAvailable, "PocketBase container not available. Run from Xcode to execute integration tests.")
)
@MainActor
func happyPath() async throws {
    // Initialize pocketbase
    let pb = PocketBase(
        url: .localhost,
        authStore: AuthStore(
            keychain: MockKeychain.self,
            service: #function,
            defaults: UserDefaultsSpy(suiteName: #function)
        )
    )
    
    // Define the user collection
    let users = pb.collection(User.self)
    
    // Logout as setup for previously failed tests (for development)
    await users.logout()
    
    await #expect(throws: NetworkError.self, performing: {
        // Shouldn't be logged in yet
        try await users.authRefresh()
    })
    
    // list authentication methods
    
    let methods = try await users.listAuthMethods()
    
    #expect(methods.emailPassword)
    
    // Create a new user
    let password = "Test1234%"
    var user = try await users.create(
        User(),
        password: password,
        passwordConfirm: password
    )
    #expect(user.collectionId.isEmpty == false)
    #expect(user.email == nil)
    #expect(user.verified == false)
    #expect(user.emailVisibility == false)
    let username = user.username
    
    await #expect(throws: NetworkError.self, performing: {
        // Still shouldn't be logged in yet
        try await users.authRefresh()
    })
    
    // Auth store should be empty prior to authentication
    #expect(pb.authStore.isValid == false)
    #expect(pb.authStore.token == nil)
    #expect(try pb.authStore.record() as User? == nil)
    
    // Login
    user = try await users.login(
        with: .identity(
            username,
            password: password
        )
    )
    
    #expect(user.username == username)
    
    // Auth store should now be valid with data
    #expect(pb.authStore.isValid == true)
    #expect(pb.authStore.token?.isEmpty == false)
    
    // Should now be logged in and this shouldn't throw
    try await users.authRefresh()
    
    let tags = pb.collection(Tag.self)
    
    let tag1 = try await tags.create(Tag(name: "Meow"))
    let tag2 = try await tags.create(Tag(name: "Purr"))
    let tag3 = try await tags.create(Tag(name: "Woof"))
    
    // Create a post
    let posts = pb.collection(Post.self)
    var events: [RecordEvent<Post>] = []
    let stream = try await posts.events()
    
    Task { @MainActor in
        for await event in stream {
            events.append(event)
        }
    }
    
    var post = try await posts.create(
        Post(
            title: "Hello World",
            owner: user.id,
            tags: [tag1.id, tag2.id, tag3.id]
        )
    )
    var allPosts = try await posts.list()
    #expect(events.map(\.action) == [.create])
//    #expect(events.map(\.record) == allPosts.items)
    #expect(allPosts.items.count == 1)
    #expect(allPosts.items.first == post)
    #expect(post.id != nil)
    #expect(post.title == "Hello World")
    #expect(post.tags == [tag1, tag2, tag3])
    
    // Update a post
    post.title = "Updated Title"
    post = try await posts.update(post)
    #expect(post.title == "Updated Title")
    
    #expect(events.map(\.action) == [.create, .update])
    
    let comments = pb.collection(Comment.self)
    
    let comment = try await comments.create(
        Comment(
            text: "Hello World",
            post: post.id,
            author: user.id
        )
    )
    
    #expect(comment.post?.id == post.id)
    
    // View the same post
    let theSamePost = try await posts.view(id: post.id)
    #expect(post.id == theSamePost.id)
    #expect(events.map(\.action) == [.create, .update])
    
    #expect(theSamePost.postComments.count == 1)
    #expect(theSamePost.postComments.first?.text == comment.text)
    #expect(theSamePost.postComments.first?.id == comment.id)
    
    try await comments.delete(comment)
    
    post = try await posts.view(id: post.id)
    
    #expect(post.postComments == [])
    
    // Delete the post
    try await posts.delete(post)
    
    allPosts = try await posts.list()
    #expect(allPosts.items.count == 0)
    
    #expect(events.map(\.action) == [.create, .update, .delete])
    
    try await tags.delete(tag1)
    try await tags.delete(tag2)
    try await tags.delete(tag3)
    
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
    
    #expect(user.username == username)
    
    // Auth store should now be valid with data (again)
    #expect(pb.authStore.isValid == true)
    #expect(pb.authStore.token?.isEmpty == false)
    
    // Delete user
    try await users.delete(user)
    
    // Auth store should be empty after deleting user
    #expect(pb.authStore.isValid == false)
    #expect(pb.authStore.token == nil)
}
