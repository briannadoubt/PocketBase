//
//  File.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/24/25.
//

@attached(peer, names: arbitrary)
@attached(accessor)
public macro File() = #externalMacro(module: "PocketBaseMacros", type: "File")
