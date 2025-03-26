//
//  BackRelation.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/24/25.
//

@attached(peer, names: arbitrary)
public macro BackRelation<Base, Value>(
    _ path: KeyPath<Base, Value>
) = #externalMacro(module: "PocketBaseMacros", type: "BackRelation")
