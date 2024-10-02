# PocketBase

[![Run Tests](https://github.com/briannadoubt/PocketBase/actions/workflows/run-tests.yml/badge.svg)](https://github.com/briannadoubt/PocketBase/actions/workflows/run-tests.yml)

A pure Swift client for interfacing with a PocketBase instance.

## Getting Started

### Development Environment
Easiest way to get started with PocketBase for Swift is to run an instance inside of a Docker container.

Run the following commands to start PocketBase locally:

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

Now you're ready to incorporate the library.

### The Codes

First, be sure to import the right things. This should be all the dependencies required to build an app with PocketBase:
```swift
import PocketBase // <~ Exposes the core `PocketBase` object. Imports `Foundation`.
import PocketBaseUI // <~ Exposes the various SwiftUI helpers surrounding the `PocketBase` instance.
import SwiftUI
```

To setup a pocketbase instance on your app, use the Environment. PocketBase will default to `localhost` if no instance is defined here.

To set up a custom url, use a similar pattern, but just pass a URL:

```swift
@main
struct CatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if DEBUG
        .pocketbase(.localhost) // <~ optional
        #else
        .pocketbase(url: URL(string: "https://production.myFancyApp.com/")!)
        #endif
    }
}
```

Then, if you want to support authentication, you'll need to create an `AuthCollection`. This object should match the field schema shape of your authentication collection defined in your PocketBase admin console:

```swift
@AuthCollection("users") // <~ Define auth collection model to enable authentication.
struct User {
    var name: String = ""
}
```

Now that our app is set up with a user schema to authenticate with, let's make that happen in our App:

```swift
@main
struct CatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .authenticated { username, email in // <~ Attach a default authentication flow to get started.
                    User(username: username, email: email) // <~ Provide a default instance of your user. 
                }
        }
        .pocketbase(.localhost)
    }
}
```

To provide a custom auth flow, use a different overload:

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
    @Environment(\.pocketbase) private var pocketbase // <~ get the `PocketBase` instance from the environment to make mutations
    
    var collection: RecordCollection<User>
    @Binding var authState: AuthState
    
    var body: some View {
        // All your fancy styling here
    
        SignUpButton(
            User.self,
            collection: collection,
            authState: $authState,
            strategy: .identity(
                "meowface",
                password: "Test1234"
            )
        )
    }
}
```

To log a user out, just call `.logout()` on the relevant `RecordCollection<T>`:

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

Now, users can download records in other collections. So let's define another one. Just like the `AuthCollection`, this object should match the field schema shape of your base collection defined in your PocketBase admin console:

```swift
@BaseCollection("rawrs") // <- Define a base collection type
struct Rawr {
    var field: String = ""
}
```

Awesome. Now that we have a type, we can query for them. There are two options in this realm: `StaticQuery` and `RealtimeQuery`.

`StaticQuery` is a simple `propertyWrapper` that pages results and stores them in-memory. It can be used like so:

```swift
struct StaticRawrs: View {
    @StaticQuery private var rawrs: [Rawr]
    var body: some View {
        List(rawrs) { rawr in
            Text(rawr.field)
        }
        .task {
            await $rawrs.load()
        }
        .refreshable {
            await $rawrs.load()
        }
    }
}
```

`RealtimeQuery` is a bit fancier, and enables realtime updates to the data as it changes on the server. It can be used in a very similar way:

```swift
struct RealtimeRawrs: View {
    @RealtimeQuery private var rawrs: [Rawr]
    var body: some View {
        List(rawrs) { rawr in
            Text(rawr.field)
        }
        .task {
            await $rawrs.start()
        }
        .refreshable {
            await $rawrs.start()
        }
    }
}
```

Or, if you want to handle state on your own, you can hook into the async events stream:

```swift
let pocketbase = PocketBase()
var events: [RecordEvent<Rawr>] = []
let stream = try await pocketbase.collection(Rawr.self).events()
for await event in stream {
    let record = event.record
    switch event.action {
    case .create:
        // Do
    case .update:
        // Yo
    case .delete:
        // Thang
    }
}
// etc.
```

Any other data mutations can be made with the `RecordCollection<T>` that is generated with `PocketBase().collection(Rawr.self)`:

```swift
let pocketbase = PocketBase()
let collection = pocketbase.collection(Rawr.self)
let new = Rawr(field: "meow")
let created = try await collection.create(new)
let results = try await collection.list()
let record = try await collection.view(id: created.id)
guard var first = results.items.first else { return }
first.field = "updated value"
let updated = try await collection.update(first)
try await collection.delete(updated)
```
