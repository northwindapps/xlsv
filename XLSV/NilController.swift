//
//  NilController.swift
//  Ecalculator
//
//  Created by 矢野悠人 on 2017/02/05.
//  Copyright © 2017年 yumiya. All rights reserved.
//
import UIKit
import Foundation
class NilController {
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    
    func REPLACE_WITH_CONSTANT(source:String)->(String){//sin(PI/4)
        var input = source
        
        input = input.replacingOccurrences(of: "pi", with: String(Double.pi))
        input = input.replacingOccurrences(of: "e", with: String(M_E))
        
        
        return input
    }
    
    
    func BRACKET_INDEX(source:String,bracketsize:Int)->(Int){
        
        var input = source//sin60,sqrt4,log
        
        
        
        input = input.replacingOccurrences(of: "(", with: " ( ")
        input = input.replacingOccurrences(of: ")", with: " ) ")//これで中は数字だけ
        
        let elements : [String] = input.split{$0 == " "}.map(String.init)
        
        
        var bracketcount = 0
        var calcuationstart = -1
        
        
        
        for i in 0..<elements.count {
            
            if elements[i] == "(" {
                bracketcount += 1
                
                
                //最深部だから次はカッコはない
                if bracketcount == bracketsize {
                    
                    calcuationstart = i + 1
                    
                    bracketcount += 1
                }
            }
            
        }

        
        return calcuationstart//if -1 then over
    }
    
    func NUMCHECK(source:String)->(String){
        
        let numonly = source.trimmingCharacters(in: CharacterSet(charactersIn: "-0123456789").inverted)
        return numonly
    }
    
    func CALCULATION_OPERATION(source:String)->(String){
        //1+3/4*
        
        //http://stackoverflow.com/questions/34540332/how-to-get-the-first-character-of-each-word-in-a-string
        let firstc = NUMCHECK(source: String(describing: source.first))
        let lastc = NUMCHECK(source: String(describing: source.last))
        
        
        
        if firstc != "" && lastc != ""{
            
            //("enter")
            
            var resultvalue = NSDecimalNumber(string: "0.0")
            
            var input = source
            
            
            input = input.replacingOccurrences(of: "--", with: "+")
            input = input.replacingOccurrences(of: "+", with: " ")
            input = input.replacingOccurrences(of: "/", with: " / ")
            input = input.replacingOccurrences(of: "-", with: " -")
            input = input.replacingOccurrences(of: "*", with: " * ")
            input = input.replacingOccurrences(of: "^", with: " ^ ")
            
            
            
            
            var elements : [String] = input.split{$0 == " "}.map(String.init)
            
            
            
            for i in 0..<elements.count {
                
                if (elements[i] == "^" && Double(elements[i-1]) != nil && Double(elements[i+1]) != nil) {
                    
                    if Double(elements[i+1]) == nil{
                        
                        elements[i+1] = "error"
                        
                        elements[i-1] = "nil"
                        elements[i] = "nil"
                        //error
                        
                    }
                    else{
                        
                        let a = Double(elements[i-1])
                        let b = Double(elements[i+1])
                        
                        //let c = pow(a as Decimal, b!)
                        var c = pow(a!, b!)
                        
                        c = c*100000
                        
                        c = round(c)/100000
                        
                        
                        elements[i+1] = String(describing: c)
                        
                        elements[i-1] = "nil"
                        elements[i] = "nil"
                        
                    }
                    
                }
            }
            
            elements = elements.filter{$0 != "nil"}
            
            
            for i in 0..<elements.count {
                
                
                if elements[i] == "*" && Double(elements[i-1]) != nil && Double(elements[i+1]) != nil {
                    //("*")
                    
                    let a = NSDecimalNumber(string: elements[i-1])
                    let b = NSDecimalNumber(string: elements[i+1])
                    
                    resultvalue = a.multiplying(by: b)
                    
                    elements[i+1] = String(describing: resultvalue)
                    
                    elements[i-1] = "nil"
                    elements[i] = "nil"
                    
                }
                
                if elements[i] == "/" && Double(elements[i-1]) != nil && Double(elements[i+1]) != nil{
                    
                    let a = NSDecimalNumber(string: elements[i-1])
                    let b = NSDecimalNumber(string: elements[i+1])
                    
                    if elements[i+1] == "0" {
                        
                        elements[i-1] = "nil"
                        elements[i] = "nil"
                        elements[i+1] = "nil"
                        
                    }
                    else{
                        
                        resultvalue = a.dividing(by: b)
                        
                        elements[i+1] = String(describing: resultvalue)
                        
                        elements[i-1] = "nil"
                        elements[i] = "nil"
                        
                    }
                }
                
                
            }
            
            
            elements = elements.filter{$0 != "nil"}
            
            
            //MUST NEED
            if elements.count > 1 {
                
                for i in 1..<elements.count {
                    
                    if Double(elements[i-1]) != nil && Double(elements[i]) != nil{
                        
                        let a = NSDecimalNumber(string: elements[i-1])
                        let b = NSDecimalNumber(string: elements[i])
                        
                        resultvalue = a.adding(b)
                        
                        elements[i] = String(describing: resultvalue)
                        
                        elements[i-1] = "nil"
                        
                        
                        
                        
                    }
                }
                
            }
            
            
            
            elements = elements.filter{$0 != "nil"}
            
            if elements.count == 1 {
                
                return elements[0]
            }
            else{
                
                return source
            }
            
        }
        else{
            
            //("didn't enter")
            return source
        }
        
    }
    
    
    
    func SCIENTIFIC_OPERATION(source:String)->(String){
        
        var resultvalue = NSDecimalNumber(string: "0.0")
        var input = source//sin60,sqrt4,log
        
        input = input.replacingOccurrences(of: "--", with: "+")
        input = input.replacingOccurrences(of: "+", with: " +")
        input = input.replacingOccurrences(of: "-", with: " -")
        
        input = input.replacingOccurrences(of: "/", with: " /")
        
        input = input.replacingOccurrences(of: "*", with: " *")
        
        
        input = input.replacingOccurrences(of: "^", with: " ^ ")
        
        
        
        
        input = input.replacingOccurrences(of: "sin", with: " sin")
        input = input.replacingOccurrences(of: "log", with: " log")
        input = input.replacingOccurrences(of: "cos", with: " cos")
        input = input.replacingOccurrences(of: "tan", with: " tan")
        input = input.replacingOccurrences(of: "sqr", with: " sqr")
        input = input.replacingOccurrences(of: "sin -", with: "sin-")
        input = input.replacingOccurrences(of: "cos -", with: "cos-")
        input = input.replacingOccurrences(of: "tan -", with: "tan-")
        input = input.replacingOccurrences(of: "a sin", with: "asin")
        input = input.replacingOccurrences(of: "a cos", with: "acos")
        input = input.replacingOccurrences(of: "a tan", with: "atan")
        
        
        
        input = input.replacingOccurrences(of: "(", with: " ( ")
        input = input.replacingOccurrences(of: ")", with: " ) ")
        
        
        //("input")
        //(input)
        
        
        var elements : [String] = input.split{$0 == " "}.map(String.init)
        
        //(elements)
        
        
        for i in 0..<elements.count {
            
            if elements[i].contains("asin") {
                
                if Double(elements[i].replacingOccurrences(of: "asin", with: "")) == nil{
                    
                    
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "asin", with: "")
                    
                    
                    //http://stackoverflow.com/questions/39890795/decimal-to-double-conversion-in-swift-3
                    resultvalue = NSDecimalNumber(value:asin(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                    
                }
                
            }
            
            if elements[i].contains("acos") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "acos", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "acos", with: "")
                    
                    //http://stackoverflow.com/questions/39890795/decimal-to-double-conversion-in-swift-3
                    resultvalue = NSDecimalNumber(value:acos(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            if elements[i].contains("atan") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "atan", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "atan", with: "")
                    
                    
                    //http://stackoverflow.com/questions/39890795/decimal-to-double-conversion-in-swift-3
                    resultvalue = NSDecimalNumber(value:atan(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            if elements[i].contains("sin") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "sin", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "sin", with: "")
                    
                    //http://stackoverflow.com/questions/39890795/decimal-to-double-conversion-in-swift-3
                    resultvalue = NSDecimalNumber(value:sin(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            if elements[i].contains("cos") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "cos", with: "")) == nil{
                    
                    //("cosnil")
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "cos", with: "")
                    
                    
                    //http://stackoverflow.com/questions/39890795/decimal-to-double-conversion-in-swift-3
                    resultvalue = NSDecimalNumber(value:cos(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            if elements[i].contains("tan") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "tan", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "tan", with: "")
                    
                    
                    //http://stackoverflow.com/questions/39890795/decimal-to-double-conversion-in-swift-3
                    resultvalue = NSDecimalNumber(value:tan(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            
            
            //
            if elements[i].contains("sqrt") {
                
                
                if Double(elements[i].replacingOccurrences(of: "sqrt", with: "")
                    ) == nil{
                    
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "sqrt", with: "")
                    
                    
                    //http://stackoverflow.com/questions/39890795/decimal-to-double-conversion-in-swift-3
                    resultvalue = NSDecimalNumber(value:sqrt(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            
            //http://swift.tecc0.com/?p=105
            if elements[i].contains("abs") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "abs", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "abs", with: "")
                    
                    resultvalue = NSDecimalNumber(value:fabs(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            
            
            if elements[i].contains("expb") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "expb", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "expb", with: "")
                    
                    resultvalue = NSDecimalNumber(value:exp2(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            if elements[i].contains("exp") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "exp", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "exp", with: "")
                    
                    resultvalue = NSDecimalNumber(value:exp(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            if elements[i].contains("logb") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "logb", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "logb", with: "")
                    
                    resultvalue = NSDecimalNumber(value:log2(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            
            if elements[i].contains("logd") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "logd", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "logd", with: "")
                    
                    resultvalue = NSDecimalNumber(value:log10(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            
            if elements[i].contains("log") {
                
                
                
                if Double(elements[i].replacingOccurrences(of: "log", with: "")) == nil{
                    
                }else{
                    
                    elements[i] = elements[i].replacingOccurrences(of: "log", with: "")
                    
                    resultvalue = NSDecimalNumber(value:log(Double(elements[i])!))
                    
                    elements[i] = String(describing: resultvalue)
                }
            }
            
            
            
        }
        
        //("elements")
        //(elements)
        
        let resultstr = elements.joined(separator: "")
        
        return resultstr
        
    }
    
    
    func BASIC_OPERATION(source:String)->(String){
        
        var resultvalue = NSDecimalNumber(string: "0.0")
        
        var input = source
        
        input = input.replacingOccurrences(of: "--", with: "+")
        input = input.replacingOccurrences(of: "+", with: " ")
        input = input.replacingOccurrences(of: "/", with: " / ")
        input = input.replacingOccurrences(of: "-", with: " -")
        input = input.replacingOccurrences(of: "*", with: " * ")
        input = input.replacingOccurrences(of: "^", with: " ^ ")
        
        var elements : [String] = input.split{$0 == " "}.map(String.init)
        
        
        
        for i in 0..<elements.count {
            
            if (elements[i] == "^" && Double(elements[i-1]) != nil && Double(elements[i+1]) != nil) {
                
                if Double(elements[i+1]) == nil{
                    
                    elements[i+1] = "error"
                    
                    elements[i-1] = "nil"
                    elements[i] = "nil"
                    //error
                    
                }
                else{
                    
                    let a = Double(elements[i-1])
                    let b = Double(elements[i+1])
                    
                    //let c = pow(a as Decimal, b!)
                    var c = pow(a!, b!)
                    
                    c = c*100000
                    
                    c = round(c)/100000
                    
                    
                    elements[i+1] = String(describing: c)
                    
                    elements[i-1] = "nil"
                    elements[i] = "nil"
                    
                }
                
            }
            
            
            if elements[i] == "*" && Double(elements[i-1]) != nil && Double(elements[i+1]) != nil {
                
                let a = NSDecimalNumber(string: elements[i-1])
                let b = NSDecimalNumber(string: elements[i+1])
                
                resultvalue = a.multiplying(by: b)
                
                elements[i+1] = String(describing: resultvalue)
                
                elements[i-1] = "nil"
                elements[i] = "nil"
                
            }
            
            if elements[i] == "/" && Double(elements[i-1]) != nil && Double(elements[i+1]) != nil{
                
                let a = NSDecimalNumber(string: elements[i-1])
                let b = NSDecimalNumber(string: elements[i+1])
                
                if elements[i+1] == "0" {
                    
                    elements[i-1] = "nil"
                    elements[i] = "nil"
                    elements[i+1] = "nil"
                    
                }
                else{
                    
                    resultvalue = a.dividing(by: b)
                    
                    elements[i+1] = String(describing: resultvalue)
                    
                    elements[i-1] = "nil"
                    elements[i] = "nil"
                    
                }
            }
            
            
        }
        
        
        elements = elements.filter{$0 != "nil"}
        
        
        //MUST NEED
        if elements.count > 1 {
            
            for i in 1..<elements.count {
                
                if Double(elements[i-1]) != nil && Double(elements[i]) != nil{
                    
                    let a = NSDecimalNumber(string: elements[i-1])
                    let b = NSDecimalNumber(string: elements[i])
                    
                    resultvalue = a.adding(b)
                    
                    elements[i] = String(describing: resultvalue)
                    
                    elements[i-1] = "nil"
                    
                    
                    
                    
                }
            }
            
        }
        
        
        
        elements = elements.filter{$0 != "nil"}
        
        let resultstr = elements.joined(separator: "")
        
        return resultstr
        
    }
    
    func EXCEL_FUNCTION(src:String)->String{
        
        if src.contains("IMPRODUCT(") {
//            let breakedDown = src.replacingOccurrences(of: "complex(", with: "").replacingOccurrences(of: ")", with: "")
            return COMPLEX_PRODUCT(src: src)
        }else if src.contains("IMSUM(") {
            return COMPLEX_ADDITION(src: src)
        }else if src.contains("IMSUB(") {
            return COMPLEX_SUBTRACTION(src: src)
        }else if src.contains("IMCONJUGATE(") {
            return COMPLEX_IMCONJUGATE(src: src)
        }else if src.contains("IMDIV(") {
            return COMPLEX_DIVISION(src: src)
        }else if src.contains("IMARGUMENT(") {
            return COMPLEX_IMARGUMENT(src: src)
        }else if src.contains("IMABS(") {
            return COMPLEX_ABS(src: src)
        }else if src.contains("IMRECTANGULAR("){
            return COMPLEX_IMRECTANGULAR(src: src)
        }else if src.contains("COMPLEX("){
            return COMPLEX_CREATE(src: src)
        }else{
            return "error"
        }
    }
    
    func COMPLEX_CREATE(src:String)->String{
        var complex_number = src
        if complex_number.contains("COMPLEX(") {
            complex_number = complex_number.replacingOccurrences(of: "COMPLEX(", with: "").replacingOccurrences(of: ")", with: "")
        }else{
            return src
        }
        var ary = complex_number.components(separatedBy: ",")
        if ary.count == 1 || ary.count > 3{
            return src
        }
        
        //Contains nO reference like A2
        //We use sqrt in complex numbers that's why the following code comes
        let real = ONELINE_CALC(oneLine: ary[0].replacingOccurrences(of: "sqrt(", with: "sqrt").replacingOccurrences(of: ")", with: ""))
        let img = ONELINE_CALC(oneLine: ary[1].replacingOccurrences(of: "sqrt(", with: "sqrt").replacingOccurrences(of: ")", with: ""))
        
        if Double(real) != nil && Double(img) != nil{
            if Double(img)! < 0.0{
                let dv = Double(img)
                let absv = abs(dv!)
                return real + "-j" + String(absv)
            }else if Double(img)! > 0.0{
                return real + "+j" + img
            }else{
                
            }
        }
        
        return src
    }
    
    func COMPLEX_PRODUCT(src:String)->String{
        var realPart = [Double]()
        var imgPart = [Double]()
        var realCalced = 0.0
        var imgCalced = 0.0
        
        let breakedDown = src.replacingOccurrences(of: "IMPRODUCT(", with: "").replacingOccurrences(of: ")", with: "")
        let ary = breakedDown.components(separatedBy: ",")
        for i in 0..<ary.count {
            
            if ary[i].contains("j") {
                
            }else{
                return "error"
            }
            var complex_number = ""
            if ary[i].prefix(1) == "j" {
                complex_number = "0+" + ary[i]
            }else if ary[i].prefix(2) == "+j" || ary[i].prefix(2) == "-j" {
                complex_number = "0" + ary[i]
            }else{
                complex_number = ary[i]
            }
            
            complex_number = complex_number.replacingOccurrences(of: "=", with: "")
            let elements = complex_number.components(separatedBy: "j")
            let lastChar = elements[0].last
            var real = String(elements[0].dropLast())
            var img = String(lastChar!) + elements[1]//-1 or +1
            real = ONELINE_CALC(oneLine: real)
            img = ONELINE_CALC(oneLine: img)
            if Double(real) != nil{
                let r = Double(real)
                realPart.append(r!)
            }else{return "error"}
            if Double(img) != nil{
                let i = Double(img)
                imgPart.append(i!)
            }else{return "error"}
            
            //1+j4
        }
        
        if realPart.count < 2 {
            return "error"
        }
        //TODO sorting..
        realCalced = realPart[0]
        imgCalced = imgPart[0]
        for i in 1..<realPart.count {
            let a = realCalced
            let b = imgCalced
            let c = realPart[i]
            let d = imgPart[i]
            
            realCalced = a*c
            if realCalced > 0 && b*d > 0{
                realCalced = realCalced - abs(b*d)
            }else if realCalced < 0 && b*d < 0{
                realCalced = realCalced - abs(b*d)
            }else{
                realCalced = realCalced + abs(b*d)
            }
            
            imgCalced = a*d
            imgCalced = imgCalced + b*c
            
            
        }
        
        //a+jb * c+jd ->a*c +jad + jbc +bd
        //https://stackoverflow.com/questions/26350977/how-to-round-a-double-to-the-nearest-int-in-swift
        
        let numberOfPlaces = 3.0
        let multiplier = pow(10.0, numberOfPlaces)
        
        realCalced = realCalced * multiplier
        realCalced = round(realCalced) / multiplier
        
        imgCalced = imgCalced * multiplier
        imgCalced = round(imgCalced) / multiplier
        
//        print(realCalced)
//        print(imgCalced)
        
        if imgCalced > 0{
            return String(realCalced) + "+j" + String(imgCalced)
        }else{
            return String(realCalced) + "-j" + String(abs(imgCalced))
        }
    }
    
    func COMPLEX_ADDITION(src:String)->String{
               var realPart = [Double]()
               var imgPart = [Double]()
               var realCalced = 0.0
               var imgCalced = 0.0
               
               let breakedDown = src.replacingOccurrences(of: "IMSUM(", with: "").replacingOccurrences(of: ")", with: "")
               let ary = breakedDown.components(separatedBy: ",")
               for i in 0..<ary.count {
                   
                   if ary[i].contains("j") {
                       
                   }else{
                       return "error"
                   }
                   var complex_number = ""
                   if ary[i].prefix(1) == "j" {
                       complex_number = "0+" + ary[i]
                   }else if ary[i].prefix(2) == "+j" || ary[i].prefix(2) == "-j" {
                       complex_number = "0" + ary[i]
                   }else{
                       complex_number = ary[i]
                   }
                   
                   complex_number = complex_number.replacingOccurrences(of: "=", with: "")
                   let elements = complex_number.components(separatedBy: "j")
                   let lastChar = elements[0].last
                   var real = String(elements[0].dropLast())
                   var img = String(lastChar!) + elements[1]//-1 or +1
                   real = ONELINE_CALC(oneLine: real)
                   img = ONELINE_CALC(oneLine: img)
                   if Double(real) != nil{
                       let r = Double(real)
                       realPart.append(r!)
                   }else{return "error"}
                   if Double(img) != nil{
                       let i = Double(img)
                       imgPart.append(i!)
                   }else{return "error"}
                   
                   //1+j4
               }
               
               if realPart.count < 2 {
                   return "error"
               }
               //TODO sorting..
               realCalced = realPart[0]
               imgCalced = imgPart[0]
               for i in 1..<realPart.count {
                   let a = realCalced
                   let b = imgCalced
                   let c = realPart[i]
                   let d = imgPart[i]
                   
                   realCalced = a+c
                   imgCalced = b+d

               }
               
               //https://stackoverflow.com/questions/26350977/how-to-round-a-double-to-the-nearest-int-in-swift
               
               let numberOfPlaces = 3.0
               let multiplier = pow(10.0, numberOfPlaces)
               
               realCalced = realCalced * multiplier
               realCalced = round(realCalced) / multiplier
               
               imgCalced = imgCalced * multiplier
               imgCalced = round(imgCalced) / multiplier
               
//               print(realCalced)
//               print(imgCalced)
               
               if imgCalced > 0{
                   return String(realCalced) + "+j" + String(imgCalced)
               }else{
                   return String(realCalced) + "-j" + String(abs(imgCalced))
               }
    }
    
    func COMPLEX_SUBTRACTION(src:String)->String{
        var realPart = [Double]()
                      var imgPart = [Double]()
                      var realCalced = 0.0
                      var imgCalced = 0.0
                      
                      let breakedDown = src.replacingOccurrences(of: "IMSUB(", with: "").replacingOccurrences(of: ")", with: "")
                      let ary = breakedDown.components(separatedBy: ",")
                      for i in 0..<ary.count {
                          
                          if ary[i].contains("j") {
                              
                          }else{
                              return "error"
                          }
                          var complex_number = ""
                          if ary[i].prefix(1) == "j" {
                              complex_number = "0+" + ary[i]
                          }else if ary[i].prefix(2) == "+j" || ary[i].prefix(2) == "-j" {
                              complex_number = "0" + ary[i]
                          }else{
                              complex_number = ary[i]
                          }
                          
                          complex_number = complex_number.replacingOccurrences(of: "=", with: "")
                          let elements = complex_number.components(separatedBy: "j")
                          let lastChar = elements[0].last
                          var real = String(elements[0].dropLast())
                          var img = String(lastChar!) + elements[1]//-1 or +1
                          real = ONELINE_CALC(oneLine: real)
                          img = ONELINE_CALC(oneLine: img)
                          if Double(real) != nil{
                              let r = Double(real)
                              realPart.append(r!)
                          }else{return "error"}
                          if Double(img) != nil{
                              let i = Double(img)
                              imgPart.append(i!)
                          }else{return "error"}
                          
                          //1+j4
                      }
                      
                      if realPart.count < 2 {
                          return "error"
                      }
                      //TODO sorting..
                      realCalced = realPart[0]
                      imgCalced = imgPart[0]
                      
                      //a+jb c+jd
                      for i in 1..<realPart.count {
                          let a = realCalced
                          let b = imgCalced
                          let c = realPart[i] * -1
                          let d = imgPart[i] * -1
                          
                          realCalced = a+c
                          imgCalced = b+d

                      }
                      
                      //https://stackoverflow.com/questions/26350977/how-to-round-a-double-to-the-nearest-int-in-swift
                      
                      let numberOfPlaces = 3.0
                      let multiplier = pow(10.0, numberOfPlaces)
                      
                      realCalced = realCalced * multiplier
                      realCalced = round(realCalced) / multiplier
                      
                      imgCalced = imgCalced * multiplier
                      imgCalced = round(imgCalced) / multiplier
                      
//                      print(realCalced)
//                      print(imgCalced)
                      
                      if imgCalced > 0{
                          return String(realCalced) + "+j" + String(imgCalced)
                      }else{
                          return String(realCalced) + "-j" + String(abs(imgCalced))
                      }
    }
    
    func COMPLEX_DIVISION(src:String)->String{
        var realPart = [Double]()
               var imgPart = [Double]()
               var realCalced = 0.0
               var imgCalced = 0.0
         var mid = 0.0
               
               let breakedDown = src.replacingOccurrences(of: "IMDIV(", with: "").replacingOccurrences(of: ")", with: "")
               let ary = breakedDown.components(separatedBy: ",")
               for i in 0..<ary.count {
                   
                   if ary[i].contains("j") {
                       
                   }else{
                       return "error"
                   }
                   var complex_number = ""
                   if ary[i].prefix(1) == "j" {
                       complex_number = "0+" + ary[i]
                   }else if ary[i].prefix(2) == "+j" || ary[i].prefix(2) == "-j" {
                       complex_number = "0" + ary[i]
                   }else{
                       complex_number = ary[i]
                   }
                   
                   complex_number = complex_number.replacingOccurrences(of: "=", with: "")
                   let elements = complex_number.components(separatedBy: "j")
                   let lastChar = elements[0].last
                   var real = String(elements[0].dropLast())
                   var img = String(lastChar!) + elements[1]//-1 or +1
                   real = ONELINE_CALC(oneLine: real)
                   img = ONELINE_CALC(oneLine: img)
                   if Double(real) != nil{
                       let r = Double(real)
                       realPart.append(r!)
                   }else{return "error"}
                   if Double(img) != nil{
                       let i = Double(img)
                       imgPart.append(i!)
                   }else{return "error"}
                   
                   //1+j4
               }
               
               if realPart.count < 2 {
                   return "error"
               }
               //TODO sorting..
               realCalced = realPart[0]
               imgCalced = imgPart[0]
        //a+jb / c+jd e+jf
               for i in 1..<realPart.count {
                   let a = realCalced
                   let b = imgCalced
                   let c = realPart[i]
                   let d = imgPart[i]
                
                   //COMFO
                   let e = c
                   let f = d * -1
                
                  
                   mid = c * e
                   mid = mid + abs(d*f)
                
                   //
                   realCalced = a*e
                   if realCalced > 0 && b*f > 0{
                       realCalced = realCalced - abs(b*f)
                   }else if realCalced < 0 && b*f < 0{
                       realCalced = realCalced - abs(b*f)
                   }else{
                       realCalced = realCalced + abs(b*f)
                   }
                   
                   realCalced = realCalced / mid
                
                   imgCalced = a*f
                   imgCalced = imgCalced + b*e
                
                   imgCalced = imgCalced / mid
                   
               }
               
               //a+jb * c+jd ->a*c +jad + jbc +bd
               //https://stackoverflow.com/questions/26350977/how-to-round-a-double-to-the-nearest-int-in-swift
               
               let numberOfPlaces = 3.0
               let multiplier = pow(10.0, numberOfPlaces)
               
               realCalced = realCalced * multiplier
               realCalced = round(realCalced) / multiplier
               
               imgCalced = imgCalced * multiplier
               imgCalced = round(imgCalced) / multiplier
               
               print(realCalced)
               print(imgCalced)
               
               if imgCalced > 0{
                   return String(realCalced) + "+j" + String(imgCalced)
               }else{
                   return String(realCalced) + "-j" + String(abs(imgCalced))
               }
    }
    
    func COMPLEX_IMRECTANGULAR(src:String)->String{
        var realPart = Double()
                var imgPart = Double()
                var realCalced = 0.0
                var imgCalced = 0.0
                
                let breakedDown = src.replacingOccurrences(of: "IMRECTANGULAR(", with: "").replacingOccurrences(of: ")", with: "")
                let ary = breakedDown
             
                    if ary.contains(",") {
                        
                    }else{
                        return "error"
                    }
                   
                    let elements = ary.components(separatedBy: ",")
                    
                    if elements.count < 2{
                        return "error"
                    }
                    
        
                    var radius = String(elements[0])
                    var theta = String(elements[1])//-1 or +1
                    radius = ONELINE_CALC(oneLine: radius)
                    theta = ONELINE_CALC(oneLine: theta)
        if Double(theta) != nil{
                        
                    }else{return "error"}
                    if Double(radius) != nil{
                        
                    }else{return "error"}
                    
                    //1+j4
        let rad = Double(theta)! * Double.pi/180
                realCalced = Double(radius)! * cos(rad)
                imgCalced = Double(radius)! * sin(rad)
                
                //https://stackoverflow.com/questions/26350977/how-to-round-a-double-to-the-nearest-int-in-swift
                
                let numberOfPlaces = 3.0
                let multiplier = pow(10.0, numberOfPlaces)
                
                realCalced = realCalced * multiplier
                realCalced = round(realCalced) / multiplier
        
                imgCalced = imgCalced * multiplier
                imgCalced = round(imgCalced) / multiplier
        
                if imgCalced < 0 {
                    return String(realCalced) + "-j" + String(abs(imgCalced))
                }else{
                    return String(realCalced) + "+j" + String(abs(imgCalced))
                }
    }

    
    func COMPLEX_IMARGUMENT(src:String)->String{
           var realPart = Double()
                                 var imgPart = Double()
                                 var realCalced = 0.0
                                 var imgCalced = 0.0
                                 
                                 let breakedDown = src.replacingOccurrences(of: "IMARGUMENT(", with: "").replacingOccurrences(of: ")", with: "")
                                 let ary = breakedDown
                              
                                     if ary.contains("j") {
                                         
                                     }else{
                                         return "error"
                                     }
                                     var complex_number = ""
                                     if ary.prefix(1) == "j" {
                                         complex_number = "0+" + ary
                                     }else if ary.prefix(2) == "+j" || ary.prefix(2) == "-j" {
                                         complex_number = "0" + ary
                                     }else{
                                         complex_number = ary
                                     }
                                     
                                     complex_number = complex_number.replacingOccurrences(of: "=", with: "")
                                     let elements = complex_number.components(separatedBy: "j")
                                     let lastChar = elements[0].last
                                     var real = String(elements[0].dropLast())
                                     var img = String(lastChar!) + elements[1]//-1 or +1
                                     real = ONELINE_CALC(oneLine: real)
                                     img = ONELINE_CALC(oneLine: img)
                                     if Double(real) != nil{
                                         let r = Double(real)
                                         realPart = r!
                                     }else{return "error"}
                                     if Double(img) != nil{
                                         let i = Double(img)
                                         imgPart = i!
                                     }else{return "error"}
                                     
                                     //1+j4
                         
                                 realCalced = realPart
                                 imgCalced = imgPart
                                 
                                 var arctanjent = atan(imgCalced/realCalced)
                                 //https://stackoverflow.com/questions/26350977/how-to-round-a-double-to-the-nearest-int-in-swift
                                 
                                 let numberOfPlaces = 3.0
                                 let multiplier = pow(10.0, numberOfPlaces)
                                 
                                 arctanjent = arctanjent * multiplier
                                 arctanjent = round(arctanjent) / multiplier
                               
                                 return String(arctanjent)
                                 
    }
    func COMPLEX_ABS(src:String)->String{
           var realPart = Double()
                                 var imgPart = Double()
                                 var realCalced = 0.0
                                 var imgCalced = 0.0
                                 
                                 let breakedDown = src.replacingOccurrences(of: "IMABS(", with: "").replacingOccurrences(of: ")", with: "")
                                 let ary = breakedDown
                              
                                     if ary.contains("j") {
                                         
                                     }else{
                                         return "error"
                                     }
                                     var complex_number = ""
                                     if ary.prefix(1) == "j" {
                                         complex_number = "0+" + ary
                                     }else if ary.prefix(2) == "+j" || ary.prefix(2) == "-j" {
                                         complex_number = "0" + ary
                                     }else{
                                         complex_number = ary
                                     }
                                     
                                     complex_number = complex_number.replacingOccurrences(of: "=", with: "")
                                     let elements = complex_number.components(separatedBy: "j")
                                     let lastChar = elements[0].last
                                     var real = String(elements[0].dropLast())
                                     var img = String(lastChar!) + elements[1]//-1 or +1
                                     real = ONELINE_CALC(oneLine: real)
                                     img = ONELINE_CALC(oneLine: img)
                                     if Double(real) != nil{
                                         let r = Double(real)
                                         realPart = r!
                                     }else{return "error"}
                                     if Double(img) != nil{
                                         let i = Double(img)
                                         imgPart = i!
                                     }else{return "error"}
                                     
                                     //1+j4
                         
                                 realCalced = realPart
                                 imgCalced = imgPart
                                 
                                 //
                                 var abs = realCalced * realCalced + imgCalced * imgCalced
                                 abs = sqrt(abs)
                                 //https://stackoverflow.com/questions/26350977/how-to-round-a-double-to-the-nearest-int-in-swift
                                 
                                 let numberOfPlaces = 3.0
                                 let multiplier = pow(10.0, numberOfPlaces)
                                 
                                 abs = abs * multiplier
                                 abs = round(abs) / multiplier
                               
                                 return String(abs)
                                 
    }
    
    func COMPLEX_IMCONJUGATE(src:String)->String{
                            var realPart = Double()
                            var imgPart = Double()
                            var realCalced = 0.0
                            var imgCalced = 0.0
                            
                            let breakedDown = src.replacingOccurrences(of: "IMCONJUGATE(", with: "").replacingOccurrences(of: ")", with: "")
                            let ary = breakedDown
                         
                                if ary.contains("j") {
                                    
                                }else{
                                    return "error"
                                }
                                var complex_number = ""
                                if ary.prefix(1) == "j" {
                                    complex_number = "0+" + ary
                                }else if ary.prefix(2) == "+j" || ary.prefix(2) == "-j" {
                                    complex_number = "0" + ary
                                }else{
                                    complex_number = ary
                                }
                                
                                complex_number = complex_number.replacingOccurrences(of: "=", with: "")
                                let elements = complex_number.components(separatedBy: "j")
                                let lastChar = elements[0].last
                                var real = String(elements[0].dropLast())
                                var img = String(lastChar!) + elements[1]//-1 or +1
                                real = ONELINE_CALC(oneLine: real)
                                img = ONELINE_CALC(oneLine: img)
                                if Double(real) != nil{
                                    let r = Double(real)
                                    realPart = r!
                                }else{return "error"}
                                if Double(img) != nil{
                                    let i = Double(img)
                                    imgPart = i!
                                }else{return "error"}
                                
                                //1+j4
                    
                            realCalced = realPart
                            imgCalced = imgPart
                            
                            //
                            imgCalced = imgCalced * -1
                            
                            //https://stackoverflow.com/questions/26350977/how-to-round-a-double-to-the-nearest-int-in-swift
                            
                            let numberOfPlaces = 3.0
                            let multiplier = pow(10.0, numberOfPlaces)
                            
                            realCalced = realCalced * multiplier
                            realCalced = round(realCalced) / multiplier
                            
                            imgCalced = imgCalced * multiplier
                            imgCalced = round(imgCalced) / multiplier
                            
                            print(realCalced)
                            print(imgCalced)
                            
                            if imgCalced > 0{
                                return String(realCalced) + "+j" + String(imgCalced)
                            }else{
                                return String(realCalced) + "-j" + String(abs(imgCalced))
                            }
    }
    
   
    
    
    func IMG_OPERATION(src:String){
        if src.contains("j") {//(sqrt(3) - 5 j) * (sqrt(3) + 5 j)
            let breakedDown = src.replacingOccurrences(of: "COMPLEX(", with: "").replacingOccurrences(of: ")", with: "")
        }
    }
    
    
    func ONELINE_CALC(oneLine:String)->String{
        var tempStr = oneLine
        let charset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                    if oneLine.rangeOfCharacter(from: charset) != nil {
                       print("ABC",oneLine)
                    }else{
                        
                        tempStr = oneLine.replacingOccurrences(of: "=", with: "")
                    }
                    
                    
                    let notgood = tempStr.suffix(1)
                    if notgood == "^"{
                        
                        tempStr = ""
                    }else if notgood == "/"{
                        
                        tempStr = ""
                    }else if notgood == "*"{
                        
                        tempStr = ""
                    }else if notgood == "-"{
                        
                        tempStr = ""
                    }else if notgood == "+"{
                        
                        tempStr = ""
                    }
                    
                    
                    //Feb 9
                    var elements = [String]()
                    var bz_local = 0
                    var startindex = -1
                    
                    var loopcounter = 10
                    
                    //PREPARATION
                    tempStr = REPLACE_WITH_CONSTANT(source: tempStr)
                    
                    //
                    tempStr = tempStr.replacingOccurrences(of: ",", with: "")
                    
                    
                    //Comma Free
                    tempStr = tempStr.replacingOccurrences(of: ",", with: "")
                    
                    if tempStr.contains("(") {
                        
                    }else{
                        loopcounter = 0
                    }
                    
                    
                    while loopcounter > 0  {
                        
                        
                        tempStr = tempStr.replacingOccurrences(of: "(", with: " ( ")
                        tempStr = tempStr.replacingOccurrences(of: ")", with: " ) ")//これで中は数字だけ
                        
                        elements = tempStr.split{$0 == " "}.map(String.init)
                        bz_local = 0
                        startindex = -1
                        
                        for i in 0..<elements.count {
                            
                            if elements[i] == "(" {
                                bz_local += 1
                            }
                        }
                        
                        while bz_local > 0 {
                            
                            startindex = BRACKET_INDEX(source: tempStr, bracketsize:bz_local)
                            elements[startindex] = CALCULATION_OPERATION(source: elements[startindex])
                            
                            bz_local -= 1
                        }
                        
                        
                        if elements.count > 2 {//(9.5)->9.5
                            
                            for i in 2..<elements.count {
                                if elements[i] == ")" && elements[i-2] == "("{
                                    elements[i] = "nil"
                                    elements[i-2] = "nil"
                                }
                            }
                        }
                        
                        elements = elements.filter{$0 != "nil"}
                        
                        tempStr = elements.joined(separator: "")
                        
                        //ここでnext calculation (sin0.7853+1.75)、sin、sqrtを置換
                        tempStr = SCIENTIFIC_OPERATION(source: tempStr)
                        
                        if Double(tempStr) != nil{
                            loopcounter = 0
                        }
                        loopcounter -= 1
                    }
                    
                    
                    //()がない場合も考えないといけない。その場合は
                    if Double(tempStr) == nil{
                        
                        tempStr = SCIENTIFIC_OPERATION(source: tempStr)
                        tempStr = BASIC_OPERATION(source: tempStr)
                        
                        
                    }
                    else{
                        //Ok that's it
                    }
                    

                    if Double(tempStr) != nil{
                        
                        //http://swift-salaryman.com/round.php
                        var calculated = Double(tempStr)! * 10000
                        calculated = round(calculated) / 10000
                        //print(calculated, "final answer")
//                        f_calculated.append(String(calculated))
//                        if numberContentLocationInLetters.contains((String(f_location_alphabet[i]))){
//                            let idx = numberContentLocationInLetters.index(of: (String(f_location_alphabet[i])))
//                            numberContent[idx!] = String(calculated)
//                        }else{
//                            numberContentLocationInLetters.append((String(f_location_alphabet[i])))
//                            numberContent.append((String(calculated)))
//                        }
                        
                        return String(calculated)
                        
                    }else{

                        return "error"
                    }
        }
    
    
}
