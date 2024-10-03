//
//  Filter.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/25/24.
//

import Foundation

@freestanding(expression)
public macro Filter<each Input>(
    _ body: (repeat each Input) -> Bool
) -> Filter = #externalMacro(module: "PocketBaseMacros", type: "Filter")

public struct Filter: Codable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: These symbols represent the operators in the PocketBase filter string that don't exist as native Swift operators
infix operator ~: ComparisonPrecedence
func ~ <T> (lhs: T, rhs: T) -> Bool { false }

infix operator !~: ComparisonPrecedence
func !~ <T> (lhs: T, rhs: T) -> Bool { false }

infix operator ?=: ComparisonPrecedence
func ?= <T> (lhs: T, rhs: T) -> Bool { false }

infix operator ?!=: ComparisonPrecedence
func ?!= <T> (lhs: T, rhs: T) -> Bool { false }

infix operator ?>: ComparisonPrecedence
func ?> <T> (lhs: T, rhs: T) -> Bool { false }

infix operator ?>=: ComparisonPrecedence
func ?>= <T> (lhs: T, rhs: T) -> Bool { false }

infix operator ?<: ComparisonPrecedence
func ?< <T> (lhs: T, rhs: T) -> Bool { false }

infix operator ?<=: ComparisonPrecedence
func ?<= <T> (lhs: T, rhs: T) -> Bool { false }

infix operator ?~: ComparisonPrecedence
func ?~ <T> (lhs: T, rhs: T) -> Bool { false }

infix operator ?!~: ComparisonPrecedence
func ?!~ <T> (lhs: T, rhs: T) -> Bool { false }
