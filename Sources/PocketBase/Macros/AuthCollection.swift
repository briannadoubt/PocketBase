//
//  AuthCollection.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/12/24.
//

@attached(
    member,
    conformances: AuthRecord,
    names:
        named(collection),
        named(relationships),
        named(id),
        named(collectionName),
        named(collectionId),
        named(created),
        named(updated),
        named(verified),
        named(emailVisibility),
        named(username),
        named(email),
        named(CodingKeys),
        named(relations),
        named(init),
        named(init(from:)),
        named(encode(to:configuration:)),
        named(Expand),
        named(EncodingConfiguration),
)
@attached(
    extension,
    conformances: AuthRecord
)
public macro AuthCollection(
    _ collectionName: String
) = #externalMacro(module: "PocketBaseMacros", type: "AuthCollection")
