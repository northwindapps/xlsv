//
//  calculationservice.swift
//  testFlight2
//
//  Created by yujin on 2023/10/20.
//  Copyright © 2023 yujin. All rights reserved.
//

import Foundation


class CalculationService{
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
           "sqrt"
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
                print(modified)
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
        print(modifiedString)
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
    
      func isFloat(_ str: String) -> Bool {
            let floatRegex = #"^-?\d+(\.\d+)?$"#
            let range = NSRange(str.startIndex..<str.endIndex, in: str)
            return NSPredicate(format: "SELF MATCHES %@", floatRegex).evaluate(with: str)
      }

      func areAllFloats(_ item: String) -> Bool {
            return Float(item) != nil
      }

    func containsAlphabetChars(_ str: String) -> Bool {
        let lettersSet = CharacterSet.letters
        return str.rangeOfCharacter(from: lettersSet) != nil
    }


    func degreesToRadians(_ degrees: Double) -> String {
        let radians = degrees * (.pi / 180.0)
        return String(radians)
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
                            while k > 0 {
                                result = basicOperation(source: basicExp)
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
                            }
                        }
                    }
                }
                
                let match = extractMostNestedBraces(input: tempStr ?? "")
                if match == nil{
                    tempStr = scientificOperation(tempStr ?? "")
                    tempStr = basicOperation(source: tempStr ?? "")
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
            
            return isFloat(tempStr ?? "") ? tempStr : nil
        }
    
    func basicOperation(source: String) -> String {
        var resultvalue = Decimal(0.0)
        var input = source
        var isInfinity = false;
        input = input.replacingOccurrences(of: "--", with: "+")
        input = input.replacingOccurrences(of: "+", with: " + ")
        input = input.replacingOccurrences(of: "/", with: " / ")
        input = input.replacingOccurrences(of: "-", with: " -")
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
                    if elements[i] == "^" && i - 1 >= 0 && isFloat(String(elements[i - 1])) && i + 1 < elements.count && isFloat(String(elements[i + 1])) {
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
            if(isInfinity){
                return "error"
            }
            elements = elements.filter { item in
                return item != "nil"
            }
            return elements.joined(separator: "")
        }
    }
    
    func scientificOperation(_ source: String) -> String {
            var input = source
            input = input.replacingOccurrences(of: "(", with: "")
            input = input.replacingOccurrences(of: ")", with: "")
            
        if let elements = input.match(regex: #"[a-z]+\s*-?\d+(\.\d+)?"#) {
                for element in elements {
                    if element.contains("asin") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "asin", with: "")),
                           let arg = Decimal(string:degreesToRadians(exp.doubleValue)) {
                            let resultValue = Decimal(asin(arg.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("acos") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "acos", with: "")),
                           let arg = Decimal(string:degreesToRadians(exp.doubleValue)) {
                            let resultValue = Decimal(acos(arg.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("atan") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "atan", with: "")),
                           let arg = Decimal(string:degreesToRadians(exp.doubleValue)) {
                            let resultValue = Decimal(atan(arg.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("sin") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "sin", with: "")),
                           let arg = Decimal(string:degreesToRadians(exp.doubleValue)) {
                            let resultValue = Decimal(sin(arg.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("cos") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "cos", with: "")),
                           let arg = Decimal(string:degreesToRadians(exp.doubleValue)) {
                            let resultValue = Decimal(cos(arg.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
                        }
                    }
                    if element.contains("tan") {
                        if let exp = Decimal(string: element.replacingOccurrences(of: "tan", with: "")),
                           let arg = Decimal(string:degreesToRadians(exp.doubleValue)) {
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
                            let resultValue = Decimal(log10(exp.doubleValue))
                            input = input.replacingOccurrences(of: element, with: resultValue.description)
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

