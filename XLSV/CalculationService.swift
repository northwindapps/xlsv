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






// let tempStr = "10/(3-3)"//"2 ^ 1000"//"3 + ( )"//"3.1.4 + 2"//"5 + - - 2"//"2 ^ 3 ^ 2"//"10 / ( 5 - 5 )"//"-2 ^ 2"//"10 + ( 2 * ( 3 + ( 4 ^ 2 / 8 ) ) - 5 )"//"( -2 + 5 ) ^ ( 3 * 2 / 3 )"//"asin(1) * 2 / pi"//"asin(1)"//"asin(1.0000000001)"//"2(3+4)"//"-4^2"//"3 + 4 * 2 / ( 1 - 5 ) ^ 2"
// let cs = CalculationService()
// let result = cs.execute(expression:tempStr) ?? ""
// //print("final",result)

