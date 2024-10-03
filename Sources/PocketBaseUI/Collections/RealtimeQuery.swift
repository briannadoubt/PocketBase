//
//  RealtimeQuery.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/18/24.
//

import PocketBase
import SwiftUI
import Collections

/// Observe a set of records given
@MainActor
@propertyWrapper
public struct RealtimeQuery<T: BaseRecord>: DynamicProperty {
    /// <#Description#>
    /// - Parameters:
    ///   - page: <#page description#>
    ///   - perPage: <#perPage description#>
    ///   - shouldPage: <#shouldPage description#>
    ///   - sort: <#sort description#>
    public init(
        page: Int = 0,
        perPage: Int = 30,
        shouldPage: Bool = true,
        sort: [SortDescriptor<T>] = [SortDescriptor(\.created, order: .reverse)]
    ) {
        self.page = page
        let configuration = Configuration(
            perPage: perPage,
            shouldPage: shouldPage,
            sort: sort
        )
        self.configuration = configuration
        self.records = []
    }
    
    @Environment(\.pocketbase) private var pocketbase

    @State private var records: [T]
    @State private var page: Int
    @State private var nextPage: Int?
    
    private var collection: RecordCollection<T> {
        pocketbase.collection(T.self)
    }
    
    /// The records exposed to the view.
    public var wrappedValue: [T] {
        records
    }
    
    @State private var mostRecentError: Error?
    
    /// The `Coodinator` object that enables an interface with the `RealtimeQuery`'s interface from the view.
    public var projectedValue: Coordinator {
        Coordinator(
            error: mostRecentError
        ) {
            try await start()
        } load: {
            try await load()
        }
    }
    
    /// - note: This should stay `internal`. Public access is available through the `projectedValue`.
    internal func start() async throws {
        self.mostRecentError = nil
        if records.isEmpty {
            try await load()
        }
        let events = try await collection.events()
        for await event in events {
            let record = event.value
            switch event.action {
            case .create:
                insert(record)
            case .update:
                update(record)
            case .delete:
                remove(record)
            }
        }
    }
    
    private func load() async throws {
        self.mostRecentError = nil
        let response = try await getRecords()
        page = response.page
        if configuration.shouldPage {
            if response.page < response.totalPages {
                nextPage = response.page + 1
            } else {
                nextPage = nil
            }
        }
        guard let updatedRecords = records.applying(response.items.difference(from: records)) else {
            return
        }
        records = updatedRecords
    }
    
    @State
    private var configuration: RealtimeQuery<T>.Configuration

    @MainActor
    private func set(_ response: RecordCollection<T>.ListResponse) {
        self.records = response.items
    }
    
    @MainActor
    private func insert(_ record: T) {
        records.append(record)
        sort()
    }
    
    @MainActor
    private func remove(_ record: T) {
        records[record.id] = nil
    }
    
    @MainActor
    private func update(_ record: T) {
        guard let existingIndex = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[existingIndex] = record
        sort()
    }
    
    @MainActor
    private func sort() {
        records = records.sorted(using: configuration.sort)
    }
    
    @MainActor
    private func getRecords() async throws -> RecordCollection<T>.ListResponse {
        try await collection.list(
            page: page,
            perPage: configuration.perPage,
            sort: configuration.sort
        )
    }
}

extension Array where Element: Record, Index == Int {
    subscript(id: String) -> Element? {
        get {
            first(where: { $0.id == id })
        }
        set {
            guard let index = firstIndex(where: { $0.id == id }) else {
                return
            }
            if let newValue {
                self[index] = newValue
            } else {
                self.remove(at: index)
            }
        }
    }
}
extension RealtimeQuery {
    public struct Configuration : Sendable{
        public var perPage: Int
        public var shouldPage: Bool
        public var sort: [SortDescriptor<T>]
        
        public init(
            perPage: Int,
            shouldPage: Bool,
            sort: [SortDescriptor<T>]
        ) {
            self.perPage = perPage
            self.shouldPage = shouldPage
            self.sort = sort
        }
    }
}

extension RealtimeQuery {
    public struct Coordinator: Sendable {
        public var error: (any Error)?
        public var start: @Sendable () async throws -> Void
        public var load: @Sendable () async throws -> Void
    }
}
