# PocketBase

[![Run Tests](https://github.com/briannadoubt/PocketBase/actions/workflows/run-tests.yml/badge.svg)](https://github.com/briannadoubt/PocketBase/actions/workflows/run-tests.yml)

A pure Swift client for interfacing with a PocketBase instance.

## Package Overview

| Module | Description |
|--------|-------------|
| `PocketBase` | Core client library with records, auth, realtime, and file operations |
| `PocketBaseUI` | SwiftUI property wrappers and view modifiers |
| `PocketBaseAdmin` | Admin API for managing collections, settings, logs, and backups |
| `PocketBaseServer` | Run PocketBase locally using Apple's Containerization framework |
| `PocketBasePlugin` | SwiftPM plugin commands for development |

## Installation

Add PocketBase to your Swift package:

```swift
dependencies: [
    .package(url: "https://github.com/briannadoubt/PocketBase.git", from: "1.0.0")
]
```

Then add the products you need to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "PocketBase", package: "PocketBase"),
        .product(name: "PocketBaseUI", package: "PocketBase"),     // For SwiftUI apps
        .product(name: "PocketBaseAdmin", package: "PocketBase"),  // For admin tools
    ]
)
```

## Table of Contents

- [Getting Started](#getting-started)
  - [Running PocketBase Locally](#running-pocketbase-locally)
  - [Configuration](#configuration)
- [Macros](#macros) - `@AuthCollection`, `@BaseCollection`, `@File`, `@Relation`, `#Filter`
- [Authentication](#authentication)
- [Querying Data](#querying-data) - `@StaticQuery`, `@RealtimeQuery`
- [CRUD Operations](#crud-operations)
- [File Operations](#file-operations)
- [Admin API](#admin-api) - Collections, Records, Settings, Logs, Backups

---

## Getting Started

### Running PocketBase Locally

There are several ways to run PocketBase locally for development. Choose the option that best fits your workflow.

---

#### Option 1: Run from Xcode (Recommended for SwiftUI Apps)

The easiest way to run PocketBase alongside your SwiftUI app is to add the `PocketBaseServer` target directly to your Xcode scheme. This uses Apple's native Containerization framework to run PocketBase in a lightweight Linux VM—no Docker required!

**Requirements:**
- macOS 26 (Tahoe) or later
- Apple Container CLI (install with `brew install apple/container/container`)

**Setup:**

1. **Install the Apple Container CLI:**
   ```shell
   brew tap apple/container
   brew install apple/container/container
   ```

2. **Start the container system** (one-time setup):
   ```shell
   container system start
   ```

3. **Add PocketBaseServer to your Xcode scheme:**
   - Open your project in Xcode
   - Edit your scheme (Product → Scheme → Edit Scheme...)
   - Select "Build" in the sidebar
   - Click "+" and add the `PocketBaseServer` target from the PocketBase package
   - Optionally, check "Parallelize Build" to build both targets simultaneously

4. **Run your app:**
   - When you run your app, Xcode will also start PocketBaseServer
   - PocketBase will be available at `http://localhost:8090`
   - Admin UI at `http://localhost:8090/_/`
   - Data is persisted in `./pb_data` in your project directory

**How it works:**

PocketBaseServer uses Apple's Containerization framework to run the [PocketBase Docker image](https://github.com/muchobien/pocketbase-docker) in a lightweight Linux VM. It automatically:
- Downloads and caches the container image
- Sets up port forwarding from the VM to your Mac
- Mounts `./pb_data` for persistent storage
- Streams container logs to the Xcode console

---

#### Option 2: SwiftPM Plugin Commands

The `PocketBasePlugin` provides convenient commands for building, running, and managing PocketBase from the command line.

**Available Commands:**

```shell
# Build and run the server
swift package pocketbase run

# Build only (with code signing for containerization)
swift package pocketbase build

# Build in release mode
swift package pocketbase build --release

# Run with custom options
swift package pocketbase run -- --port 8080 --verbose
```

**Container Management:**

```shell
# Check container system status
swift package pocketbase container status

# Start the container system
swift package pocketbase container start

# Stop the container system
swift package pocketbase container stop

# Install the Apple Container CLI via Homebrew
swift package pocketbase container install
```

**Database Utilities:**

```shell
# Show database info
swift package pocketbase db info

# Create a backup
swift package pocketbase db backup my-backup

# Restore from backup
swift package pocketbase db restore my-backup

# Clear all data (with confirmation)
swift package pocketbase db clear
```

**Server Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `-H, --host` | Host/interface to bind to | `0.0.0.0` |
| `-p, --port` | Port to expose PocketBase on | `8090` |
| `-d, --dataPath` | Path to data directory | `./pb_data` |
| `--cpus` | Number of CPUs to allocate | `2` |
| `--memory` | Memory in MB to allocate | `512` |
| `-v, --verbose` | Enable verbose output | `false` |
| `--clear` | Clear data directory before starting | `false` |

---

#### Option 3: Docker Compose

If you prefer Docker or aren't on macOS 26+, use Docker Compose:

```shell
docker compose up
```

You should see:

```shell
Starting pocketbase ... done
Attaching to pocketbase
pocketbase    | > Server started at: http://0.0.0.0:8090
pocketbase    |   - REST API: http://0.0.0.0:8090/api/
pocketbase    |   - Admin UI: http://0.0.0.0:8090/_/
```

---

#### Option 4: Download PocketBase Directly

You can also download and run PocketBase directly from the official website:

1. Download the latest release from [pocketbase.io/docs](https://pocketbase.io/docs/)
2. Extract the archive
3. Run the executable:
   ```shell
   ./pocketbase serve
   ```

See the [PocketBase documentation](https://pocketbase.io/docs/) for more configuration options.

---

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

### OAuth2 Authentication

PocketBase Swift supports full OAuth2 authentication with PKCE for providers like Google, GitHub, Discord, and more.

#### Quick Setup

1. **Configure URL scheme in Info.plist:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

2. **Add OAuth configuration to your app:**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .pocketbase(.localhost)
                .oauthConfiguration(redirectScheme: "myapp")
        }
    }
}
```

3. **Use the built-in OAuth buttons:**
```swift
struct LoginView: View {
    @Environment(\.pocketbase) var pocketbase
    @State private var authState: AuthState = .signedOut
    @State private var providers: [OAuthProvider] = []

    var body: some View {
        VStack {
            ForEach(providers) { provider in
                LoginButton(
                    collection: pocketbase.collection("users"),
                    authState: $authState,
                    strategy: .oauth(provider)
                )
            }
        }
        .task {
            let methods = try? await pocketbase.collection("users").listAuthMethods()
            providers = methods?.oauth2.providers ?? []
        }
    }
}
```

#### Manual OAuth Flow

For custom UI or advanced use cases:

```swift
let users = pocketbase.collection("users")

// Login with type-safe provider names
try await users.loginWithOAuth(
    provider: .google,
    redirectScheme: "myapp"
)

// Or use string literals
try await users.loginWithOAuth(
    provider: "github",
    redirectScheme: "myapp"
)

// Sign up with custom user data
let customUser = User(name: "New User", avatar: nil)
try await users.loginWithOAuth(
    provider: .discord,
    redirectScheme: "myapp",
    createData: customUser
)
```

#### Supported Providers

Built-in type-safe constants for common providers:
- `.google`, `.github`, `.gitlab`, `.discord`
- `.twitter`, `.facebook`, `.microsoft`, `.apple`
- `.spotify`, `.kakao`, `.twitch`, `.strava`
- And more...

Custom providers: `.custom("okta")` or use string literals

#### Platform Support

- ✅ iOS 12+ (full support)
- ✅ macOS 10.15+ (full support)
- ✅ visionOS (full support)
- ❌ tvOS/watchOS (no browser-based OAuth)

For complete setup instructions, troubleshooting, and advanced features, see the [OAuth2 Setup Guide](Documentation/OAuth2Setup.md).

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

## Admin API

The `PocketBaseAdmin` module provides a complete interface to PocketBase's administrative endpoints. This is used to build admin dashboards, management tools, or server-side applications.

### Importing the Admin Module

```swift
import PocketBase
import PocketBaseAdmin
```

### Authentication

Admin operations require superuser authentication:

```swift
let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)

// Authenticate as superuser
let superuser = try await pocketbase.collection(Superuser.self)
    .authWithPassword("admin@example.com", password: "yourpassword")
```

### Admin API Overview

Access all admin functionality through `pocketbase.admin`:

```swift
// Collections management
let collections = try await pocketbase.admin.collections.list()

// Records (with admin privileges)
let users = try await pocketbase.admin.records("users").list()

// Server settings
let settings = try await pocketbase.admin.settings.get()

// Request logs
let logs = try await pocketbase.admin.logs.list()

// Backups
let backups = try await pocketbase.admin.backups.list()

// Health check
let health = try await pocketbase.admin.health.check()
```

### Collections Management

Create, update, and manage collection schemas programmatically:

```swift
// List all collections
let collections = try await pocketbase.admin.collections.list()

// View a specific collection
let posts = try await pocketbase.admin.collections.view(id: "posts")

// Create a new collection
let request = CollectionCreateRequest(
    name: "articles",
    type: .base,
    schema: [
        Field(id: "title_field", name: "title", type: .text, required: true),
        Field(id: "content_field", name: "content", type: .editor),
        Field(id: "published_field", name: "published", type: .bool)
    ],
    listRule: "@request.auth.id != \"\"",  // Authenticated users only
    viewRule: "",                           // Public access
    createRule: "@request.auth.verified = true"
)
let created = try await pocketbase.admin.collections.create(request)

// Update a collection
let updateRequest = CollectionUpdateRequest(
    name: "articles",
    listRule: nil  // Admin only
)
try await pocketbase.admin.collections.update(id: "articles", updateRequest)

// Delete a collection
try await pocketbase.admin.collections.delete(id: "articles")

// Import collections from JSON
try await pocketbase.admin.collections.import(collections, deleteMissing: false)
```

#### View Collections

View collections use SQL queries to create virtual tables:

```swift
let viewRequest = CollectionCreateRequest(
    name: "published_posts",
    type: .view,
    viewQuery: "SELECT id, title, created FROM posts WHERE published = true",
    viewRule: ""  // Public access (View collections only have list/view rules)
)
try await pocketbase.admin.collections.create(viewRequest)
```

### Records Management

Manage records in any collection with admin privileges:

```swift
let records = pocketbase.admin.records("users")

// List with pagination and filtering
let result = try await records.list(
    page: 1,
    perPage: 50,
    filter: "verified = true",
    sort: "-created"
)

// View a single record
let user = try await records.view(id: "abc123")

// Create a record
let newRecord = try await records.create([
    "email": "user@example.com",
    "name": "New User"
])

// Create with file upload
let recordWithFile = try await records.create(
    ["name": "Document"],
    files: [UploadFile(filename: "doc.pdf", data: pdfData, mimeType: "application/pdf")]
)

// Update a record
try await records.update(id: "abc123", ["name": "Updated Name"])

// Delete a record
try await records.delete(id: "abc123")
```

### Settings Management

Read and update server settings:

```swift
// Get current settings
let settings = try await pocketbase.admin.settings.get()
print(settings.meta?.appName)
print(settings.smtp?.enabled)

// Update settings
try await pocketbase.admin.settings.update(SettingsModel(
    meta: Meta(
        appName: "My App",
        appUrl: "https://myapp.com",
        senderName: "My App",
        senderAddress: "noreply@myapp.com"
    ),
    smtp: SMTPSettings(
        enabled: true,
        host: "smtp.example.com",
        port: 587,
        username: "user",
        password: "pass",
        tls: true
    ),
    s3: S3Settings(
        enabled: true,
        bucket: "my-bucket",
        region: "us-east-1",
        endpoint: "s3.amazonaws.com",
        accessKey: "...",
        secret: "..."
    )
))

// Test email configuration
try await pocketbase.admin.settings.testEmail(to: "test@example.com")

// Test S3 configuration
try await pocketbase.admin.settings.testS3(filesystem: "storage")
```

### Logs

Access request logs for debugging and monitoring:

```swift
// List logs with pagination
let logs = try await pocketbase.admin.logs.list(
    page: 1,
    perPage: 100,
    filter: "level >= 4"  // Warnings and errors only
)

for log in logs.items {
    print("\(log.created): [\(log.level)] \(log.message)")
    print("  URL: \(log.url)")
    print("  Status: \(log.status)")
}

// View a specific log entry
let log = try await pocketbase.admin.logs.view(id: "log_id")

// Get log statistics
let stats = try await pocketbase.admin.logs.stats()
```

### Backups

Create and manage database backups:

```swift
// List existing backups
let backups = try await pocketbase.admin.backups.list()

// Create a new backup
try await pocketbase.admin.backups.create(name: "backup_2024")

// Download a backup
let backupData = try await pocketbase.admin.backups.download(key: "backup_2024.zip")

// Restore from backup
try await pocketbase.admin.backups.restore(key: "backup_2024.zip")

// Delete a backup
try await pocketbase.admin.backups.delete(key: "backup_2024.zip")
```

### Health Checks

Monitor server health:

```swift
let health = try await pocketbase.admin.health.check()
print("Server healthy: \(health.code == 200)")
print("Message: \(health.message)")
```

## Requirements

- iOS 17.0+ / macOS 15.0+
- Swift 6.1+ (Xcode 16.3+) or Swift 6.2+ (Xcode 26+)

**Native Containerization (PocketBaseServer):**
- macOS 26.0+ (Tahoe) and Swift 6.2+ required for running containers
