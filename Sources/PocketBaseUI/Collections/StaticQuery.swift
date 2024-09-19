//
//  StaticQuery.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/16/24.
//

import SwiftUI
import PocketBase
import Collections

@MainActor
@propertyWrapper
public struct StaticQuery<T: BaseRecord>: DynamicProperty
where T.EncodingConfiguration == RecordCollectionEncodingConfiguration {
    @Environment(\.pocketbase) private var pocketbase
    
    private var collection: RecordCollection<T> {
        pocketbase.collection(T.self)
    }
    
    private let shouldPage: Bool
    
    @State private var records: [T] = []
    @State private var page: Int
    @State private var nextPage: Int?
    
    private let perPage: Int
    private let sort: [SortDescriptor<T>]
    private let filter: Filter?
    
    public init(
        page: Int = 1,
        perPage: Int = 30,
        shouldPage: Bool = true,
        sort: [SortDescriptor<T>] = [],
        filter: Filter? = nil
    ) {
        _page = State(initialValue: page)
        self.perPage = perPage
        self.shouldPage = shouldPage
        self.sort = sort
        self.filter = filter
    }
    
    public var wrappedValue: [T] {
        records
    }
    
    public func load() async throws {
        let response = try await collection.list(
            page: page,
            perPage: perPage,
            sort: sort,
            filter: filter
        )
        page = response.page
        if shouldPage {
            if response.page < response.totalPages {
                nextPage = response.page + 1
            } else {
                nextPage = nil
            }
        }
        guard let updatedRecords = records.applying(records.difference(from: response.items)) else {
            records = response.items
            return
        }
        records = updatedRecords
    }
}
