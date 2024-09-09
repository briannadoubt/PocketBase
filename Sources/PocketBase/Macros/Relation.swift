//
//  Relation.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/27/24.
//

@attached(peer, names: arbitrary)
public macro Relation() = #externalMacro(module: "PocketBaseMacros", type: "Relation")

// TODO: Add `.skipExpand` attribute to macro invocation
