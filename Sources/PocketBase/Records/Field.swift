//
//  Field.swift
//  PocketBase
//
//  Created by Bri on 9/27/22.
//

import Foundation
import RegexBuilder
import SwiftUI

@available(iOS 16.0, *)
public struct Email: ExpressibleByStringLiteral {
    var full: String?
    var name: String?
    var domain: URL?
    
    public init(name: String, domain: URL) {
        self.name = name
        self.domain = domain
        self.full = name + "@" + domain.absoluteString
    }
    
    public init(_ email: String) {
        self.init(stringLiteral: email)
    }
    
    public init(stringLiteral email: String) {
        let word = OneOrMore(.word)
        let emailPattern = Regex {
            Capture {
                ZeroOrMore {
                    word
                    "."
                }
                word
            }
            "@"
            Capture {
                word
                OneOrMore {
                    "."
                    word
                }
            }
        }
        if let match = email.firstMatch(of: emailPattern) {
            let (wholeMatch, name, domain) = match.output
            self.full = String(wholeMatch)
            self.name = String(name)
            self.domain = URL(string: String(domain))
        }
    }
}

//@propertyWrapper
//public struct Field: DynamicProperty {
//    private var value: FieldValue
//    public var wrappedValue: FieldValue {
//        get {
//            value
//        }
//        set {
//            value = newValue
//        }
//    }
//}

//@dynamicMemberLookup
//public enum FieldValue: ExpressibleByNilLiteral, ExpressibleByStringLiteral {
//
//    subscript(dynamicMember member: String) -> FieldValue? {
//
//    }
//
//    case string(string: String)
//    var string: String? {
//        if case .string(let string) = self {
//            return string
//        }
//    }
//
//    case int(int: Int)
//    var int: Int? {
//        if case .int(let int) = self {
//            return int
//        }
//    }
    
//    case int8(_ value: Int8)
//    case int16(_ value: Int16)
//    case int32(_ value: Int32)
//    case int64(_ value: Int64)
//    case uInt(_ value: UInt)
//    case uInt8(_ value: UInt8)
//    case uInt16(_ value: UInt16)
//    case uInt32(_ value: UInt32)
//    case uInt64(_ value: UInt64)
//    case double(_ value: Double)
//    case float(_ value: Float)
//    case cgFloat(_ value: CGFloat)
//    case codable(codable: Codable)
//    var codable: Codable? {
//        if case .codable(let codable) = self {
//            return codable
//        }
//    }
//
//    case bool(bool: Bool)
//    var bool: Bool? {
//        if case .bool(let bool) = self {
//            return bool
//        }
//    }
//
//    case email(email: String)
//
//    var emailString: String? {
//        if case .email(let email) = self {
//            return email
//        }
//    }
//    @available(iOS 16.0, *)
//    var email: Email? {
//        if case .email(let email) = self {
//            return Email(email)
//        }
//    }
//
//    case url(url: URL)
//    case date(date: Date)
//    case file(file: Data)
//    case relation(recordId: String?)
//    case user(userId: String?)
//}

@dynamicMemberLookup
public enum JSON {
   case intValue(Int)
   case stringValue(String)
   case arrayValue(Array<JSON>)
   case dictionaryValue(Dictionary<String, JSON>)

   var stringValue: String? {
      if case .stringValue(let str) = self {
         return str
      }
      return nil
   }

   subscript(index: Int) -> JSON? {
      if case .arrayValue(let arr) = self {
         return index < arr.count ? arr[index] : nil
      }
      return nil
   }

   subscript(key: String) -> JSON? {
      if case .dictionaryValue(let dict) = self {
         return dict[key]
      }
      return nil
   }

   subscript(dynamicMember member: String) -> JSON? {
      if case .dictionaryValue(let dict) = self {
         return dict[member]
      }
      return nil
   }
}
