//
//  PocketBase+SwiftData.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/24/24.
//

import Foundation
import SwiftData
import PocketBase

@Model
@AuthCollection("users")
final class User: @unchecked Sendable {
    @Relationship(deleteRule: .cascade) var rawrs: [Rawr] = []
    init() {}
}

@Model
@BaseCollection("rawrs")
final class Rawr: @unchecked Sendable {
    var field: String = ""
    @Relationship var user: User?
    init() {}
}

@ModelActor
public actor PocketBaseSync: HasLogger {
    public func sync<each T: PersistentModel & Record>(_ type: (repeat (each T).Type)) async throws {
        let unsynced = try findUnsynced() as [(repeat (each T, Operation))]
        try await withThrowingTaskGroup(of: Void.self) { group in
            for unsynced in unsynced {
                for (record, operation) in repeat (each unsynced) {
                    group.addTask {
                        switch operation {
                        case .create:
                            await self.create(record)
                        case .update:
                            await self.update(record)
                        case .delete:
                            await self.delete(record)
                        }
                    }
                    try await group.waitForAll(isolation: self)
                }
            }
        }
    }

    enum Operation: Hashable {
        case create
        case update
        case delete
    }
    
    func findUnsynced<each T: PersistentModel & Record>() throws -> [(repeat (each T, Operation))] {
        let tokenData = UserDefaults.standard.data(forKey: Self.lastHistoryToken)
        var historyToken: DefaultHistoryToken? = nil
        if let tokenData {
            historyToken = try JSONDecoder().decode(DefaultHistoryToken.self, from: tokenData)
        }
        let transactions = try findTransactions(after: historyToken, author: "PocketBase")
        let result = try findOperations(with: (repeat (each T).self), in: transactions)

        let newTokenData = try JSONEncoder().encode(result.1)
        UserDefaults.standard.set(newTokenData, forKey: Self.lastHistoryToken)

        return result.0
    }
    
    static let lastHistoryToken: String = "io.pocketbase.lastHistoryToken"

    func findTransactions(after token: DefaultHistoryToken?, author: String) throws -> [DefaultHistoryTransaction] {
        var historyDescriptor = HistoryDescriptor<DefaultHistoryTransaction>()
        if let token {
            historyDescriptor.predicate = #Predicate { transaction in
                (transaction.token > token) && (transaction.author == author)
            }
        }
        var transactions: [DefaultHistoryTransaction] = []
        transactions = try modelContext.fetchHistory(historyDescriptor)
        return transactions
    }

    func findOperations<each T: PersistentModel & Record>(
        with type: (repeat (each T).Type),
        in transactions: [DefaultHistoryTransaction]
    ) throws -> ([(repeat (each T, Operation))], DefaultHistoryToken?) {
        var operations: [(repeat (each T, Operation))] = []
        for transaction in transactions {
            for change in transaction.changes {
                let modelID = change.changedPersistentIdentifier
                let predicate = (repeat predicate((each T).self, modelID: modelID))
                let fetchDescriptor = (repeat FetchDescriptor<each T>(predicate: (each predicate)))
                let fetchResults = (repeat try modelContext.fetch(each fetchDescriptor))
                let matchedRecord = (repeat (each fetchResults).first!)
                switch change {
                case .insert:
                    operations.append((repeat (each matchedRecord, Operation.create)))
                case .update:
                    operations.append((repeat (each matchedRecord, Operation.update)))
                case .delete:
                    operations.append((repeat (each matchedRecord, Operation.delete)))
                default:
                    continue
                }
            }
        }
        return (operations, transactions.last?.token)
    }
    
    func predicate<R: PersistentModel & Record>(
        _ type: R.Type,
        modelID: PersistentIdentifier
    ) -> Predicate<R> {
        #Predicate { $0.persistentModelID == modelID }
    }
    
    func create<T: PersistentModel & Record>(_ record: T) async {
        let pocketbase = PocketBase()
        let collection = pocketbase.collection(T.self)
        do {
            try await collection.create(record)
        } catch {
            Self.logger.error("Failed to create \(T.self): \(error)")
        }
    }
    
    func update<T: PersistentModel & Record>(_ record: T) async {
        let pocketbase = PocketBase()
        let collection = pocketbase.collection(T.self)
        do {
            try await collection.update(record)
        } catch {
            Self.logger.error("Failed to update \(T.self): \(error)")
        }
    }
    
    func delete<T: PersistentModel & Record>(_ record: T) async {
        let pocketbase = PocketBase()
        let collection = pocketbase.collection(T.self)
        do {
            try await collection.delete(record)
        } catch {
            Self.logger.error("Failed to delete \(T.self): \(error)")
        }
    }
}
