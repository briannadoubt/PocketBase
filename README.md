# PocketBase

A pure Swift client for interfacing with a PocketBase instance.


## Getting Started

### Development Environment
Easiest way to get started with PocketBase for Swift is to run an instance inside of a Docker container.

Run the following commands to start PocketBase locally:

```shell
cd <path>/PocketBase/Developer
docker-compose up
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

The PocketBase Swift library defaults to sending requests to the default PocketBase docker image URL: http://0.0.0.0:8090/`.

```swift
import PocketBase // <~ 1.
import SwiftUI
```
1. Import `PocketBase` to your project.

```swift
@main
struct TestApp: App {
    
    @Client var client: PocketBase // <~ 2
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(client) // <~ 3
                .environment(\.baseUrl,  URL(string: "http://0.0.0.0:8090/")!) // <~ 4 (Optional)
        }
    }
}
```
2. Create an instance of PocketBase with the `@Client` property wrapper. This internally creates a singleton that lives throughout the lifecycle of your app.
3. Add the `client` to the environment so that child views can access the singleton.
4. Optionally specify the URL where your PocketBase instance is served. If this is omitted the URL will default to `http://0.0.0.0:8090/`.

```swift
struct Test: Codable, Identifiable { // <~ 5
    var id: String?
    var foo: String
}
```
5. Create the model object. Must conform to both `Codable` and `Identifiable`.
```swift
struct ContentView: View {
    
    @Query("test") var tests: [Test] // <~ 6
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tests) { test in // <~ 7
                    Text(test.foo)
                }
            }
            .navigationTitle("Tests Collection")
        }
    }
}
```
6. Create a `@Query` instance. This is the object that does the most magic. It will download the records for the given collection and then subscribe to realtime updatest to keep the server and the client in sync.
7. Display the data in your view.
