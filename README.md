# PocketBase

[![Run Tests](https://github.com/briannadoubt/PocketBase/actions/workflows/run-tests.yml/badge.svg)](https://github.com/briannadoubt/PocketBase/actions/workflows/run-tests.yml)

A pure Swift client for interfacing with a PocketBase instance.

## Getting Started

### Development Environment

There are two ways to run PocketBase locally for development:

#### Option 1: Docker (Recommended for most users)

```shell
git clone https://github.com/briannadoubt/PocketBase.git
cd PocketBase
docker compose up
```

You should then see something like:

```shell
Starting pocketbase ... done
Attaching to pocketbase
pocketbase    | > Server started at: http://0.0.0.0:8090
pocketbase    |   - REST API: http://0.0.0.0:8090/api/
pocketbase    |   - Admin UI: http://0.0.0.0:8090/_/
```

#### Option 2: Native Containerization (macOS 26+)

On macOS 26 (Tahoe) and later, you can run PocketBase using Apple's native Containerization framework. This provides a lightweight Linux VM without needing Docker.

**Prerequisites:**
1. macOS 26 or later
2. Run `container system start` once to initialize the container runtime
3. Download a Linux kernel (`vmlinux`) to the project root

**Running:**
```shell
make debug
# or
swift run PocketBaseServer
```

The server will start PocketBase in a container with automatic port forwarding to `localhost:8090`.

### The Codes

First, be sure to import the right things:
```swift
import PocketBase   // Core PocketBase client. Imports Foundation.
import PocketBaseUI // SwiftUI helpers for PocketBase.
import SwiftUI
```

## Configuration

### Setting Up PocketBase

Use the environment modifier to configure your PocketBase instance:

```swift
@main
struct CatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if DEBUG
        .pocketbase(.localhost) // Local development on the same machine
        #else
        .pocketbase(url: URL(string: "https://production.myFancyApp.com/")!)
        #endif
    }
}
```

### Local Network Access

For testing on physical devices (like your iPhone) while your PocketBase server runs on your Mac:

#### Direct IP Configuration
```swift
.pocketbase(.localNetwork(ip: "10.0.0.185")) // Replace with your Mac's IP
```

#### Configured IP via UserDefaults
```swift
// Set your Mac's IP address (do this once, update when IP changes)
UserDefaults.standard.set("10.0.0.185", forKey: "io.pocketbase.local_ip")

// Then use:
.pocketbase(.configuredLocalNetwork) // Uses IP from UserDefaults, falls back to localhost
```

**Tip:** Find your Mac's local IP with: `ifconfig en0 | grep "inet " | awk '{print $2}'`

## Macros

PocketBase for Swift provides several macros to simplify working with collections:

### @AuthCollection

Defines an authentication collection model that matches your PocketBase auth collection schema:

```swift
@AuthCollection("users")
struct User {
    var name: String = ""
    var avatar: String = ""
}
```

This generates all the boilerplate for authentication including `id`, `email`, `username`, `verified`, `emailVisibility`, `created`, and `updated` fields.

### @BaseCollection

Defines a base collection model:

```swift
@BaseCollection("posts")
struct Post {
    var title: String = ""
    var content: String = ""
    var published: Bool = false
}
```

This generates `id`, `collectionId`, `collectionName`, `created`, and `updated` fields automatically.

### @File

Marks a property as a file field with hydrated `FileValue` objects:

```swift
@BaseCollection("posts")
struct Post {
    var title: String = ""

    @File var coverImage: FileValue?      // Single file
    @File var attachments: [FileValue]?   // Multiple files
}
```

**Accessing files:**
```swift
if let cover = post.coverImage?.existingFile {
    let url = cover.url
    let thumbUrl = cover.url(thumb: .crop(width: 100, height: 100))
    let downloadUrl = cover.url(download: true)
}
```

**Uploading files:**
```swift
let imageData = // ... your image data
let uploadFile = UploadFile(filename: "cover.png", data: imageData, mimeType: "image/png")

var post = Post(title: "My Post")
post.coverImage = .pending(uploadFile)
let created = try await collection.create(post)

// The returned post has a hydrated FileValue with URL
if let url = created.coverImage?.existingFile?.url {
    // Ready to use!
}
```

### @Relation

Defines a relation to another collection:

```swift
@BaseCollection("comments")
struct Comment {
    var text: String = ""

    @Relation var author: User?           // Single relation
    @Relation var likedBy: [User]?        // Multiple relations
}
```

Relations are automatically expanded when fetching records.

**Options:**
- `.skipExpand` - Don't automatically expand this relation
- `.optional` - Relation is optional

### @BackRelation

Defines a back-relation from another collection:

```swift
@AuthCollection("users")
struct User {
    var name: String = ""

    @BackRelation(\Comment.author) var comments: [Comment]?
}
```

### #Filter

A type-safe way to build PocketBase filter expressions:

```swift
let filter = #Filter<Post> { post in
    post.published == true && post.title ~ "Swift"
}

let results = try await collection.list(filter: filter)
```

**Supported operators:**
| Operator | Description |
|----------|-------------|
| `==` | Equal |
| `!=` | Not equal |
| `>` | Greater than |
| `>=` | Greater than or equal |
| `<` | Less than |
| `<=` | Less than or equal |
| `~` | Like/Contains |
| `!~` | Not like |
| `?=` | Any equal (for arrays) |
| `?!=` | Any not equal |
| `?>` | Any greater than |
| `?>=` | Any greater than or equal |
| `?<` | Any less than |
| `?<=` | Any less than or equal |
| `?~` | Any like |
| `?!~` | Any not like |

## Authentication

### Basic Authentication Flow

```swift
@AuthCollection("users")
struct User {
    var name: String = ""
}

@main
struct CatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .authenticated { username, email in
                    User(username: username, email: email)
                }
        }
        .pocketbase(.localhost)
    }
}
```

### Custom Authentication Flow

```swift
@main
struct CatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .authenticated(as: User.self) {
                    ProgressView("Loading...")
                } signedOut: { collection, authState in
                    CustomLoginScreen(
                        collection: collection,
                        authState: authState
                    )
                }
        }
        .pocketbase(.localhost)
    }
}

struct CustomLoginScreen: View {
    @Environment(\.pocketbase) private var pocketbase

    var collection: RecordCollection<User>
    @Binding var authState: AuthState

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)

            Button("Login") {
                Task {
                    try await collection.authWithPassword(email, password: password)
                    authState = .signedIn
                }
            }
        }
    }
}
```

### Logging Out

```swift
struct LogoutButton: View {
    @Environment(\.pocketbase) private var pocketbase

    var body: some View {
        Button("Logout") {
            pocketbase.collection(User.self).logout()
        }
    }
}
```

## Querying Data

### StaticQuery

A simple property wrapper that fetches and stores results in-memory:

```swift
struct PostList: View {
    @StaticQuery private var posts: [Post]

    var body: some View {
        List(posts) { post in
            Text(post.title)
        }
        .task {
            await $posts.load()
        }
        .refreshable {
            await $posts.load()
        }
    }
}
```

### RealtimeQuery

Enables realtime updates as data changes on the server:

```swift
struct RealtimePosts: View {
    @RealtimeQuery private var posts: [Post]

    var body: some View {
        List(posts) { post in
            Text(post.title)
        }
        .task {
            await $posts.start()
        }
    }
}
```

### Manual Event Handling

```swift
let pocketbase = PocketBase()
let stream = try await pocketbase.collection(Post.self).events()

for await event in stream {
    let record = event.record
    switch event.action {
    case .create:
        // Handle create
    case .update:
        // Handle update
    case .delete:
        // Handle delete
    }
}
```

## CRUD Operations

```swift
let pocketbase = PocketBase()
let collection = pocketbase.collection(Post.self)

// Create
let newPost = Post(title: "Hello World", content: "My first post")
let created = try await collection.create(newPost)

// List
let results = try await collection.list()

// View single record
let post = try await collection.view(id: created.id)

// Update
var updated = post
updated.title = "Updated Title"
let saved = try await collection.update(updated)

// Delete
try await collection.delete(saved)
```

### Filtering and Sorting

```swift
// With type-safe filter
let filter = #Filter<Post> { $0.published == true }
let published = try await collection.list(filter: filter)

// With sort
let sorted = try await collection.list(sort: [.ascending("created")])

// With pagination
let page = try await collection.list(page: 1, perPage: 20)
```

## File Operations

### Uploading Files

```swift
// Single file upload
var post = Post(title: "My Post")
post.coverImage = .pending(UploadFile(
    filename: "cover.jpg",
    data: imageData,
    mimeType: "image/jpeg"
))
let created = try await collection.create(post)

// Multiple files
post.attachments = [
    .pending(UploadFile(filename: "doc1.pdf", data: data1, mimeType: "application/pdf")),
    .pending(UploadFile(filename: "doc2.pdf", data: data2, mimeType: "application/pdf"))
]
```

### Accessing File URLs

```swift
if let file = post.coverImage?.existingFile {
    // Basic URL
    let url = file.url

    // With thumbnail (images only)
    let thumb = file.url(thumb: .crop(width: 200, height: 200))

    // Force download
    let download = file.url(download: true)

    // Protected file with token
    let token = try await collection.getFileToken()
    let protected = file.url(token: token.token)
}
```

### Deleting Files

```swift
try await collection.deleteFiles(
    from: post,
    files: FileDeletePayload(["attachments": ["old-file.pdf"]])
)
```

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.0+
- Xcode 16.0+

**Native Containerization (PocketBaseServer):**
- macOS 26.0+ (Tahoe) required for running containers
