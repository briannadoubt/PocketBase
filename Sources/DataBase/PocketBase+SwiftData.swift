//
//  PocketBase+SwiftData.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/24/24.
//

import Foundation
import SwiftData
import PocketBase

extension PocketBase {
    /// Inspect the latest changes of the given types in a correlated `ModelContainer` instance, and sync those changes with a remote PocketBase instance through atomic network requests.
    ///
    /// This is an experimental idea to sync records from SwiftData to a remote PocketBase instance. This would enable atomic, lightning-fast lookups, and realtime updates. The idea was inspired by the official JavaScript and Dart clients, as they have client-side caching.
    ///
    /// It would be ideal to pair this with the realtime features for incoming changes, and sync them into SwiftData. Then, use this solution to push all the local changes to a remote PocketBase instance. This would mean interacting with SwiftData is interacting with PocketBase, much like iCloud.
    /// 
    /// However, this has been challenging. Given the fresh complexities of SwiftData, and some difficult challenges listed below, this will stay experimental for now. Maybe we can get this out in v3.0.0.
    /// 
    /// A few known challenges with a relational storage approach:
    /// 
    /// 1. SwiftData's `PersistentModel`, and the correlated `@Model` macro is, by design, not `Sendable`. This currently compiles with `@unchecked Sendable`, but this will assuredly cause data faults as the objects are passed around. Not scalable.
    /// 2. Decoding patterns are currently using custom a `@Relation` peer macro to annotate the model relationships. This would have to be reworked with SwiftData's `@Relationship` macro and proves complex.
    /// 3. Managing a `ModelContainer` instance requires a singleton. This poses a challenge with the atomic nature of how a new `PocketBase` instance is stood up, and would make it challenging to both expose a flexible interface to the api calls _and_ refactor away the `UserDefaults` dependency (which enables the empty `PocketBase()` initializer).
    /// 4. Parsing a `#Predicate` into a filter string proved to be difficult. This prompted the creation of `#Filter`, which shares a lot of the same interface conveniences. 
    /// 5. Determining changes in relations (adding a reference from one object to another, for example) is a very imperative pattern through the APIs, so parsing that history and crafting a relevant POST body could prove complicated.
    /// 6. A large sync from the phone could in theory generate a LOT of network requests. We would need to find a way to batch them, intersperse them (rate limit), or ensure this is a scalable pattern.
    ///
    /// In an ideal world, this could look something like this:
    ///
    /// ```swift
    /// fileprivate struct Cat {
    ///     func meow() async throws {
    ///         let container = try ModelContainer(
    ///             for: User.self, Rawr.self,
    ///             configurations: .init(isStoredInMemoryOnly: true)
    ///         )
    ///         let pocketbase = PocketBase()
    ///         try await pocketbase.sync(to: container, with: User.self, Rawr.self)
    ///     }
    /// }
    /// ```
    ///
    /// - Note: An alternative approach could be to store the mutation events (create, update, or delete) as their own model objects, and return the last result as a `Data` blob if the device is offline. Then, once internet is restored, use this sync system to push all the changes to a remote PocketBase instance.
    /// - Parameters:
    ///   - modelContainer: The `ModelContainer` used to sync the most recent history to a remote PocketBase instance.
    ///   - type: A `repeat`ing type that is iterated over and synced, type-by-type.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, macCatalyst 18.0, visionOS 2.0, *)
    public func sync<each T: PersistentModel & Record>(
        to modelContainer: ModelContainer,
        with type: repeat (each T).Type
    ) async throws {
        let unsynced = try findUnsynced(in: modelContainer) as [(repeat ((each T), Operation))]
        try await withThrowingTaskGroup(of: Void.self) { group in
            for unsynced in unsynced {
                for (record, operation) in repeat each unsynced {
                    group.addTask {
//                        let pocketbase = PocketBase()
                        switch operation {
                        case .create:
                            func create<R: PersistentModel & Record>(_ record: R) async {
//                                let collection = pocketbase.collection(R.self)
//                                do {
//                                    try await collection.create(record)
//                                } catch {
//                                    Self.logger.error("Failed to create \(R.self): \(error)")
//                                }
                            }
                            
                            await create(record)
                        case .update:
                            func update<R: PersistentModel & Record>(_ record: R) async {
//                                let collection = pocketbase.collection(R.self)
//                                do {
//                                    try await collection.update(record)
//                                } catch {
//                                    Self.logger.error("Failed to update \(R.self): \(error)")
//                                }
                            }
                            
                            await update(record)
                        case .delete:
                            func delete<R: PersistentModel & Record>(_ record: R) async {
//                                let collection = pocketbase.collection(R.self)
//                                do {
//                                    try await collection.delete(record)
//                                } catch {
//                                    Self.logger.error("Failed to delete \(R.self): \(error)")
//                                }
                            }
                            
                            await delete(record)
                        }
                    }
                }
            }
            try await group.waitForAll()
        }
    }

    enum Operation: Hashable {
        case create
        case update
        case delete
    }
    
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, macCatalyst 18.0, visionOS 2.0, *)
    func findUnsynced<each T: PersistentModel & Record>(
        in modelContainer: ModelContainer
    ) throws -> [(repeat ((each T), Operation))] {
        let tokenData = UserDefaults.pocketbase?.data(forKey: Self.lastHistoryToken)
        var historyToken: DefaultHistoryToken? = nil
        if let tokenData {
            historyToken = try JSONDecoder().decode(DefaultHistoryToken.self, from: tokenData)
        }
        let transactions = try findTransactions(in: modelContainer, after: historyToken, author: "PocketBase")
        let result = try findOperations(in: modelContainer, with: repeat (each T).self, in: transactions)

        let newTokenData = try JSONEncoder().encode(result.1)
        UserDefaults.pocketbase?.set(newTokenData, forKey: Self.lastHistoryToken)

        return result.0
    }
    
    static let lastHistoryToken: String = "io.pocketbase.lastHistoryToken"

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, macCatalyst 18.0, visionOS 2.0, *)
    func findTransactions(
        in modelContainer: ModelContainer,
        after token: DefaultHistoryToken?,
        author: String
    ) throws -> [DefaultHistoryTransaction] {
        var historyDescriptor = HistoryDescriptor<DefaultHistoryTransaction>()
        if let token {
            historyDescriptor.predicate = #Predicate { transaction in
                (transaction.token > token) && (transaction.author == author)
            }
        }
        var transactions: [DefaultHistoryTransaction] = []
        let modelContext = ModelContext(modelContainer)
        transactions = try modelContext.fetchHistory(historyDescriptor)
        return transactions
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, macCatalyst 18.0, visionOS 2.0, *)
    func findOperations<each T: PersistentModel & Record>(
        in modelContainer: ModelContainer,
        with type: repeat (each T).Type,
        in transactions: [DefaultHistoryTransaction]
    ) throws -> (
        [(repeat ((each T), Operation))],
        DefaultHistoryToken?
    ) {
        let modelContext = ModelContext(modelContainer)
        return try (
            transactions
                .map(\.changes)
                .flatMap({ $0 })
                .compactMap { change in
                    let modelID = change.changedPersistentIdentifier
                    let predicate = (repeat predicate((each T).self, modelID: modelID))
                    let fetchDescriptor = (repeat FetchDescriptor<each T>(predicate: (each predicate)))
                    let fetchResults = (repeat try modelContext.fetch(each fetchDescriptor))
                    let matchedRecord = (repeat (each fetchResults).first!)
                    switch change {
                    case .insert:
                        return (repeat ((each matchedRecord), Operation.create))
                    case .update:
                        return (repeat ((each matchedRecord), Operation.update))
                    case .delete:
                        return (repeat ((each matchedRecord), Operation.delete))
                    default:
                        return nil
                    }
                },
            transactions.last?.token
        )
    }
    
    func emptyOperations<R: PersistentModel & Record>(
        _ type: R.Type
    ) -> [(R, Operation)] {
        []
    }
    
    func predicate<R: PersistentModel & Record>(
        _ type: R.Type,
        modelID: PersistentIdentifier
    ) -> Predicate<R> {
        #Predicate { $0.persistentModelID == modelID }
    }
}
