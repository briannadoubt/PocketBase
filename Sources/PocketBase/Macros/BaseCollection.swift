//
//  BaseCollection.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/12/24.
//

@attached(
    member,
    conformances: BaseRecord,
    names:
        named(collection),
        named(relationships),
        named(id),
        named(collectionName),
        named(collectionId),
        named(created),
        named(updated),
        named(CodingKeys),
        named(init),
        named(encode),
        named(relations),
        named(Expand)
)
@attached(
    extension,
    conformances: BaseRecord
)
public macro BaseCollection(_ collectionName: String) = #externalMacro(module: "PocketBaseMacros", type: "BaseCollection")
