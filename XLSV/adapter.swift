//
//  adapter.swift
//  xmlProject
//
//  Created by yujin on 2020/10/19.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class Adapter{
    var content:[String]
    var location:[String]
    var sheetIdx:[Int]
    var uniqueContent:[String]
    var span:[String]
    let sheetSize:Int
    var rowSpan:[String]
    //TODO Formula [String] if not put nil
    var formulaContent:[String]

    
    
    init(imp_content:[String],imp_location:[String],imp_sheetIdx:[Int],imp_sheetSize:Int, imp_formula:[String]) {
        content = imp_content//tank,plane
        location = imp_location//A4,B2,A1
        sheetIdx = imp_sheetIdx//1,2,3,2,2
        sheetSize = imp_sheetSize
        uniqueContent = [String]()
        span=[String]()//count = sheetSize
        rowSpan = [String]()//1:2,3:3 count = sheetSize
        formulaContent = imp_formula
    }
    
    func getColumnNameNumber(columnName:String)->Int{
        //set span values X:Y
        //Convert column names to number
        //https://stackoverflow.com/questions/667802/what-is-the-algorithm-to-convert-an-excel-column-letter-into-its-number
        let letters = columnName//"AA"
        var sum = 0

        let character: Character = "A"
        let scalars = character.unicodeScalars
        let firstScalar = scalars[scalars.startIndex]
        

        for i in 0..<letters.count {
            
            let characterAti: Character = letters[letters.index(letters.startIndex, offsetBy: i)]
            let scalarsAti = characterAti.unicodeScalars
            let firstScalarAti = scalarsAti[scalarsAti.startIndex].value
            
            
            sum = sum * 26
            sum = sum + (Int(firstScalarAti) - (Int(firstScalar.value) - 1))
        }
        
        print("columnNumber",sum)
        return sum
    }
    
    func initSpanAry(){
        //TODO emptySheet
        for i in 1..<sheetSize+1 {
            var tempSpanValues=[Int]()
            var temprowSpanValues=[Int]()
            for j in 0..<sheetIdx.count {
                if i==sheetIdx[j] {
                    let CN = location[j].letters
                    tempSpanValues.append(getColumnNameNumber(columnName: CN))//AA
                    temprowSpanValues.append(Int.parse(from: location[j])!)//1
                }
            }
            let max = tempSpanValues.max()
            let min = tempSpanValues.min()
            
            if max == nil || min == nil{
                span.append("nil")
                rowSpan.append("nil")
            }else{
                //1:1,1:3
                span.append("spans=\"" + String(min!) + ":" + String(max!) + "\"")
                let max_row = temprowSpanValues.max()
                let min_row = temprowSpanValues.min()
                rowSpan.append(String(min_row!) + ":" + String(max_row!))
            }
        }
        //spans="1:1",rowSpans="1:3"
    }
    
    func initUniqueContentAry(){
        var unique = [String]()
        for i in 0..<content.count {
            if (unique.firstIndex(of:content[i]) == nil) {
                //TODO complex number or str formulas
                if Double(content[i]) == nil{
                    
                    //formula values are double numbers.. I think
                    if complexNumberCheck(src: content[i]){
                       content[i] = complexFormat(src: content[i])
                    }else{
                        unique.append(content[i])
                    }
                }
            }
        }
        uniqueContent = unique
    }
    
    func complexFormat(src:String)->String{
        var ary = src
      
            if ary.contains("j") {
                let mid = ary.replacingOccurrences(of: "j", with: "")
                ary = mid + "j"
            }
   
        return ary
    }
    
    func complexNumberCheck(src:String)->Bool{
        let ary = src.components(separatedBy: "j")
        if ary.count == 2{
            if Double(ary[1]) != nil{
                if Double(ary[0].dropLast()) != nil{
                    return true
                }
            }
        }
        
        let ary2 = src.components(separatedBy: "j")
        if ary2.count == 2{
            if Double(ary2[1]) != nil{
                if Double(ary2[0].dropLast()) != nil{
                    return true
                }
            }
        }
        
        return false
    }
    
    
    func strFormulaCheck(ary:[String],element:String)->Bool{
        for i in 0..<ary.count {
            if element.contains(ary[i]){
                return true
            }
        }
        
        return false
    }
    
    func sortAlphabetical(sheet_sorted_location:[String],sheet_sorted_content:[String],sheet_sorted_formula:[String]) -> ([String],[String],[String]) {
        
        var sorted_location = [String]()
        var sorted_content = [String]()
        var sorted_formula = [String]()
        //"B5","B4","A4","C4","B3","F4","D4"
       
        sorted_location = sheet_sorted_location
        sorted_location.sort()
        //https://www.hackingwithswift.com/example-code/arrays/how-to-sort-an-array-using-sort
        
        for i in 0..<sorted_location.count {
            let idx = sheet_sorted_location.firstIndex(of:sorted_location[i])
            
            if idx != nil{
                sorted_content.append(sheet_sorted_content[idx!])
                sorted_formula.append(sheet_sorted_formula[idx!])
            }
        }
        
        
        return (sorted_location,sorted_content,sorted_formula)
        
    }
    
    func createContentArys()->([String],String){
        initSpanAry()
        initUniqueContentAry()
        
        //str _fomulas list
        let STR_FORMULAS = [
                            "IMPRODUCT",
                            "IMSUM",
                            "IMSUB",
                            "IMDIV",
                            "IMABS",
                            "IMARGUMENT",
                            "IMCONJUGATE",
                            "COMPLEX"
        ]
        
        //Create sharedString
        var sharedString_data = "<sst xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" count=\"" + String(content.count) + "\">"
        
        for i in 0..<uniqueContent.count {
            sharedString_data.append("<si><t>")
            sharedString_data.append(uniqueContent[i])
            sharedString_data.append("</t></si>")
        }
        sharedString_data.append("</sst>")
        
        //Creating sheet_data_ary
        //TODO
        var sheet_data_ary = [String]()
        for i in 0..<sheetSize {
            
            let sheet_spans = span[i]
            var sheet_content = [String]()
            var sheet_location = [String]()
            var sheet_formula = [String]()
            let row_start :Int
            let row_end :Int
            let row_diff :Int
            
            if sheet_spans.contains("nil"){
                sheet_data_ary.append("<sheetData/>")
            }else{
                
            
            row_start = Int(rowSpan[i].components(separatedBy: ":")[0])!
            row_end = Int(rowSpan[i].components(separatedBy: ":")[1])!
            row_diff = row_end - row_start
            
            var sheet_string = ""
            
            //extracting each sheet
            for j in 0..<location.count {
                if i+1 == sheetIdx[j] {//sheet1,sheet2,sheet3...
                    sheet_content.append(content[j])
                    sheet_location.append(location[j])
                    sheet_formula.append(formulaContent[j])
                }
            }
                
            //TODO sort in alphabetical order
            //"sheep","dog","crow"
                (sheet_location,sheet_content,sheet_formula) = sortAlphabetical(sheet_sorted_location: sheet_location, sheet_sorted_content: sheet_content, sheet_sorted_formula: sheet_formula)
                
                
            if row_diff == 0 {
                //TODO only one row
                sheet_string = "<sheetData>"
             
                    var rowElement = "<row r=" + "\"" + String(row_start) + "\" " + sheet_spans + ">"
                    //Writing start
                    for l in 0..<sheet_location.count {
                        //1 == A1
                        if row_start == Int.parse(from: sheet_location[l])! {
                            //TODO check formula
                            if Double(sheet_content[l]) == nil {
                                let sharedLocation = uniqueContent.firstIndex(of: sheet_content[l])
                               
                                if (sharedLocation != nil){
                                    rowElement.append("<c r=" + "\"" + sheet_location[l] + "\" " + "t=\"s\"><v>" + String(sharedLocation!) + "</v></c>")
                                }else{
                                    //TODO strFormulas as result values are not double numbers they came into here.
                                 
                                    //TODO str formulas t="str"
                                    if strFormulaCheck(ary: STR_FORMULAS, element: sheet_formula[l]){
                                        if sheet_formula[l].contains("COMPLEX"){
                                            sheet_formula[l] = sheet_formula[l].dropLast() + " ,\"j\")"
                                        }
                                        rowElement.append("<c r=" + "\"" + sheet_location[l] + "\" " + "t=\"str\"><f>" + sheet_formula[l] + "</f><v>" + sheet_content[l] + "</v></c>")
                                    }else{
                                        //other str formulas
                                    }
                                }
                            }else{
                                if (sheet_formula[l] != "nil" ){

                                    rowElement.append("<c r=" + "\"" + sheet_location[l] + "\"><f>" + sheet_formula[l] + "</f><v>" + sheet_content[l] + "</v></c>")

                                }else{
                                                        
                                
                                rowElement.append("<c r=" + "\"" + sheet_location[l] + "\"><v>" + sheet_content[l] + "</v></c>")
                                }
                            }
                            
                        }
                    }
                    
                    rowElement.append("</row>")
                    sheet_string.append(rowElement)
             
                
                sheet_string.append("</sheetData>")
                sheet_data_ary.append(sheet_string)
            }else if row_diff > 0{
                sheet_string = "<sheetData>"
                for k in row_start..<row_end+1 {
                    var rowElement = "<row r=" + "\"" + String(k) + "\" " + sheet_spans + ">"
                    //Writing start
                    for l in 0..<sheet_location.count {
                        //1 == A1
                        if k == Int.parse(from: sheet_location[l])! {
                            //TODO check formula
                            if Double(sheet_content[l]) == nil {
                                let sharedLocation = uniqueContent.firstIndex(of: sheet_content[l])
                                if (sharedLocation != nil){
                                    rowElement.append("<c r=" + "\"" + sheet_location[l] + "\" " + "t=\"s\"><v>" + String(sharedLocation!) + "</v></c>")
                                }else{
                                   //TODO str formulas t="str" convert to 1+7j
                                   if strFormulaCheck(ary: STR_FORMULAS, element: sheet_formula[l]){
                                    if sheet_formula[l].contains("COMPLEX"){
                                        sheet_formula[l] = sheet_formula[l].dropLast() + " ,\"j\")"
                                    }
                                       rowElement.append("<c r=" + "\"" + sheet_location[l] + "\" " + "t=\"str\"><f>" + sheet_formula[l] + "</f><v>" + sheet_content[l] + "</v></c>")
                                   }else{
                                    //other str formulas
                                    }
                                }
                            }else{
                                if (sheet_formula[l] != "nil" ){
                                    
                                //TODO str formulas t="str" convert to 1+7j
                                    rowElement.append("<c r=" + "\"" + sheet_location[l] + "\"><f>" + sheet_formula[l] + "</f><v>" + sheet_content[l] + "</v></c>")

                                }else{
                                                        
                                    rowElement.append("<c r=" + "\"" + sheet_location[l] + "\"><v>" + sheet_content[l] + "</v></c>")
                                    
                                }
                            }
                        }
                    }
                    
                    rowElement.append("</row>")
                    sheet_string.append(rowElement)
                }
                
                sheet_string.append("</sheetData>")
                sheet_data_ary.append(sheet_string)
            }
            
            
            }
            
            
            
            
        }
        return (sheet_data_ary,sharedString_data)
    }
    
    //TODO
    //"<sst xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" count=\"3\" uniqueCount=\"3\"><si><t>sheet1 empty</t></si><si><t>sheet2 empty</t></si><si><t>sheet3 empty</t></si></sst>"
    
}

extension String {
    var letters: String {
        return String(unicodeScalars.filter(CharacterSet.letters.contains))
    }
}

extension Int {
    static func parse(from string: String) -> Int? {
        return Int(string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
    }
}



//defaultRowHeight="13.5"/><sheetData><row r="1" spans="1:1"><c r="A1" t="s"><v>1</v></c></row></sheetData>

//<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
//<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="3" uniqueCount="3">
//    <si>
//        <t>sheet1 empty</t>
//    </si>
//    <si>
//        <t>sheet2 empty</t>
//    </si>
//    <si>
//        <t>sheet3 empty</t>
//    </si>
//</sst>
