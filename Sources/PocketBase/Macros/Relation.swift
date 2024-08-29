//
//  Relation.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/27/24.
//

@freestanding(expression)
public macro Relation<T: Record>() -> Relation<T> = #externalMacro(module: "PocketBaseMacros", type: "Relation")

public struct Relation<T: Record>: Codable, Equatable, Identifiable, RawRepresentable {
    public var record: T?
    
    public init(record: T) {
        self.record = record
    }
    
    public var id: String? {
        rawValue
    }
    
    public init?(rawValue: String?) {}
    
    public var rawValue: String? {
        record?.id
    }
}
