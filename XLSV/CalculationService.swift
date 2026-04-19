//
//  calculationservice.swift
//  testFlight2
//
//  Created by yujin on 2023/10/20.
//  Copyright © 2023 yujin. All rights reserved.
//

import Foundation


class CalculationService{
        // Testcase Examples
        // let tempStr = "10/(3-3)"//"2 ^ 1000"//"3 + ( )"//"3.1.4 + 2"//"5 + - - 2"//"2 ^ 3 ^ 2"//"10 / ( 5 - 5 )"//"-2 ^ 2"//"10 + ( 2 * ( 3 + ( 4 ^ 2 / 8 ) ) - 5 )"//"( -2 + 5 ) ^ ( 3 * 2 / 3 )"//"asin(1) * 2 / pi"//"asin(1)"//"asin(1.0000000001)"//"2(3+4)"//"-4^2"//"3 + 4 * 2 / ( 1 - 5 ) ^ 2"
        // let cs = CalculationService()
        // let result = cs.execute(expression:tempStr) ?? ""
        // //print("final",result)
        static let reservedWords: [String] = [
           "pi",
           "e",
           "asin",
           "acos",
           "atan",
           "sin",
           "cos",
           "tan",
           "exp",
           "logb",
           "logd",
           "log",
           "abs",
           "sqrt",
           //These excel expressions should be transformed earlier
//           "PI()",
//           "EXP(1)",
//           "ASIN",
//           "ACOS",
//           "ATAN",
//           "SIN",
//           "COS",
//           "TAN",
//           "EXP",
//           "LOG",
//           "LOG10",
//           "LN",
//           "ABS",
//           "SQRT"
       ]

       var propertyMap: [String: Any] = [:]

       func setProperties(propertyMap: [String: Any]) {
           for (key, value) in propertyMap {
               self.propertyMap[key] = value
           }
       }

       func getProperty(key: String) -> Any? {
           return propertyMap[key]
       }
    
       func replaceConstant(source: String) -> String {
            var input = source
            input = input.replacingOccurrences(of: "pi", with: String(Double.pi))
            input = input.replacingOccurrences(of: "e", with: String(M_E))
            let regex = try! NSRegularExpression(pattern: #"(?<![a-zA-Z])e(?![a-zA-Z])"#)
            input = regex.stringByReplacingMatches(in: input, range: NSRange(input.startIndex..., in: input), withTemplate: String(M_E))

            let words = input.match(regex: #"[a-zA-Z][0-9]*\b"#) ?? []
            for word in words {
                if !CalculationService.reservedWords.contains(word) {
                    if let value = getProperty(key: word) {
                        let valueString = String(describing: value)
                        input = input.replacingOccurrences(of: word, with: valueString)
                    }
                }
            }
            return input
       }
    
    func replacePattern(input: String) -> String {
            // Define the regular expression pattern
            let pattern = "(\\d+)\\("
            // Create a regular expression object
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                // Replace matches in the input string
                let modified = regex.stringByReplacingMatches(
                    in: input,
                    options: [],
                    range: NSRange(location: 0, length: input.utf16.count),
                    withTemplate: "$1 *("
                )
                
                // Print the modified string
                //print(modified)
                return modified
            }
            return input;
    }
    
    func replacePattern2(input:String) -> String{

        // Define the regular expression pattern
        let pattern = "(\\d+)([a-zA-Z]+)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        // Replace matches in the input string
        let modifiedString = regex.stringByReplacingMatches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count), withTemplate: "$1 * $2")

        // Print the modified string
        //print(modifiedString)
        return modifiedString
    }
    
    
       func numCheck(source: String) -> String {
            let regex = try! NSRegularExpression(pattern: "[^-0123456789.]+", options: [])
            let numOnly = regex.stringByReplacingMatches(in: source, options: [], range: NSRange(source.startIndex..., in: source), withTemplate: "")
            return numOnly
       }

       func extractMostNestedBraces(input: String) -> String? {
            var depth = 0
            var currentDepth = 0
            var startIndex = -1
            var endIndex = -1

            for (index, character) in input.enumerated() {
                if character == "(" {
                    currentDepth += 1
                    if currentDepth > depth {
                        depth = currentDepth
                        startIndex = index
                    }
                } else if character == ")" {
                    if currentDepth == depth {
                        endIndex = index
                        break
                    }
                    currentDepth -= 1
                }
            }

            if startIndex != -1, endIndex != -1 {
                let start = input.index(input.startIndex, offsetBy: startIndex + 1)
                let end = input.index(input.startIndex, offsetBy: endIndex)
                return String(input[start..<end])
            }
            
           return nil
            
      }
    
    //   func isFloat(_ str: String) -> Bool {
    //         let floatRegex = #"^-?\d+(\.\d+)?$"#
    //         let range = NSRange(str.startIndex..<str.endIndex, in: str)
    //         return NSPredicate(format: "SELF MATCHES %@", floatRegex).evaluate(with: str)
    //   }

    func isFloat(_ str: String) -> Bool {
    let pattern = "^-?\\d+(\\.\\d+)?$"
    // NSRegularExpression over NSPredicate
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
    
    let range = NSRange(location: 0, length: str.utf16.count)
    return regex.firstMatch(in: str, options: [], range: range) != nil
}

    func areAllFloats(_ item: String) -> Bool {
        return Float(item) != nil
    }

    func containsAlphabetChars(_ str: String) -> Bool {
        let lettersSet = CharacterSet.letters
        return str.rangeOfCharacter(from: lettersSet) != nil
    }


    func radianToString(_ degrees: Double) -> String {
        //let radians = degrees * (.pi / 180.0)
        return String(degrees)
    }

    
    func execute(expression: String) -> String? {
            var tempStr: String? = nil
            let charset: Set<Character> = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            var isInfinity = false;
            let ERROR = "error";
            
            if expression.contains { charset.contains($0) } {
                return nil
            } else {
                tempStr = expression.replacingOccurrences(of: "=", with: "")
            }
            
            if let firstChar = tempStr?.first {
                if firstChar == "^" || firstChar == "/" || firstChar == "*"  || firstChar == "+" {
                    return nil
                }
            }
            
            let MAXIMUM_LOOP_NUM = 50
            var loopCounter = MAXIMUM_LOOP_NUM
            
            // PREPARATION
            tempStr = replaceConstant(source: tempStr!)
            tempStr = replacePattern(input: tempStr!)
            tempStr = replacePattern2(input: tempStr!)
            
            
            
            // Comma Free
            tempStr = tempStr?.replacingOccurrences(of: ",", with: "")
            
            if !(tempStr?.contains("(") ?? false) {
                loopCounter = 50
                // No braces
                if let unwrappedTempStr = tempStr, !isFloat(unwrappedTempStr) {
                    while loopCounter > 0 {
                        tempStr = scientificOperation(tempStr!)
                        tempStr = basicOperation(source: tempStr!)
                        tempStr = slashDotPowerPlusCase(tempStr!)
                        //print("tempStr",tempStr)
                        if tempStr == ERROR{
                            isInfinity = true;
                        }
                        if isFloat(tempStr ?? "") {
                            loopCounter = 0
                        }
                        loopCounter -= 1
                    }
                }
            }
            
            while loopCounter > 0 {
                tempStr = tempStr?.replacingOccurrences(of: " ", with: "")
                if let match = extractMostNestedBraces(input: tempStr ?? "") {
                    let cloned = "(\(match))"
                    var result: String? = nil
                    var j = 10
                    //print("match",cloned)
                    for i in 0..<cloned.count {
                        if containsAlphabetChars(cloned) {
                            result = scientificOperation(cloned.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: ""))
                            while j > 0 {
                                if let unwrappedResult = result, isFloat(unwrappedResult) {
                                    tempStr = tempStr?.replacingOccurrences(of: cloned, with: unwrappedResult)
                                    j = 0
                                } else {
                                    if containsAlphabetChars(result ?? "") {
                                        result = scientificOperation(result ?? "")
                                    } else {
                                        result = basicOperation(source: result ?? "")
                                        tempStr = slashDotPowerPlusCase(tempStr!)
                                        if result == ERROR{
                                            isInfinity = true;
                                        }
                                    }
                                }
                                j -= 1
                            }
                        } else {
                            var k = 50
                            var basicExp = cloned.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                            //print("basicExp",basicExp)
                            while k > 0 {
                                result = basicOperation(source: basicExp)
                                tempStr = slashDotPowerPlusCase(tempStr!)
                                //print("result",result)
                                if result == ERROR{
                                    isInfinity = true;
                                }
                                if isFloat(result ?? "") {
                                    k = 0
                                }
                                basicExp = result ?? ""
                                k -= 1
                            }
                            
                            if let unwrappedResult = result {
                                let ptn = cloned
                                tempStr = tempStr?.replacingOccurrences(of: ptn, with: unwrappedResult)
                                //print("unwrappedResult",tempStr)
                            }
                        }
                    }
                }
                
                let match = extractMostNestedBraces(input: tempStr ?? "")
                if match == nil{
                    tempStr = scientificOperation(tempStr ?? "")
                    tempStr = basicOperation(source: tempStr ?? "")
                    tempStr = slashDotPowerPlusCase(tempStr!)
                    if tempStr == ERROR{
                        isInfinity = true;
                    }
                }
                if isInfinity{
                    tempStr = "nil";
                }
                
                
                if isFloat(tempStr ?? "") {
                    loopCounter = 0
                }
                loopCounter -= 1
            }
            
            if tempStr ?? "" == "nil"{
              return "error"
            }
            
            return isFloat(tempStr ?? "") ? tempStr : nil
        }
    
    func replaceSquared(_ str: String) -> String {
        let pattern = #"(-?\d+(\.\d+)?)\^2"#
        let regex = try! NSRegularExpression(pattern: pattern)
        
        var result = str
        let matches = regex.matches(in: str, range: NSRange(str.startIndex..., in: str)).reversed()
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: str) {
                let numberStr = String(str[range])
                if let value = Double(numberStr) {
                    let squared = value * value
                    if let fullRange = Range(match.range, in: result) {
                        result.replaceSubrange(fullRange, with: "\(squared)")
                    }
                }
            }
        }
        
        return result
    }
    
    func basicOperation(source: String) -> String {
        var resultvalue = Decimal(0.0)
        var input = source
        var isInfinity = false;
        input = input.replacingOccurrences(of: "——", with: "+")
        input = input.replacingOccurrences(of: "--", with: "+")
        input = input.replacingOccurrences(of: "-+", with: " -")
        input = input.replacingOccurrences(of: "+", with: " + ")
        input = input.replacingOccurrences(of: "/", with: " / ")
        input = input.replacingOccurrences(of: "-", with: " -")
        input = input.replacingOccurrences(of: "–", with: " -")
        input = input.replacingOccurrences(of: "*", with: " * ")
        input = input.replacingOccurrences(of: "^", with: " ^ ")
        
        var elements = input.split(separator: " ")
        elements = elements.filter { item in
            return item != "nil" && item != "" && item != "nil"
        }
        var checkings = Array(elements)
        checkings = checkings.filter { item in
            return item != "+"
        }
        
        
        if checkings.allSatisfy({ isFloat(String($0)) }) {
            elements = checkings
            if elements.count > 1 {
                for i in 1..<elements.count {
                    if isFloat(String(elements[i - 1])) && isFloat(String(elements[i])) {
                        let a = Decimal(string: String(elements[i-1])) ?? Decimal(0.0)
                        let b = Decimal(string: String(elements[i])) ?? Decimal(0.0)
                        let result = a + b
                        elements[i] = "\(result)"
                        elements[i - 1] = "nil"
                    }
                }
            }
            elements = elements.filter { item in
                return item != "nil"
            }
            return elements.joined(separator: "")
        } else {
            if elements.contains("^") {
                for i in 1..<elements.count {
                    //print("element",elements[i])
                    
                    if elements[i] == "^" && i - 1 >= 0 && isFloat(String(elements[i - 1])) && i + 1 < elements.count && isFloat(String(elements[i + 1])) {
                        if elements[i - 1] == "0.0" || elements[i - 1] == "0"{
                            elements[i + 1] = "0.0"
                            elements[i - 1] = "nil"
                            elements[i] = "+"
                        }else{
                            if elements[i-1].hasPrefix("-") && i-2>0 && elements[i-2].hasPrefix("-") {
                                let base = Double(elements[i-1].dropFirst())!
                                let exp = Double(elements[i+1])!
                                let result = pow(base, exp) // apply minus AFTER power
                                elements[i + 1] = "\(result)"
                                elements[i - 1] = "nil"
                                elements[i] = "+"
                            }else if elements[i-1].hasPrefix("-") {
                                let base = Double(elements[i-1].dropFirst())!
                                let exp = Double(elements[i+1])!
                                let result = -pow(base, exp) // apply minus AFTER power
                                elements[i + 1] = "\(result)"
                                elements[i - 1] = "nil"
                                elements[i] = "+"
                            }else{
                                let a = Double(elements[i-1])
                                let b = Double(elements[i+1])
                                let cd = Decimal(string: String(elements[i-1])) ?? Decimal(0.0)
                                if cd.isEqual(to: Decimal(0.0)) {
                                    isInfinity = true;
                                }
                                //let c = pow(a as Decimal, b!)
                                let c = pow(a!, b!)
                                let result = Decimal(c)
                                elements[i + 1] = "\(result)"
                                elements[i - 1] = "nil"
                                elements[i] = "+"
                            }
                        }
                    }
                }
            } else {
                for i in 1..<elements.count {
                    if elements[i] == "*" && i - 1 >= 0 && isFloat(String(elements[i - 1])) && i + 1 < elements.count && isFloat(String(elements[i + 1])) {
                        let a = Decimal(string: String(elements[i - 1])) ?? Decimal(0.0)
                        let b = Decimal(string: String(elements[i + 1])) ?? Decimal(0.0)
                        resultvalue = a * b
                        elements[i + 1] = "\(resultvalue)"
                        elements[i - 1] = "nil"
                        elements[i] = "+"
                    }

                    if elements[i] == "/" && isFloat(String(elements[i - 1])) && isFloat(String(elements[i + 1])) {
                        
                        if elements[i+1] == "0" || elements[i+1] == "0.0"{
                            elements[i - 1] = "nil"
                            elements[i] = "+"
                            elements[i + 1] = "nil"
                            isInfinity = true;
                        }else{
                            let a = Decimal(string: String(elements[i - 1])) ?? Decimal(0.0)
                            let b = Decimal(string: String(elements[i + 1])) ?? Decimal(0.0)
                            if b.isEqual(to: Decimal(0.0)) {
                                elements[i - 1] = "nil"
                                elements[i] = "+"
                                elements[i + 1] = "nil"
                                isInfinity = true;
                            } else {
                                resultvalue = a / b
                                elements[i + 1] = "\(resultvalue)"
                                elements[i - 1] = "nil"
                                elements[i] = "+"
                            }
                        }
                    }
                }
            }
            if(isInfinity){
                return "error"
            }
            elements = elements.filter { item in
                return item != "nil"
            }
            //print("joined",elements.joined(separator: ""))
            return elements.joined(separator: "")
        }
    }

    func slashDotPowerPlusCase(_ source: String) -> String {
        var input = source
            input = input.replacingOccurrences(of: "/+", with: "/")
            input = input.replacingOccurrences(of: "*+", with: "*")
            input = input.replacingOccurrences(of: "^+", with: "^")
            input = input.replacingOccurrences(of: "-+", with: "-")
            input = input.replacingOccurrences(of: "--", with: "+")
        
        return input
    }
    
    func scientificOperation(_ source: String) -> String {
            var input = source
            input = input.replacingOccurrences(of: "(", with: "")
            input = input.replacingOccurrences(of: ")", with: "")
            
        if let elements = input.match(regex: #"[a-z]+\s*-?\d+(\.\d+)?"#) {
                for element in elements {
                    if element.contains("asin") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "asin", with: "")),
                           let arg = Decimal(string:radianToString(exp.doubleValue)) {
                            let val = arg.doubleValue
                            if val >= -1.0 && val <= 1.0 {
                                let resultValue = Decimal(asin(val))
                                input = input.replacingOccurrences(of: element, with: resultValue.description)
                            } else {
                                input = input.replacingOccurrences(of: element, with: "NaN")
                            }
                        }
                    }
                    if element.contains("acos") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "acos", with: "")),
                           let arg = Decimal(string:radianToString(exp.doubleValue)) {
                            let val = arg.doubleValue
                            if val >= -1.0 && val <= 1.0 {
                                let resultValue = Decimal(acos(val))
                                input = input.replacingOccurrences(of: element, with: resultValue.description)
                            } else {
                                input = input.replacingOccurrences(of: element, with: "NaN")
                            }
                        }
                    }
                    if element.contains("atan") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "atan", with: "")),
                           let arg = Decimal(string:radianToString(exp.doubleValue)) {
                            let resultValue = Decimal(atan(arg.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("sin") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "sin", with: "")),
                           let arg = Decimal(string:radianToString(exp.doubleValue)) {
                            let resultValue = Decimal(sin(arg.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("cos") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "cos", with: "")),
                           let arg = Decimal(string:radianToString(exp.doubleValue)) {
                            let resultValue = Decimal(cos(arg.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("tan") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "tan", with: "")),
                           let arg = Decimal(string:radianToString(exp.doubleValue)) {
                            let resultValue = Decimal(tan(arg.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("sqrt") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "sqrt", with: "")) {
                            let resultValue = Decimal(sqrt(exp.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("abs") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "abs", with: "")) {
                            let resultValue = abs(exp)
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("exp") {
                        if let exps = Decimal(string: element.replacingOccurrences(of: "exp", with: "")) {
                            let resultValue = Decimal(exp(exps.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("logd") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "logd", with: "")) {
                            let val = exp.doubleValue
                                    
                            if val > 0 {
                                let resultValue = Decimal(log10(val))
                                input = input.replacingOccurrences(of: element, with: resultValue.description)
                            } else {
                                input = input.replacingOccurrences(of: element, with: "NaN")
                            }
                        }
                    }
                    if element.contains("logb") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "logb", with: "")) {
                            let resultValue = Decimal(log2(NSDecimalNumber(decimal:exp).doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("log") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "log", with: "")) {
                            let resultValue = Decimal(log(exp.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                }
            }
            return input
        }

    
    
    
}
extension String {
    func match(regex: String) -> [String]? {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let matches = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return matches.map { nsString.substring(with: $0.range) }
        } catch {
            return nil
        }
    }
}
extension Decimal {
    var doubleValue:Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }
}


// CalculationService.swift
// Swift counterpart of the TypeScript math expression parser
// MARK: - AST Node Types

protocol ASTNode {
    var type: String { get }
}

struct BinaryOp: ASTNode {
    let type = "BinaryOp"
    let left: ASTNode
    let right: ASTNode
    let operation: String
}

struct FunctionCall: ASTNode {
    let type = "FunctionCall"
    let name: String
    let args: [ASTNode]
}

struct Variable: ASTNode {
    let type = "Variable"
    let name: String
}

struct NumberLiteral: ASTNode {
    let type = "NumberLiteral"
    let value: Double
}

struct UnaryOp: ASTNode {
    let type = "UnaryOp"
    let operation: String
    let operand: ASTNode
}

// MARK: - Math Parser

class MathParser {
    private let input: String
    private var pos: String.Index

    init(input: String) {
        // Remove spaces for simplicity
        self.input = input.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        self.pos = self.input.startIndex
    }

    func parse() throws -> ASTNode {
        return try parseExpression()
    }

    private func parseExpression() throws -> ASTNode {
        var left = try parseTerm()
        while peek() == "+" || peek() == "-" {
            let op = String(consume())
            let right = try parseTerm()
            left = BinaryOp(left: left, right: right, operation: op)
        }
        return left
    }

    private func parseTerm() throws -> ASTNode {
        var left = try parseFactor()
        while peek() == "*" || peek() == "/" || peek() == "%" {
            let op = String(consume())
            let right = try parseFactor()
            left = BinaryOp(left: left, right: right, operation: op)
        }
        return left
    }

    private func parseFactor() throws -> ASTNode {
        return try parsePower()
    }

    private func parseAtom() throws -> ASTNode {
        var sign = 1
        if peek() == "-" {
            consume()
            sign = -1
        } else if peek() == "+" {
            consume()
        }

        var atom: ASTNode
        if peek() == "(" {
            consume() // "("
            atom = try parseExpression()
            try expect(")")
        } else if isDigit(String(peek())) || peek() == "." {
            atom = try parseNumber()
        } else if isLetter(String(peek())) {
            let name = try parseIdentifier()
            if peek() == "(" {
                consume() // "("
                var args: [ASTNode] = []
                if peek() != ")" {
                    args.append(try parseExpression())
                    while peek() == "," {
                        consume()
                        args.append(try parseExpression())
                    }
                }
                try expect(")")
                atom = FunctionCall(name: name, args: args)
            } else {
                atom = Variable(name: name)
            }
        } else {
            throw ParseError.unexpectedCharacter(String(peek()))
        }

        if sign == -1 {
            return UnaryOp(operation: "-", operand: atom)
        }
        return atom
    }

    private func parsePower() throws -> ASTNode {
        var left = try parseAtom()
        if peek() == "^" {
            consume()
            let right = try parsePower()
            return BinaryOp(left: left, right: right, operation: "^")
        }
        return left
    }

    private func parseNumber() throws -> NumberLiteral {
        var num = ""
        while pos < input.endIndex && (isDigit(String(peek())) || peek() == ".") {
            num.append(consume())
        }
        guard let value = Double(num) else {
            throw ParseError.invalidNumber(num)
        }
        return NumberLiteral(value: value)
    }

    private func parseIdentifier() throws -> String {
        var id = ""
        if isLetter(String(peek())) || peek() == "_" {
            id.append(consume())
            while pos < input.endIndex && (isLetter(String(peek())) || isDigit(String(peek())) || peek() == "_") {
                id.append(consume())
            }
        }
        return id
    }

    private func peek() -> Character {
        return pos < input.endIndex ? input[pos] : "\0"
    }

    private func consume() -> Character {
        let char = peek()
        pos = input.index(after: pos)
        return char
    }

    private func expect(_ char: Character) throws {
        if peek() != char {
            throw ParseError.expectedCharacter(String(char), got: String(peek()))
        }
        consume()
    }

    private func isDigit(_ char: String) -> Bool {
        return char.range(of: "\\d", options: .regularExpression) != nil
    }

    private func isLetter(_ char: String) -> Bool {
        return char.range(of: "[a-zA-Z]", options: .regularExpression) != nil
    }
}

// MARK: - Errors

enum ParseError: Error {
    case unexpectedCharacter(String)
    case invalidNumber(String)
    case expectedCharacter(String, got: String)
}

enum EvaluationError: Error, CustomStringConvertible {
    case divisionByZero
    case moduloByZero
    case domainError(String)
    case unknownVariable(String)
    case unknownFunction(String)
    case invalidBinaryOperator(String)
    case invalidArgumentCount(String)
    case undefinedOperation(String)

    var description: String {
        switch self {
        case .divisionByZero:
            return "Division by zero"
        case .moduloByZero:
            return "Modulo by zero"
        case .domainError(let message):
            return message
        case .unknownVariable(let name):
            return "Unknown variable: \(name)"
        case .unknownFunction(let name):
            return "Unknown function: \(name)"
        case .invalidBinaryOperator(let op):
            return "Invalid binary operator: \(op)"
        case .invalidArgumentCount(let message):
            return message
        case .undefinedOperation(let message):
            return message
        }
    }
}

// MARK: - AST Utilities

func printCustomAST(_ node: ASTNode, indent: String = "") {
    print("\(indent)\(node.type)")
    if let bin = node as? BinaryOp {
        print("\(indent)  Operator: \(bin.operation)")
        printCustomAST(bin.left, indent: indent + "  ")
        printCustomAST(bin.right, indent: indent + "  ")
    } else if let un = node as? UnaryOp {
        print("\(indent)  Operator: \(un.operation)")
        printCustomAST(un.operand, indent: indent + "  ")
    } else if let function = node as? FunctionCall {
        print("\(indent)  Name: \(function.name)")
        for (i, arg) in function.args.enumerated() {
            print("\(indent)  Arg \(i):")
            printCustomAST(arg, indent: indent + "    ")
        }
    } else if let variable = node as? Variable {
        print("\(indent)  Name: \(variable.name)")
    } else if let number = node as? NumberLiteral {
        print("\(indent)  Value: \(number.value)")
    }
}

func toRPN(_ node: ASTNode) -> String {
    if let bin = node as? BinaryOp {
        return "\(toRPN(bin.left)) \(toRPN(bin.right)) \(bin.operation)"
    } else if let un = node as? UnaryOp {
        return "\(toRPN(un.operand)) \(un.operation)"
    } else if let function = node as? FunctionCall {
        let args = function.args.map { toRPN($0) }.joined(separator: " ")
        return "\(args) \(function.name)"
    } else if let variable = node as? Variable {
        return variable.name
    } else if let number = node as? NumberLiteral {
        return String(number.value)
    }
    return ""
}

// MARK: - Calculation Service

final class ASTCalculationService: Sendable {

    func parseExpression(_ expression: String) -> ASTNode? {
        let parser = MathParser(input: expression)
        do {
            return try parser.parse()
        } catch {
            print("Parse error: \(error)")
            return nil
        }
    }

    func parseExpressionThrowing(_ expression: String) throws -> ASTNode {
        let parser = MathParser(input: expression)
        return try parser.parse()
    }

    func evaluate(_ expression: String) throws -> Double {
        let ast = try parseExpressionThrowing(expression)
        return try evaluate(ast)
    }

    func evaluate(_ node: ASTNode) throws -> Double {
        if let bin = node as? BinaryOp {
            return try evaluateBinaryOp(bin)
        } else if let un = node as? UnaryOp {
            return try evaluateUnaryOp(un)
        } else if let function = node as? FunctionCall {
            return try evaluateFunctionCall(function)
        } else if let variable = node as? Variable {
            return try evaluateVariable(variable)
        } else if let number = node as? NumberLiteral {
            return number.value
        }
        throw EvaluationError.undefinedOperation("Unsupported AST node: \(node.type)")
    }

    private func evaluateBinaryOp(_ bin: BinaryOp) throws -> Double {
        let leftValue = try evaluate(bin.left)
        let rightValue = try evaluate(bin.right)

        switch bin.operation {
        case "+":
            return leftValue + rightValue
        case "-":
            return leftValue - rightValue
        case "*":
            return leftValue * rightValue
        case "/":
            if rightValue == 0 {
                throw EvaluationError.divisionByZero
            }
            return leftValue / rightValue
        case "%":
            if rightValue == 0 {
                throw EvaluationError.moduloByZero
            }
            return leftValue.truncatingRemainder(dividingBy: rightValue)
        case "^":
            let result = pow(leftValue, rightValue)
            if result.isNaN {
                throw EvaluationError.domainError("\(leftValue)^\(rightValue) is undefined")
            }
            return result
        default:
            throw EvaluationError.invalidBinaryOperator(bin.operation)
        }
    }

    private func evaluateUnaryOp(_ un: UnaryOp) throws -> Double {
        let value = try evaluate(un.operand)
        switch un.operation {
        case "-":
            return -value
        case "+":
            return value
        default:
            throw EvaluationError.invalidBinaryOperator(un.operation)
        }
    }

    private func evaluateFunctionCall(_ function: FunctionCall) throws -> Double {
        let args = try function.args.map { try evaluate($0) }
        switch function.name.lowercased() {
        case "abs":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("abs() requires 1 argument")
            }
            return abs(args[0])
        case "sqrt":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("sqrt() requires 1 argument")
            }
            if args[0] < 0 {
                throw EvaluationError.domainError("sqrt domain error: argument \(args[0]) must be non-negative")
            }
            return sqrt(args[0])
        case "sin":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("sin() requires 1 argument")
            }
            return sin(args[0])
        case "cos":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("cos() requires 1 argument")
            }
            return cos(args[0])
        case "tan":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("tan() requires 1 argument")
            }
            return tan(args[0])
        case "asin":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("asin() requires 1 argument")
            }
            if args[0] < -1 || args[0] > 1 {
                throw EvaluationError.domainError("asin domain error: argument \(args[0]) must be in [-1, 1]")
            }
            return asin(args[0])
        case "acos":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("acos() requires 1 argument")
            }
            if args[0] < -1 || args[0] > 1 {
                throw EvaluationError.domainError("acos domain error: argument \(args[0]) must be in [-1, 1]")
            }
            return acos(args[0])
        case "atan":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("atan() requires 1 argument")
            }
            return atan(args[0])
        case "log":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("log() requires 1 argument")
            }
            if args[0] <= 0 {
                throw EvaluationError.domainError("log domain error: argument \(args[0]) must be positive")
            }
            return log(args[0])
        case "log10":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("log10() requires 1 argument")
            }
            if args[0] <= 0 {
                throw EvaluationError.domainError("log10 domain error: argument \(args[0]) must be positive")
            }
            return log10(args[0])
        case "log2":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("log2() requires 1 argument")
            }
            if args[0] <= 0 {
                throw EvaluationError.domainError("log2 domain error: argument \(args[0]) must be positive")
            }
            return log2(args[0])
        case "exp":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("exp() requires 1 argument")
            }
            return exp(args[0])
        case "floor":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("floor() requires 1 argument")
            }
            return floor(args[0])
        case "ceil":
            guard args.count == 1 else {
                throw EvaluationError.invalidArgumentCount("ceil() requires 1 argument")
            }
            return ceil(args[0])
        case "max":
            guard !args.isEmpty else {
                throw EvaluationError.invalidArgumentCount("max() requires at least 1 argument")
            }
            return args.max() ?? 0
        case "min":
            guard !args.isEmpty else {
                throw EvaluationError.invalidArgumentCount("min() requires at least 1 argument")
            }
            return args.min() ?? 0
        default:
            throw EvaluationError.unknownFunction(function.name)
        }
    }

    private func evaluateVariable(_ variable: Variable) throws -> Double {
        switch variable.name.lowercased() {
        case "pi":
            return Double.pi
        case "e":
            return exp(1)
        default:
            throw EvaluationError.unknownVariable(variable.name)
        }
    }

    func printAST(for expression: String) {
        guard let ast = parseExpression(expression) else { return }

        print("=== Expression: \(expression) ===")
        print("Custom Math AST:")
        printCustomAST(ast)

        print("\nReverse Polish Notation (RPN):")
        print(toRPN(ast))
    }

    // Test expressions (equivalent to TypeScript version)
    func runTests() {
        let testExpressions = [
            "(-5)^2 + 7^-2.5 - 3*4/2 + pi",
            "sqrt(16) + abs(-5)",
            "sin(0) + cos(0)",
            "floor(3.7) + ceil(3.2)",
            "(2+3)*(4-1)",
            "log10(100) + log2(8)",
            "max(5,10,3) - min(5,10,3)",
            "sqrt((3^2)+(4^2))",
            "(pi/2)*180",
            "log10(1.0^2-1.0^2)",
            "-5^2+25",
            "asin(1)",
            "acos(-1)",
            "17%5",
            "10%3",
            "7%7"
        ]

        for expression in testExpressions {
            printAST(for: expression)
            do {
                let result = try evaluate(expression)
                print("\nEvaluated Result:")
                print(result)
            } catch {
                print("\nEvaluated Result:")
                print("Error: \(error)")
            }
            print("\n")
        }
    }
}

// MARK: - Usage Example
/*
 // In your Swift code:
 let service = CalculationService()
 service.runTests()

 // Or parse individual expressions:
 if let ast = CalculationService.parseExpression("2+3*4") {
     print("Parsed successfully!")
     CalculationService.printAST(for: "2+3*4")
 }
 */
