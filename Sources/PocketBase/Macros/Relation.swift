//
//  Relation.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/27/24.
//

@attached(peer, names: arbitrary)
public macro Relation(
    _ options: RelationOption...
) = #externalMacro(module: "PocketBaseMacros", type: "Relation")

@attached(peer, names: arbitrary)
public macro BackRelation<Base, Value>(
    _ path: KeyPath<Base, Value>
) = #externalMacro(module: "PocketBaseMacros", type: "BackRelation")

public enum RelationOption {
    case skipExpand
    case optional
}
