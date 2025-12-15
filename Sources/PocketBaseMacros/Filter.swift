//
//  Filter.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/25/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

public struct Filter: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        #if os(macOS) && swift(<5.5)
        let arguments = node.argumentList
        #else
        let arguments = node.arguments
        #endif
        guard
            let operationClosure = arguments.first?
                .expression
                .as(ClosureExprSyntax.self)
        else {
            throw FilterError.missingClosure
        }
        guard
            let topLevelInfixOperator = operationClosure.statements.first?
                .item
                .as(InfixOperatorExprSyntax.self)
        else {
            throw FilterError.missingTopLevelInfixOperator
        }
        return "Filter(rawValue: \"(\(try parse(topLevelInfixOperator)))\")"
    }

    static func parse(_ infixOperator: InfixOperatorExprSyntax) throws -> ExprSyntax {
        let leftOperandExpression = try unwrap(operand: infixOperator.leftOperand)
        guard
            var binaryOperator = infixOperator.operator.as(BinaryOperatorExprSyntax.self)?.operator.trimmed.text
        else {
            throw FilterError.invalidOperator
        }
        if binaryOperator == "==" {
            binaryOperator = "="
        }
        let rightOperand = try unwrap(operand: infixOperator.rightOperand)
        return "\(leftOperandExpression)\(raw: binaryOperator)\(rightOperand)"
    }

    static func unwrap(operand: ExprSyntax) throws -> ExprSyntax {
        var _operand: ExprSyntax = ""
        if
            let operand = operand.as(InfixOperatorExprSyntax.self)
        {
            _operand = try parse(operand)
        } else if
            let name = operand.as(MemberAccessExprSyntax.self)?.declName.trimmed
        {
            _operand = "\(name)"
        } else if
            let operand = operand.as(StringLiteralExprSyntax.self)
        {
            _operand = "'\(operand.segments)'"
        } else {
            throw FilterError.invalidType
        }
        return _operand.trimmed
    }
}

enum FilterError: Error {
    case missingClosure
    case missingTopLevelInfixOperator
    case invalidOperator
    case invalidType
}
