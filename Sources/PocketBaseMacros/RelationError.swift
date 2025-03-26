//
//  RelationError.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/24/25.
//

enum RelationError {
    case mustBeMarkedAsOptional
    case missingCollectionName
    case mustDefineTypeAnnotation
    case missingIdentifierType
    case missingIdentitifierPattern
    case mustBeVariable
    
    var errorDescription: String {
        switch self {
        case .mustBeMarkedAsOptional:
            "`Relation` variables must be marked as optional. If the relation is optional on the pocketbase side, use `@Relation(.optional)`, otherwise the relationship will be \"required\" and enforced through a memberwise initializer."
        case .missingCollectionName:
            "Missing collection name. Match the collection name property string to the name of the collection on the pocketbase side. Example: `@BaseCollection(\"cats\")`."
        case .mustDefineTypeAnnotation:
            "Missing type annotation. Match the type to the type of the collection on the pocketbase side. Example: `@Relation var cats: [Cat]?`."
        case .missingIdentifierType:
            "Invalid type. Must be an identifier type. Example: `@Relation var cats: [Cat]?`."
        case .missingIdentitifierPattern:
            "Invalid pattern. Must be an identifier pattern. Example: `@Relation var cats: [Cat]?`."
        case .mustBeVariable:
            "Invalid declaration. Must be a variable declaration. Example: `@Relation var cats: [Cat]?`."
        }
    }
}
