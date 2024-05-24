//
//  service.swift
//  xmlProject
//
//  Created by yujin on 2020/10/21.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation
import Zip
import SWXMLHash
import SwiftyXMLParser

class Service {
    var sheetNumber:Int
    var stringContents:[String]
    
    var locations:[String]
    
    var sheetIdx:[Int]
    
    var customFileName:String
    
    var formulaContens:[String]
    
    var siElementCount: Int = 0

    init(imp_sheetNumber:Int,imp_stringContents:[String],imp_locations:[String],imp_idx:[Int],imp_fileName:String,imp_formula:[String]) {
        
        sheetNumber = imp_sheetNumber
        stringContents = imp_stringContents
        locations = imp_locations
        sheetIdx = imp_idx
        customFileName = imp_fileName
        formulaContens = imp_formula
        
        //MinmumSheet number check
        if sheetNumber < 3{
            sheetNumber = 3
        }
        
    }
    
    func export(){
        FileManager.default.deleteWorksheets()
              
              let semaphore = DispatchSemaphore(value: 1)
              DispatchQueue.global().async {
                  
                let adp = Adapter(imp_content: self.stringContents, imp_location: self.locations, imp_sheetIdx: self.sheetIdx, imp_sheetSize:self.sheetNumber,imp_formula:self.formulaContens)
              
                  var temp_ary = [String]()
                  var temp_string = ""
                  (temp_ary,temp_string) = adp.createContentArys()
                  
//                  print("ADP")
//                  print(temp_ary)
//                  print(temp_string)
                  Styles().export()
              
                  Theme().export()
              
                  Rels().export()
              
                  App().export()
              
                  Core().export()
                  
                  XlRels().export(sheetSize: self.sheetNumber)
              
                  ContentType().export(sheetSize: self.sheetNumber)
              
                  Workbook().export(sheetSize: self.sheetNumber)
              
                  Sharedstring(imp_sharedString: temp_string).export(sheetSize: self.sheetNumber)
                  
                  Sheet(imp_sheetContents: temp_ary).export(sheetSize: self.sheetNumber)
                  
                  semaphore.wait()
                  sleep(5)
                  semaphore.signal()
                  print("Finished")
                  
              }
              

         DispatchQueue.global().async {
          semaphore.wait()
            sleep(5)
            self.writeXlsxSandBox(path: (FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents"))!,fileName: self.customFileName)
              }
              semaphore.signal()
        
        
    }
    
    //making now style
    func testExtractStyle(url:URL? = nil)->String?{
        if let url2 = url{
            var modifiedPartNum = 0
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            var patternFound = false
            // Start parsing
            if parser.parse() {
                // Retrieve the extracted part
                let extractedPart = delegate.extractedPart
                //print(extractedPart)
            }
            
            //regular expression
            var xmlString = try? String(contentsOf: url2)
            if (xmlString != nil){
                let generalNumFmt = "<xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyNumberFormat=\"1\"/>"
                
                if !xmlString!.contains(generalNumFmt) {
                    xmlString! = xmlString!.replacingOccurrences(of: "</cellXfs>", with: generalNumFmt + "</cellXfs>")
                    modifiedPartNum += 1
                }
                
                
                //edit it first. append numFmtId 14 Date
                let dateNumFmt = "<xf numFmtId=\"14\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyNumberFormat=\"1\"/>"
                
                if !xmlString!.contains(dateNumFmt) {
                    xmlString! = xmlString!.replacingOccurrences(of: "</cellXfs>", with: dateNumFmt + "</cellXfs>")
                    modifiedPartNum += 1
                }
                
                let timeNumFmt = "<xf numFmtId=\"20\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyNumberFormat=\"1\"/>"
                
                if !xmlString!.contains(timeNumFmt) {
                    xmlString! = xmlString!.replacingOccurrences(of: "</cellXfs>", with: timeNumFmt + "</cellXfs>")
                    modifiedPartNum += 1
                }
                
                
                
                let xml = XMLHash.parse(xmlString!)
                
                var numFmts = [String]()
                var formatCodes = [String]()
                // Assuming `xml` is your XML object
                for child in xml.children.first!.children[0].children {
                    if child.element?.name == "numFmt" {
                        // Get the attributes
                        let attributes = child.element?.allAttributes
                        // Extract numFmtId
                        if let numFmtId = attributes!["numFmtId"]?.text {
                            print("numFmtId:", numFmtId)
                            numFmts.append(numFmtId)
                        }
                        // Extract formatCode
                        if let formatCode = attributes!["formatCode"]?.text {
                            print("formatCode:", formatCode)
                            formatCodes.append(formatCode)
                        }
                    }
                }
                
                var numFmtIds = [Int]()
                // Assuming `xml` is your XML object
                for child in xml.children.first!.children.first(where: { $0.element?.name == "cellXfs" })!.children {
                    if let id = child.element?.allAttributes["numFmtId"]?.text {
                        numFmtIds.append(Int(id) ?? -1)
                    }
                }
                

                var cellXfs = [Int]()
                // Assuming `xml` is your XML object
                for child in xml.children.first!.children.first(where: { $0.element?.name == "cellXfs" })!.children {
                    if let borderId = child.element?.allAttributes["borderId"]?.text {
                        cellXfs.append(Int(borderId) ?? -1)
                    }
                }
                
                var cellStyleXfs = [Int]()
                // Assuming `xml` is your XML object
                for child in xml.children.first!.children.first(where: { $0.element?.name == "cellStyleXfs" })!.children {
                    if let borderId = child.element?.allAttributes["borderId"]?.text {
                        cellStyleXfs.append(Int(borderId) ?? -1)
                    }
                }
                
                
                var border_lefts = [Int]()
                var border_rights = [Int]()
                var border_bottoms = [Int]()
                var border_tops = [Int]()
                // Assuming `xml` is your XML object
                for child in xml.children.first!.children.first(where: { $0.element?.name == "borders" })!.children{
                    if child.children.count > 0{
                        border_lefts.append(0)
                        border_rights.append(0)
                        border_bottoms.append(0)
                        border_tops.append(0)
                        for gChild in child.children{
                            if gChild.element?.name == "left"{
                                let leftCount = gChild.children.count
                                border_lefts[border_lefts.count - 1] = leftCount
                            }
                            
                            if gChild.element?.name == "right"{
                                let rightCount = gChild.children.count
                                border_rights[border_rights.count - 1] = rightCount
                            }
                            
                            if gChild.element?.name == "top"{
                                let topCount = gChild.children.count
                                border_tops[border_tops.count - 1] = topCount
                            }
                            
                            if gChild.element?.name == "bottom"{
                                let bottomCount = gChild.children.count
                                border_bottoms[border_bottoms.count - 1] = bottomCount
                            }
                            
                        }
                    }
                }
                
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appd.cellXfs = cellXfs
                appd.cellStyleXfs = cellStyleXfs
                appd.border_lefts = border_lefts
                appd.border_rights  = border_rights
                appd.border_bottoms = border_bottoms
                appd.border_tops = border_tops
                appd.formatCodes = formatCodes
                appd.numFmts = numFmts
                appd.numFmtIds = numFmtIds
                
                return xmlString
            }
        }
        return nil
    }
     
    //making now
    func testDeleteString(url:URL? = nil, index:String?) -> String?{
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            
            var patternFound = false
            // Start parsing
            if parser.parse() {
                // Retrieve the extracted part
                let extractedPart = delegate.extractedPart
                //print(extractedPart)
            }
            
            //regular expression
            var xmlString = try? String(contentsOf: url2)
            let xml = XMLHash.parse(xmlString!)
            
            // Define the regular expression pattern D3
            let pattern = "<c r=\"\(String(index!))\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
            
            // Create the regular expression object
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches = regex.matches(in: xmlString!, range: range)
            // Extract matching substrings
            if let match = matches.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    //var replacing0 = matchingSubstring.components(separatedBy: "><v>").first! + "/>"
                    
                    if matchingSubstring.contains("<row r"){
                        matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
                    }
                    
                    if matchingSubstring.hasSuffix("</row>"){
                        matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
                    }
                    
                    let replaced = xmlString?.replacingOccurrences(of: matchingSubstring.description, with: "")
                    return replaced
                }
            }
            
            // Define the regular expression pattern D3
            let pattern2 = "<c[^>]*r=\"\(String(index!))\"[^>]*>.*?</c>"
            //#"<c\s+r="B1".*?</c>"#
            
            // Create the regular expression object
            guard let regex = try? NSRegularExpression(pattern: pattern2, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range2 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches2 = regex.matches(in: xmlString!, range: range2)
            // Extract matching substrings
            if let match = matches2.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    //var replacing0 = matchingSubstring.components(separatedBy: "><v>").first! + "/>"
                    if matchingSubstring.contains("<row r"){
                        matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
                    }
                    
                    if matchingSubstring.hasSuffix("</row>"){
                        matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
                    }
                    
                    let replaced = xmlString?.replacingOccurrences(of: matchingSubstring.description, with: "")
                    return replaced
                }
            }
        }
        return nil
    }
    
    //making now
    func testUpdateString(url:URL? = nil, vIndex:String?, index:String?) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if let url2 = url{
            //get style id
            var styleIdx = -1
            let slocatinIdx = appd.excelStyleLocationAlphabet.firstIndex(of: String(index!))
            
            if (slocatinIdx != nil){
                styleIdx = appd.excelStyleIdx[slocatinIdx!]
            }
            
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            
            var patternFound = false
            // Start parsing
            if parser.parse() {
                // Retrieve the extracted part
                let extractedPart = delegate.extractedPart
                //print(extractedPart)
            }
            
            //regular expression
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
            
            let pattern4 = "<c[^>]*r=\"\(String(index!))\"[^>]*/>"
            
            // Create the regular expression object
            guard let regex4 = try? NSRegularExpression(pattern: pattern4, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range4 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches4 = regex4.matches(in: xmlString!, range: range4)
            
            // Extract matching substrings
            //TODO switch sharedString or value here or not?
            if let match = matches4.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    
                    var newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                    }
                    
                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
                    if cCnt == 2{
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    }
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
            
            
            
            // Define the regular expression pattern D3
            let pattern3 = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>"//"<c r=\"\(String(index!))\".*?/>"
            //#"<c\s+r="B1".*?</c>"#
            
            // Create the regular expression object
            guard let regex3 = try? NSRegularExpression(pattern: pattern3, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range3 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches3 = regex3.matches(in: xmlString!, range: range3)
            
            // Extract matching substrings
            //TODO switch sharedString or value here or not?
            if let match = matches3.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    
                    var newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                    }
                    
                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
                    if cCnt == 2{
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    }
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
            
            // Define the regular expression pattern D3
            //let pattern = "<c.*?r=\"\(String(index!))\".*?>(.*?)</c>"
            //#"<c\s+r="B1".*?</c>"#
            let pattern = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>"

            
            // Create the regular expression object
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches = regex.matches(in: xmlString!, range: range)
            
            // Extract matching substrings
            //TODO switch sharedString or value here or not?
            if let match = matches.first{
            //if let match = matches.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    
                    if matchingSubstring.contains("<row r"){
                        matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
                    }
                    
                    if matchingSubstring.hasSuffix("</row>"){
                        matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
                    }
                    
                    var newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                    }
                    
                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
                    if cCnt == 2{
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    }
                    
//                    xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: "")
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
            let pattern2 = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>"

            
            // Create the regular expression object
            guard let regex2 = try? NSRegularExpression(pattern: pattern2, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range2 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches2 = regex2.matches(in: xmlString!, range: range2)
            
            // Extract matching substrings
            //TODO switch sharedString or value here or not?
            for match in matches2{
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    
                    if matchingSubstring.contains("<row r"){
                        matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
                    }
                    
                    if matchingSubstring.hasSuffix("</row>"){
                        matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
                    }
                    
                    var newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                    }
                    
                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
                    if cCnt == 2{
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    }
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
           
                     
            //get the list of locations
            do {
                let row = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                
                // Retrieve all row tags
                let patternRow = "<row r=\"\(row)\".*?>(.*?)</row>"
                let regexRow = try NSRegularExpression(pattern: patternRow, options: [])

                // Find all matches in the XML snippet
                let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
                
                var targetRowTag = ""
                for match in matchesRow {
                    // Extract the row number from the match
                    let nsRange = match.range(at: 1) // Use the capture group index
                    if let range = Range(nsRange, in: xmlString!) {
                        if let matchRange = Range(match.range, in: xmlString!) {
                            targetRowTag = String(xmlString![matchRange])
                            if targetRowTag.contains("/><row"){
                                let items = targetRowTag.components(separatedBy: "/><row")
                                if (items.first != nil){
                                    targetRowTag = items.first! + "/>"
                                    print(targetRowTag)
                                }
                            }
                        }
                    }
                }

                // Create a regular expression pattern to match the r attribute C4,C44
                let pattern = #"r=\"([A-Z]+\d+)\""#
                
                // Create a regular expression object
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                
                // Find all matches in the XML snippet
                let matches = regex.matches(in: targetRowTag, options: [], range: NSRange(location: 0, length: targetRowTag.utf16.count))
                
                // Extract the r values from the matches
                var rValues = matches.map { match -> String in
                    guard let range = Range(match.range(at: 1), in: xmlString!) else {
                        return ""
                    }
                    return String(targetRowTag[range])
                }
                
                // Output the list of r values D1, G1
                //rValues.append(String(index!))
                
                let rValues2 = rValues.sorted { (r1, r2) -> Bool in
                    // Extract the alphabetic part of the cell reference
                    let alphabeticPart1 = r1.prefix(while: { $0.isLetter })
                    let alphabeticPart2 = r2.prefix(while: { $0.isLetter })
                    
                    // If the alphabetic parts are different, compare them
                    if alphabeticPart1 != alphabeticPart2 {
                        return alphabeticPart1 < alphabeticPart2
                    }
                    
                    // If the alphabetic parts are the same, compare the numeric parts
                    let numericPart1 = Int(r1.drop(while: { !$0.isNumber })) ?? 0
                    let numericPart2 = Int(r2.drop(while: { !$0.isNumber })) ?? 0
                    
                    return numericPart1 < numericPart2
                }
                
                //is it first
                if let idx = rValues2.firstIndex(of: String(index!)) {
                    print("rowindex",idx)
                    if idx == rValues2.count-1{
                        var newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                        
                        if styleIdx > 0{
                            newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                        }
                        
                        var replacing = targetRowTag.replacingOccurrences(of: "</row>", with: "")
                        replacing = replacing + newElement + "</row>"
                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                        print(replaced)
                        let validator = XMLValidator()
                        if validator.validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                            return replaced
                        } else {
                            print("XML is not valid.")
                            print(replaced)
                            return backUpXmlString
                        }
                    }else{
                    // Define the regular expression pattern D3
                    let pattern1 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)/>"
                    let pattern2 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
                    
                    let combinedPattern = "\(pattern1)|\(pattern2)"

                        // Create the regular expression object
                        guard let regex2 = try? NSRegularExpression(pattern: combinedPattern, options: []) else {
                            fatalError("Failed to create regular expression")
                        }
                    
                    // Find matches in the XML string
                    let range = NSRange(targetRowTag.startIndex..<targetRowTag.endIndex, in: targetRowTag)
                    let matches = regex2.matches(in: targetRowTag, range: range)
                    
                    // Extract matching substrings
                        if let match = matches.first{
                            if let matchRange = Range(match.range, in: targetRowTag) {
                                var matchingSubstring = targetRowTag[matchRange].description
                                
                                if matchingSubstring.contains("<row r"){
                                    matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
                                }
                                
                                if matchingSubstring.hasSuffix("</row>"){
                                    matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
                                }
                                
                                let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
                                var items = modified.components(separatedBy: "!")
                                //first is always ""
                                let item = items[1] ?? ""
                                print("item", item)
                                
                                var newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                                if styleIdx > 0{
                                    newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                                }
                                
                                // Find the correct position to insert the new element
                                if let range = xmlString?.range(of: item) {
                                    // Insert the new element after the element with r="J2"
                                    xmlString?.insert(contentsOf: newElement, at: range.lowerBound)
                                    let validator = XMLValidator()
                                    if validator.validateXML(xmlString: xmlString!) {
                                        print("XML is valid.")
                                    } else {
                                        print("XML is not valid.")
                                        print(xmlString)
                                        return backUpXmlString
                                    }
                                }
                            }
                        }
                    }
                
                }else{
                    //first c tag with sharedstring idx == nil
                    var sortedRowstr = ""
                    if targetRowTag == ""{
                        var newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c></row>"
                        if styleIdx > 0{
                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\" t=\"s\"><v>\(String(vIndex!))</v></c></row>"
                        }
                        
                        var replaced = xmlString?.replacingOccurrences(of: "<sheetData>", with: newElement)
                        
                        if replaced!.contains("<sheetData/>"){
                            replaced = xmlString?.replacingOccurrences(of: "<sheetData/>", with: newElement + "</sheetData>")
                        }
                        
                        xml = XMLHash.parse(replaced!)
                        
                        if let sortedRows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children{
                            // Sort the rows based on some criteria (e.g., the value of the "r" attribute of cells)
                            let sortedCells = sortedRows.sorted { (row1, row2) -> Bool in
                                guard
                                      let text1 = row1.element?.attribute(by: "r")?.text,
                                      let text2 = row2.element?.attribute(by: "r")?.text
                                       
                                else {
                                    return false
                                }
                                print("guard",text1)
                                print("gurard",text2)
                                return text1 < text2
                            }
                            
                            // Use the sorted cells
                            // For example, print them
                            for cell in sortedCells {
                                sortedRowstr += cell.description
                            }
                            print("row",sortedRowstr)
                        }

                        if let sheetDataSubstring = extractSheetDataSubstring(from: replaced!) {
                            let rowSortedStr = replaced!.replacingOccurrences(of: sheetDataSubstring, with:"<sheetData>" + sortedRowstr + "</sheetData>")
                            xml = XMLHash.parse(rowSortedStr)
                        }
                           
                        if let rows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children {
                            // Iterate through the rows
                            for row in rows {
                                // Sort the child elements (cells) within each row based on some criteria
                                let sortedCells = row.children.sorted { (cell1: XMLIndexer, cell2: XMLIndexer) -> Bool in
                                    // Compare cells based on some criteria (e.g., column index)
                                    if let name1 = cell1.element?.attribute(by: "r")?.text, let name2 = cell2.element?.attribute(by: "r")?.text {
                                        let indices1 = extractIndices(from: name1)
                                        let indices2 = extractIndices(from: name2)
                                        let ary = [indices1,indices2]
                                        
                                        let sortedArray = ary.sorted { (string1, string2) -> Bool in
                                            return string1! < string2! // Compare strings in descending order
                                        }
                                        
                                          
                                        
                                        // Rows are equal, compare columns
                                        if indices1!.column < indices2!.column{
                                            return name1 < name2
                                        }
                                    }
                                        
                                       
                                    return false // Modify as per your sorting criteria
                                }
                                
                                // Convert sortedCells back to an array of XMLIndexer objects
                                let sortedCellsArray: [XMLIndexer] = sortedCells.map { $0 }
                                
                                // Update the children of the current row with the sorted cells
                                // Note: You may need to find an alternative way to update the children of the row element
                                // row.children = sortedCellsArray // This will not work due to read-only property
                                
                                // Print the sorted cells (optional)
                                for cell in sortedCellsArray {
                                    print("updateString",cell)
                                }
                            }
                        } else {
                            print("No rows found or there are no children under the specified path")
                        }
                        
                        let validator = XMLValidator()
                        if validator.validateXML(xmlString: xml.description) {
                            print("XML is valid.")
                            return xml.description
                        } else {
                            print("XML is not valid.")
                            print(xml.description)
                            return backUpXmlString
                        }
                    }else{
                        //targetRowTag   "<row r=\"1\"><c r=\"B1\" t=\"s\"><v>78</v></c></row>"
                        var rowPart = targetRowTag
                        if rowPart.hasSuffix("/>"){
                            rowPart = rowPart.replacingOccurrences(of: "/>", with: ">")
                        }
                        
                        //rowPart = rowPart.components(separatedBy: "><c").first!
                        if !rowPart.hasSuffix(">"){
                            rowPart = rowPart + ">"
                        }
                        let rowNumber = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                        var newElement2 = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                        
                        if styleIdx > 0{
                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                        }
                        
                        var replacing = rowPart.replacingOccurrences(of: "</row>", with: "")
                        replacing = replacing + newElement2 + "</row>"
                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                        
                        let validator0 = XMLValidator()
                        if validator0.validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                        } else {
                            print("XML is not valid.")
                            print(xmlString)
                            return backUpXmlString
                        }
                        let old = xmlString
                        rowPart = ""
                        xml = XMLHash.parse(replaced!)
                        if let rows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children {
                            // Iterate through the rows
                            for row in rows {
                                // Sort the child elements (cells) within each row based on some criteria
                                let sortedCells = row.children.sorted { (cell1: XMLIndexer, cell2: XMLIndexer) -> Bool in
                                    // Compare cells based on some criteria (e.g., column index)
                                    if let name1 = cell1.element?.attribute(by: "r")?.text, let name2 = cell2.element?.attribute(by: "r")?.text {
                                        let indices1 = extractIndices(from: name1)
                                        let indices2 = extractIndices(from: name2)
                                        if indices1?.row.description == rowNumber{
                                            
                                            // Rows are equal, compare columns
                                            if indices1!.column < indices2!.column{
                                                return name1 < name2
                                            }
                                        }
                                    }
                                        
                                    return false // Modify as per your sorting criteria
                                }
                                
                                // Convert sortedCells back to an array of XMLIndexer objects
                                let sortedCellsArray: [XMLIndexer] = sortedCells.map { $0 }
                                
                            
                                
                                // Update the children of the current row with the sorted cells
                                // Note: You may need to find an alternative way to update the children of the row element
                                // row.children = sortedCellsArray // This will not work due to read-only property
                                
                                // Print the sorted cells (optional)
                                for cell in sortedCellsArray {
                                    let name1 = (cell.element?.attribute(by: "r")?.text)!
                                    let indices1 = extractIndices(from: name1)
                                    if indices1?.row.description == rowNumber{
                                        print(cell)
                                        rowPart += cell.description
                                    }
                                }
                            }
                        } else {
                            print("No rows found or there are no children under the specified path")
                        }
                        
                        rowPart = rowPart.replacingOccurrences(of: "</row>", with: "")
                        let final = old!.replacingOccurrences(of: targetRowTag, with: "<row r=\"\(row)\">" + rowPart + "</row>")
                        let validator = XMLValidator()
                        if validator.validateXML(xmlString: final) {
                            print("XML is valid.")
                            return final
                        } else {
                            print("XML is not valid.")
                            print("xmlDESC",final)
                            return backUpXmlString
                        }
                    }
                }
                
            } catch {
                print("Error: \(error)")
            }
            
            
        }
        return nil
    }
    
    //todo creating
    func testUpdateValue(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //get style id
        var styleIdx = -1
        let slocatinIdx = appd.excelStyleLocationAlphabet.firstIndex(of: String(index!))
        var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
        
        if (slocatinIdx != nil){
            styleIdx = appd.excelStyleIdx[slocatinIdx!]
        }
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            
            var patternFound = false
            // Start parsing
            if parser.parse() {
                // Retrieve the extracted part
                let extractedPart = delegate.extractedPart
                //print(extractedPart)
            }
            
            //regular expression
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
            
            // Define the regular expression pattern D3
            let pattern4 = "<c[^>]*r=\"\(String(index!))\"[^>]*/>"//"<c r=\"\(String(index!))\".*?/>"
            //#"<c\s+r="B1".*?</c>"#
            
            // Create the regular expression object
            guard let regex4 = try? NSRegularExpression(pattern: pattern4, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range4 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches4 = regex4.matches(in: xmlString!, range: range4)
            
            // Extract matching substrings
            //TODO switch sharedString or value here or not?
            if let match = matches4.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\"><v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\"><v>\(String(vIndex!))</v></c>"
                    }
                    
                    //"<c r=\"D14\" s=\"54\"><v>0.375</v></c><c r=\"E14\" s=\"55\"><v>0.75</v></c><c r=\"F14\" s=\"56\"><v>0.5</v></c><c r=\"G14\" s=\"57\"><v>0.54166666666666663</v></c><c r=\"H14\" s=\"56\"/>"
                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
                    if cCnt == 2{
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    }
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
            // Define the regular expression pattern D3
            let pattern3 = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>"//"<c r=\"\(String(index!))\".*?/>"
            //#"<c\s+r="B1".*?</c>"#
            
            // Create the regular expression object
            guard let regex3 = try? NSRegularExpression(pattern: pattern3, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range3 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches3 = regex3.matches(in: xmlString!, range: range3)
            
            // Extract matching substrings
            //TODO switch sharedString or value here or not?
            if let match = matches3.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\"><v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\"><v>\(String(vIndex!))</v></c>"
                    }
                    
                    //"<c r=\"D14\" s=\"54\"><v>0.375</v></c><c r=\"E14\" s=\"55\"><v>0.75</v></c><c r=\"F14\" s=\"56\"><v>0.5</v></c><c r=\"G14\" s=\"57\"><v>0.54166666666666663</v></c><c r=\"H14\" s=\"56\"/>"
                    
                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
                    if cCnt == 2{
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    }
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
            
            // Define the regular expression pattern D3
            let pattern = "<c.*?r=\"\(String(index!))\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
            
            // Create the regular expression object
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches = regex.matches(in: xmlString!, range: range)
            
            // Extract matching substrings
            //TODO switch sharedString or value here or not?
            if let match = matches.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    //let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
                    //var items = modified.components(separatedBy: "!")
                    //first is always ""
                    if matchingSubstring.contains("<row r"){
                        matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
                    }
                    
                    if matchingSubstring.hasSuffix("</row>"){
                        matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
                    }
                    
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\"><v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\"><v>\(String(vIndex!))</v></c>"
                    }
                    
                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
                    if cCnt == 2{
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    }
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
            let pattern2 = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>"
            
            // Create the regular expression object
            guard let regex2 = try? NSRegularExpression(pattern: pattern2, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range2 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches2 = regex2.matches(in: xmlString!, range: range2)
            
            // Extract matching substrings
            //TODO switch sharedString or value here or not?
            for match in matches2 {
                if let matchRange = Range(match.range, in: xmlString!) {
                    var matchingSubstring = xmlString![matchRange].description
                    
                    if matchingSubstring.contains("<row r"){
                        matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
                    }
                    
                    if matchingSubstring.hasSuffix("</row>"){
                        matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
                    }
                    
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\"><v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\"><v>\(String(vIndex!))</v></c>"
                    }
                    
                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
                    if cCnt == 2{
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    }
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
           
  
            //get the list of locations
            do {
                let row = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                
                // Retrieve all row tags
                let patternRow = "<row r=\"\(row)\".*?>(.*?)</row>"
                let regexRow = try NSRegularExpression(pattern: patternRow, options: [])

                // Find all matches in the XML snippet
                let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
                
                var targetRowTag = ""
                for match in matchesRow {
                    // Extract the row number from the match
                    let nsRange = match.range(at: 1) // Use the capture group index
                    if let range = Range(nsRange, in: xmlString!) {
                        if let matchRange = Range(match.range, in: xmlString!) {
                            targetRowTag = String(xmlString![matchRange]).description
                            if targetRowTag.contains("/><row"){
                                let items = targetRowTag.components(separatedBy: "/><row")
                                if (items.first != nil){
                                    targetRowTag = items.first! + "/>"
                                    print(targetRowTag)
                                }
                            }
                        }
                    }
                }

                // Create a regular expression pattern to match the r attribute C4,C44
                let pattern = #"r=\"([A-Z]+\d+)\""#
                
                // Create a regular expression object
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                
                // Find all matches in the XML snippet
                let matches = regex.matches(in: targetRowTag, options: [], range: NSRange(location: 0, length: targetRowTag.utf16.count))
                
                // Extract the r values from the matches
                var rValues = matches.map { match -> String in
                    guard let range = Range(match.range(at: 1), in: xmlString!) else {
                        return ""
                    }
                    return String(targetRowTag[range])
                }
                
                // Output the list of r values D1, G1
                //rValues.append(String(index!))
                
                let rValues2 = rValues.sorted { (r1, r2) -> Bool in
                    // Extract the alphabetic part of the cell reference
                    let alphabeticPart1 = r1.prefix(while: { $0.isLetter })
                    let alphabeticPart2 = r2.prefix(while: { $0.isLetter })
                    
                    // If the alphabetic parts are different, compare them
                    if alphabeticPart1 != alphabeticPart2 {
                        return alphabeticPart1 < alphabeticPart2
                    }
                    
                    // If the alphabetic parts are the same, compare the numeric parts
                    let numericPart1 = Int(r1.drop(while: { !$0.isNumber })) ?? 0
                    let numericPart2 = Int(r2.drop(while: { !$0.isNumber })) ?? 0
                    
                    return numericPart1 < numericPart2
                }
                
                //is it first
                if let idx = rValues2.firstIndex(of: String(index!)) {
                    print("rowindex",idx)
                    if idx == rValues2.count-1{
                        var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\"><v>\(String(vIndex!))</v></c>"
                        
                        if styleIdx > 0{
                            newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\"><v>\(String(vIndex!))</v></c>"
                        }
                        
                        var replacing = targetRowTag.replacingOccurrences(of: "</row>", with: "")
                        replacing = replacing + newElement + "</row>"
                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                        print(replaced)
                        let validator = XMLValidator()
                        if validator.validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                            return replaced
                        } else {
                            print("XML is not valid.")
                            print(replaced)
                            return backUpXmlString
                        }
                    }else{
                    // Define the regular expression pattern D3
                    let pattern1 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)/>"
                    let pattern2 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
                    
                    let combinedPattern = "\(pattern1)|\(pattern2)"

                        // Create the regular expression object
                        guard let regex2 = try? NSRegularExpression(pattern: combinedPattern, options: []) else {
                            fatalError("Failed to create regular expression")
                        }
                    
                    // Find matches in the XML string
                    let range = NSRange(targetRowTag.startIndex..<targetRowTag.endIndex, in: targetRowTag)
                    let matches = regex2.matches(in: targetRowTag, range: range)
                    
                    // Extract matching substrings
                        if let match = matches.first{
                            if let matchRange = Range(match.range, in: targetRowTag) {
                                var matchingSubstring = targetRowTag[matchRange].description
                                
                                if matchingSubstring.contains("<row r"){
                                    matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
                                }
                                
                                if matchingSubstring.hasSuffix("</row>"){
                                    matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
                                }
                                
                                let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
                                var items = modified.components(separatedBy: "!")
                                //first is always ""
                                let item = items[1] ?? ""
                                print("item", item)
                                var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\"><v>\(String(vIndex!))</v></c>"
                                
                                if styleIdx > 0{
                                    newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\"><v>\(String(vIndex!))</v></c>"
                                }

                                // Find the correct position to insert the new element
                                if let range = xmlString?.range(of: item) {
                                    // Insert the new element after the element with r="J2"
                                    xmlString?.insert(contentsOf: newElement, at: range.lowerBound)
                                    let validator = XMLValidator()
                                    if validator.validateXML(xmlString: xmlString!) {
                                        print("XML is valid.")
                                    } else {
                                        print("XML is not valid.")
                                        print(xmlString)
                                        return backUpXmlString
                                    }
                                }
                            }
                        }
                    }
                
                }else{
                    //row not exists
                    //first c tag with sharedstring idx == nil
                    var sortedRowstr = ""
                    if targetRowTag == ""{
                //"<sheetData><row r=\"4\"><c r=\"A4\" s=\"1\"><v>10</v></c></row>"
                        //var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
                        var newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" ><v>\(String(vIndex!))</v></c></row>"
                        if (sValueId != nil && sValueId! != 0){
                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\"><v>\(String(vIndex!))</v></c></row>"
                        }
                        
                        if styleIdx > 0{
                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\"><v>\(String(vIndex!))</v></c></row>"
                        }
                        
                        var replaced = xmlString?.replacingOccurrences(of: "<sheetData>", with: newElement)
                        
                        if ((replaced?.contains("<sheetData/>")) != nil){
                            replaced = replaced?.replacingOccurrences(of: "<sheetData/>", with: newElement + "</sheetData>")
                        }
                       
                        xml = XMLHash.parse(replaced!)
                        
                        if let sortedRows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children{
                            // Sort the rows based on some criteria (e.g., the value of the "r" attribute of cells)
                            let sortedCells = sortedRows.sorted { (row1, row2) -> Bool in
                                guard
                                      let text1 = row1.element?.attribute(by: "r")?.text,
                                      let text2 = row2.element?.attribute(by: "r")?.text
                                       
                                else {
                                    return false
                                }
                                print("guard",text1)
                                print("gurard",text2)
                                return text1 < text2
                            }
                            
                            // Use the sorted cells
                            // For example, print them
                            for cell in sortedCells {
                                sortedRowstr += cell.description
                            }
                            print("row",sortedRowstr)
                        }

                        if let sheetDataSubstring = extractSheetDataSubstring(from: replaced!) {
                            let rowSortedStr = replaced!.replacingOccurrences(of: sheetDataSubstring, with:"<sheetData>" + sortedRowstr + "</sheetData>")
                            xml = XMLHash.parse(rowSortedStr)
                        }
                           
                        if let rows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children {
                            // Iterate through the rows
                            for row in rows {
                                // Sort the child elements (cells) within each row based on some criteria
                                let sortedCells = row.children.sorted { (cell1: XMLIndexer, cell2: XMLIndexer) -> Bool in
                                    // Compare cells based on some criteria (e.g., column index)
                                    if let name1 = cell1.element?.attribute(by: "r")?.text, let name2 = cell2.element?.attribute(by: "r")?.text {
                                        let indices1 = extractIndices(from: name1)
                                        let indices2 = extractIndices(from: name2)
                                        let ary = [indices1,indices2]
                                        
                                        let sortedArray = ary.sorted { (string1, string2) -> Bool in
                                            return string1! < string2! // Compare strings in descending order
                                        }
                              
                                        
                                        // Rows are equal, compare columns
                                        if indices1!.column < indices2!.column{
                                            return name1 < name2
                                        }
                                    }
                                        
                                       
                                    return false // Modify as per your sorting criteria
                                }
                                
                                // Convert sortedCells back to an array of XMLIndexer objects
                                let sortedCellsArray: [XMLIndexer] = sortedCells.map { $0 }
                                
                                // Update the children of the current row with the sorted cells
                                // Note: You may need to find an alternative way to update the children of the row element
                                // row.children = sortedCellsArray // This will not work due to read-only property
                                
                                // Print the sorted cells (optional)
                                for cell in sortedCellsArray {
                                    print(cell)
                                }
                            }
                        } else {
                            print("No rows found or there are no children under the specified path")
                        }
                        

                        
                        let validator = XMLValidator()
                        if validator.validateXML(xmlString: xml.description) {
                            print("XML is valid.")
                            return xml.description
                        } else {
                            print("XML is not valid.")
                            print(xml.description)
                            return backUpXmlString
                        }
                    }else{
                        //row exists c element exists
                        //targetRowTag   "<row r=\"1\"><c r=\"B1\" t=\"s\"><v>78</v></c></row>"
                        var rowPart = targetRowTag
                        if rowPart.hasSuffix("/>"){
                            rowPart = rowPart.replacingOccurrences(of: "/>", with: ">")
                        }
                        if !rowPart.hasSuffix(">"){
                            rowPart = rowPart + ">"
                        }
                        let rowNumber = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                        //var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
                        var newElement2 = "<c r=\"\(String(index!))\" ><v>\(String(vIndex!))</v></c>"
                        if (sValueId != nil && sValueId! != 0){
                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\"><v>\(String(vIndex!))</v></c>"
                        }
                        
                        if (styleIdx > 0){
                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\"><v>\(String(vIndex!))</v></c>"
                        }
                        
                        
                        
                        var replacing = targetRowTag.replacingOccurrences(of: "</row>", with: "")
                        replacing = replacing + newElement2 + "</row>"
                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                        let validator0 = XMLValidator()
                        if validator0.validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                        } else {
                            print("XML is not valid.")
                            print(xmlString)
                            return backUpXmlString
                        }
                        let old = xmlString
                        rowPart = ""
                        xml = XMLHash.parse(replaced!)
                        if let rows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children {
                            // Iterate through the rows
                            for row in rows {
                                // Sort the child elements (cells) within each row based on some criteria
                                let sortedCells = row.children.sorted { (cell1: XMLIndexer, cell2: XMLIndexer) -> Bool in
                                    // Compare cells based on some criteria (e.g., column index)
                                    if let name1 = cell1.element?.attribute(by: "r")?.text, let name2 = cell2.element?.attribute(by: "r")?.text {
                                        let indices1 = extractIndices(from: name1)
                                        let indices2 = extractIndices(from: name2)
                                        if indices1?.row.description == rowNumber{
                                            
                                            // Rows are equal, compare columns
                                            if indices1!.column < indices2!.column{
                                                return name1 < name2
                                            }
                                        }
                                    }
                                        
                                    return false // Modify as per your sorting criteria
                                }
                                
                                // Convert sortedCells back to an array of XMLIndexer objects
                                let sortedCellsArray: [XMLIndexer] = sortedCells.map { $0 }
                                
                            
                                
                                // Update the children of the current row with the sorted cells
                                // Note: You may need to find an alternative way to update the children of the row element
                                // row.children = sortedCellsArray // This will not work due to read-only property
                                
                                // Print the sorted cells (optional)
                                for cell in sortedCellsArray {
                                    let name1 = (cell.element?.attribute(by: "r")?.text)!
                                    let indices1 = extractIndices(from: name1)
                                    if indices1?.row.description == rowNumber{
                                        print(cell)
                                        rowPart += cell.description
                                    }
                                }
                            }
                        } else {
                            print("No rows found or there are no children under the specified path")
                        }
                        
                        rowPart = rowPart.replacingOccurrences(of: "</row>", with: "")
                        rowPart = "<row r=\"\(row)\">" + rowPart + "</row>"
                        let final = old!.replacingOccurrences(of: targetRowTag, with: rowPart)
                        let validator = XMLValidator()
                        if validator.validateXML(xmlString: final) {
                            print("XML is valid.")
                            return final
                        } else {
                            print("XML is not valid.")
                            print("xmlDESC",final)
                            return backUpXmlString
                        }
                    }
                }
                
            } catch {
                print("Error: \(error)")
            }
       
            
        }
        return nil
    }
    
    func testStringUniqueAry(url:URL? = nil)->[String]?{
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            if (xmlData != nil){
                let parser = XMLParser(data: xmlData!)
                // Set XMLParserDelegate
                let delegate = SharedStringsParserDelegate()
                parser.delegate = delegate
                
                if parser.parse() {
                    print("si",delegate.sis)
                    print("si count", delegate.sis.count)
                    //var xmlString = try? String(contentsOf: url2)
                    
                    //try? xmlString?.write(to: url2, atomically: true, encoding: .utf8)
                    return delegate.sis
                }
            }
        }
        return []
    }
    
    func testStringOldUniqueCount(url:URL? = nil){
        if let url2 = url{
            var xmlString = try? String(contentsOf: url2)
            if (xmlString != nil){
                let pattern = "uniqueCount=\"([^\"]+)\"" //"count=\"([^\"]+)\""
                
                // Create a regular expression object
                guard let regex = try? NSRegularExpression(pattern: pattern) else {
                    fatalError("Invalid regular expression pattern")
                }
                
                // Search for matches in the XML string
                if let match = regex.firstMatch(in: xmlString!, range: NSRange(xmlString!.startIndex..., in: xmlString!)) {
                    // Extract the matched substring
                    let countPartRange = Range(match.range(at: 1), in: xmlString!)!
                    let countPart = String(xmlString![countPartRange])
                    
                    print("Extracted count part:", countPart)
                } else {
                    print("No match found")
                }
            }
        }
    }

    func checkSharedStringsIndex(url:URL? = nil, SSlist:[String] = [], word:String)->(Int?,String?){
        var new_count : Int?
        var new_count2 : Int?
        
        if word == ""{
            return (nil,nil)
        }
        
        if word != "" && (Float(word) != nil) {
            return (nil,nil)
        }
        
        if let url2 = url{
            var xmlString = try? String(contentsOf: url2)
            let INDEX_1_DIFF_ADJUST = 0
            if (xmlString != nil){
                //
                if let idx = SSlist.firstIndex(of:word) {
                    print("String exists at", idx + INDEX_1_DIFF_ADJUST)
                    return (idx + INDEX_1_DIFF_ADJUST, xmlString)
                } else {
                    print("String not exists.")
                    // Find the position to insert the new <si> element
                    if let range = xmlString!.range(of: "</sst>") {
                        // Construct the new <si> element
                        var newSIElement = "<si><t>" + word + "</t></si>"
                        
                        // Insert the new <si> element at the end of <sst>
                        xmlString?.replaceSubrange(range, with: "\(newSIElement)</sst>")
                        
                        let xmlData = try? Data(contentsOf: url2)
                        
                        // Create an XML parser and set its delegate
                        let parser = XMLParser(data: xmlData!)
                        let delegate = XMLParserHelper()
                        parser.delegate = delegate
                        // Parse the XML data
                        if parser.parse() {
                            print("Number of <si> elements:", delegate.siElementCount)
                            new_count = delegate.siElementCount
                        } else {
                            print("Failed to parse XML data.")
                        }
                        print("New <si> element inserted successfully.")
                        
                        return (SSlist.count ,xmlString)
                    } else {
                        print("Failed to find </sst> in the XML data.")
                    }
                }
            }
        }
        return (nil,nil)
    }
    
    
    func testSandBox(fp: String = "", url: URL? = nil) -> URL? {
        do {
                // Get the sandbox directory for documents
                if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
                //
                if FileManager.default.fileExists(atPath: fp) {
                            // The specified path exists, continue with your code
                            print("File or directory exists at path: \(fp)")
                    let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                    let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                            
                    // Check if the subdirectory already exists
                    if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                        // Create the subdirectory
                        try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                        print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                    } else {
                        // Subdirectory already exists
                        print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                        var files = try FileManager.default.contentsOfDirectory(at:
                                                                                    subdirectoryURL, includingPropertiesForKeys: nil)
                        for fileURL in files {
                           do {
                               try FileManager.default.removeItem(at: fileURL)
                               print("Deleted file:", fileURL.lastPathComponent)
                           } catch {
                               print("Error deleting file:", error)
                           }
                        }
                        
                        files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                        print("Subdirectory is now empty",files)
                    }
                    
                    // Construct the URL for the destination file
                    let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                    //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
                   
                    // Check if the file already exists at the destination
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        print("File already exists at the destination.")
                        // Remove destination file if it already exists
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                    } else {
                        // Move the file to the subdirectory
                        try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                        print("File moved successfully to: \(destinationURL.path)")
                    }
                    
                    do {
                        //unzip
                        let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                        print("File unzipped successfully.")
                    } catch {
                        print("Error unzipping file: \(error)")
                    }
                    
                    
                    
                    do {
                        //delete imported2.zip or imported2.xlsx
                        try FileManager.default.removeItem(at: destinationURL)
                        print("Deleted zip file:", destinationURL)
                    } catch {
                        print("Error deleting file:", error)
                    }
                    
                    //shardString update test
                    let shardStringXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("sharedStrings.xml")
                    
                    //value and string update test
                    let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet1.xml")
                    
                    //extract sytles read only
                    let styleXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("styles.xml")
                    let modifiedStylesStr = testExtractStyle(url:styleXMLURL)
                    //update to it contains date numFmt and other format
                    if (modifiedStylesStr != nil){
                        try? modifiedStylesStr!.write(to: styleXMLURL, atomically: true, encoding: .utf8)
                        
                        var xmlString = try? String(contentsOf: styleXMLURL)
                        print(xmlString)
                    }
                    
                    
                    let oldAry = testStringUniqueAry(url: shardStringXMLURL)
                    
//                    let idx = checkSharedStringsIndex(url: shardStringXMLURL,SSlist:oldAry!,word: "goodbyework")
//                    
//                    
//                        let replacedWithNewString = testUpdateString(url:worksheetXMLURL, vIndex: String(idx!), index: "N2")
//                        // Write the modified XML data back to the file
//                    if(idx != nil && replacedWithNewString != nil){
//                        try? replacedWithNewString!.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
//                    }
                    
                    let newAry = testStringUniqueAry(url: shardStringXMLURL)
                    
                    let oldUniqueCount = testStringOldUniqueCount(url: shardStringXMLURL)
                    
                    let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                    var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                    let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                        for file in sheetFiles {
                            print("Found .xml file:", file.lastPathComponent)
                        }
                    print("sheetFiles: ", sheetXMLFiles)
                    
                    
                    //ready to zip
                    var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    let fpURL = URL(fileURLWithPath: fp)
                    let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                    //appendingPathComponent("imported2.xlsx")
                    let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                    let rlt = try FileManager.default.copyItem(at: zipFilePath, to: productURL)
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Done: ", files)
                    
                    return productURL

                    
                } else {
                    // Handle the case where the specified path doesn't exist
                    print("File or directory does not exist at path: \(fp)")
                }
                
            } else {
                print("Document directory not found.")
            }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func testReadXMLSandBox(fp: String = "", url: URL? = nil) -> URL? {
        do {
                // Get the sandbox directory for documents
                if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
                //
                if FileManager.default.fileExists(atPath: fp) {
                            // The specified path exists, continue with your code
                            print("File or directory exists at path: \(fp)")
                    let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                    let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                            
                    // Check if the subdirectory already exists
                    if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                        // Create the subdirectory
                        try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                        print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                    } else {
                        // Subdirectory already exists
                        print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                        var files = try FileManager.default.contentsOfDirectory(at:
                                                                                    subdirectoryURL, includingPropertiesForKeys: nil)
                        for fileURL in files {
                           do {
                               try FileManager.default.removeItem(at: fileURL)
                               print("Deleted file:", fileURL.lastPathComponent)
                           } catch {
                               print("Error deleting file:", error)
                           }
                        }
                        
                        files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                        print("Subdirectory is now empty",files)
                    }
                    
                    // Construct the URL for the destination file
                    let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                    //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
                   
                    // Check if the file already exists at the destination
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        print("File already exists at the destination.")
                        // Remove destination file if it already exists
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                    } else {
                        // Move the file to the subdirectory
                        try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                        print("File moved successfully to: \(destinationURL.path)")
                    }
                    
                    do {
                        //unzip
                        let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                        print("File unzipped successfully.")
                    } catch {
                        print("Error unzipping file: \(error)")
                    }
                    
                    
                    
                    do {
                        //delete imported2.zip or imported2.xlsx
                        try FileManager.default.removeItem(at: destinationURL)
                        print("Deleted zip file:", destinationURL)
                    } catch {
                        print("Error deleting file:", error)
                    }
                   
                    
                    //shardString update test
                    let shardStringXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("sharedStrings.xml")
                    
                    //value and string update test
                    let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet1.xml")
                    
                    //extract sytles
                    let styleXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("styles.xml")
                    let modifiedStylesStr = testExtractStyle(url:styleXMLURL)
                    //update to it contains date numFmt and other format
                    
                    let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                    var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                    let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                        for file in sheetFiles {
                            print("Found .xml file:", file.lastPathComponent)
                        }
                    print("sheetFiles: ", sheetXMLFiles)
                    
                    return nil

                    
                } else {
                    // Handle the case where the specified path doesn't exist
                    print("File or directory does not exist at path: \(fp)")
                }
                
            } else {
                print("Document directory not found.")
            }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    
    func testUpdateStringBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int?) -> URL? {
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                }
                
                //TODO update sytle.xml here
                let styleXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("styles.xml")
                let modifiedStylesStr = testExtractStyle(url:styleXMLURL)
                //update to it contains date numFmt and other format
                if (modifiedStylesStr != nil){
                    try? modifiedStylesStr!.write(to: styleXMLURL, atomically: true, encoding: .utf8)
                    var xmlString = try? String(contentsOf: styleXMLURL)
                    print(xmlString)
                }
                
                    
                //shardString update test
                let shardStringXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("sharedStrings.xml")
                
                //check missing files and create the missing ones
                if !FileManager.default.fileExists(atPath: shardStringXMLURL.path) {
                    let content = """
                    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                    <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="1" uniqueCount="1"></sst>
                    """
                    
                    try? content.write(to: shardStringXMLURL, atomically: true, encoding: .utf8)
                }
                
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                
                let oldAry = testStringUniqueAry(url: shardStringXMLURL)
                
                if input.count > 0{
                    var check = false
                    //sharedString
                    let shredStringId = checkSharedStringsIndex(url: shardStringXMLURL,SSlist:oldAry!,word: input)
                    if shredStringId.0 == nil && (Float(input) != nil){
                        //value update
                        let replacedWithNewString = testUpdateValue(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt) ?? ""//A3
                        // Write the modified XML data back to the file
                        if(replacedWithNewString != ""){
                            try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                        }
                        check = true
                    }
                    if (shredStringId.0 != nil){
                        let replacedWithNewString = testUpdateString(url:worksheetXMLURL, vIndex: String(shredStringId.0!), index: cellIdxString)//A3
                        // Write the modified XML data back to the file
                        if(!check && replacedWithNewString != nil && replacedWithNewString != ""){
                            try? replacedWithNewString!.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                            
                            // Write the modified XML data back to the file
                            try? shredStringId.1!.write(to: shardStringXMLURL, atomically: true, encoding: .utf8)
                        }
                    }
                        
                }else{
                    //delete
                    let replacedWithNewString = testDeleteString(url:worksheetXMLURL, index: cellIdxString)//A3
                    // Write the modified XML data back to the file
                    if(replacedWithNewString != nil && replacedWithNewString != ""){
                        try? replacedWithNewString!.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                    }
                }
                    
                let newAry = testStringUniqueAry(url: shardStringXMLURL)
                
                let oldUniqueCount = testStringOldUniqueCount(url: shardStringXMLURL)
                
                
                
              
                
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                    for file in sheetFiles {
                        print("Found .xml file:", file.lastPathComponent)
                    }
                print("sheetFiles: ", sheetXMLFiles)
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return nil

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
            }
            
        } else {
            print("Document directory not found.")
        }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func writeXlsxEmail(fp: String = "", url: URL? = nil) -> URL? {
        do {
        // Get the sandbox directory for documents
        if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
        let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
        //
        if FileManager.default.fileExists(atPath: fp) {
                    // The specified path exists, continue with your code
                    print("File or directory exists at path: \(fp)")
            let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
            let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                    
            // Check if the subdirectory already exists
            if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                // Create the subdirectory
                try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
            } else {
                // Subdirectory already exists
                print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                var files = try FileManager.default.contentsOfDirectory(at:
                                                                            subdirectoryURL, includingPropertiesForKeys: nil)
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Subdirectory is now empty",files)
            }
            
            // Construct the URL for the destination file
            let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
            //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
           
            // Check if the file already exists at the destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                print("File already exists at the destination.")
                // Remove destination file if it already exists
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
            } else {
                // Move the file to the subdirectory
                try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                print("File moved successfully to: \(destinationURL.path)")
            }
            
            do {
                //unzip
                let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                print("File unzipped successfully.")
            } catch {
                print("Error unzipping file: \(error)")
            }
            
            
            
            do {
                //delete imported2.zip or imported2.xlsx
                try FileManager.default.removeItem(at: destinationURL)
                print("Deleted zip file:", destinationURL)
            } catch {
                print("Error deleting file:", error)
            }
            
          
            
            //ready to zip
            var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
            let fpURL = URL(fileURLWithPath: fp)
            let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
            //appendingPathComponent("imported2.xlsx")
            let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
            let rlt = try FileManager.default.copyItem(at: zipFilePath, to: productURL)
            
            files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
            print("Done: ", files)
            
            return productURL

            
        } else {
            // Handle the case where the specified path doesn't exist
            print("File or directory does not exist at path: \(fp)")
        }
        
        } else {
            print("Document directory not found.")
        }
        
        
        } catch {
            print("Error: \(error)")
        }

            return nil
    }
    
    func writeXlsxSandBox(path: URL, fileName: String) {
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
                
                // Check if the directory exists
                if FileManager.default.fileExists(atPath: driveURL.path) {
                    // Get a list of files in the directory
                    let files = try FileManager.default.contentsOfDirectory(at: driveURL, includingPropertiesForKeys: nil)
                    
                    // Zip the files (assuming you have a Zip library)
                    let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                    
                    //try Zip.quickUnzipFile(zipFilePath)
                        
                    
                    if FileManager.default.fileExists(atPath: zipFilePath.path) {
                        // Copy the zip file to the specified path
                        try FileManager.default.copyItem(at: zipFilePath, to: path.appendingPathComponent(fileName))
                        print("Done: ", path.appendingPathComponent(fileName).path)
                    }
                } else {
                    print("Directory does not exist.")
                }
            } else {
                print("Document directory not found.")
            }
        } catch {
            print("Error: \(error)")
        }
    }

    
    func writeXlsx(path:URL,fileName:String){
        do{
            let files = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path.path), includingPropertiesForKeys: nil)
            let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer") // Zip
            
            if FileManager.default.fileExists(atPath: zipFilePath.path) {
                //It's odd. It created file on the root directory.
                print("Done: ", zipFilePath.path)
                
                FileManager.default.secureCopyItem(at: URL(fileURLWithPath:zipFilePath.path), to:URL(fileURLWithPath: (path.appendingPathComponent(fileName).path)))
            }
        }
        catch
        {
            print("Something went wrong")
        }
    }
    
    // Function to extract row and column indices from the "r" attribute value
    func extractIndices(from attribute: String) -> (row: Int, column: String)? {
        guard let match = attribute.rangeOfCharacter(from: .decimalDigits) else {
            return nil
        }
        
        let rowString = attribute[match.lowerBound...]
        let columnString = attribute.prefix(upTo: match.lowerBound)
        
        if let row = Int(rowString), !columnString.isEmpty {
            return (row, String(columnString))
        } else {
            return nil
        }
    }

    func extractSheetDataSubstring(from input: String) -> String? {
        let pattern = "<sheetData>(.*?)</sheetData>"
        if let range = input.range(of: pattern, options: .regularExpression) {
            return String(input[range])
        }
        return nil
    }


}
extension FileManager {
    open func writeXml(folder:String,filename:String,content:String) -> Bool{
        let driveURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent(folder)
                
        print(driveURL?.absoluteString as Any)
                
        //        https://stackoverflow.com/questions/26931355/how-to-create-directory-using-swift-code-nsfilemanager/26931481
                
        do {
                if !FileManager.default.fileExists(atPath: driveURL!.absoluteString) {
                        try FileManager.default.createDirectory(at: driveURL!, withIntermediateDirectories: true, attributes: nil)
                }
            
            if (NSData(contentsOf: driveURL!.appendingPathComponent(filename)) != nil) {
                               
                try FileManager.default.removeItem(at: driveURL!.appendingPathComponent(filename))
                    print("overwritten",driveURL!)
                }

         
                try content.write(to: driveURL!.appendingPathComponent(filename), atomically: true, encoding: .utf8)
              
                
            return true
        
        } catch {
            print(error.localizedDescription);
            
            return false
                          
        }
    }
    
    open func writeXmlsandBox(folder:String,filename:String,content:String) -> Bool{
          let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents").appendingPathComponent(folder)
                
        print(driveURL.absoluteString as Any)
                
        //        https://stackoverflow.com/questions/26931355/how-to-create-directory-using-swift-code-nsfilemanager/26931481
                
        do {
            if !FileManager.default.fileExists(atPath: driveURL.absoluteString) {
                try FileManager.default.createDirectory(at: driveURL, withIntermediateDirectories: true, attributes: nil)
                }
            
            if (NSData(contentsOf: driveURL.appendingPathComponent(filename)) != nil) {
                               
                try FileManager.default.removeItem(at: driveURL.appendingPathComponent(filename))
                print("overwritten",driveURL)
                }

         
            try content.write(to: driveURL.appendingPathComponent(filename), atomically: true, encoding: .utf8)
              
                
            return true
        
        } catch {
            print(error.localizedDescription);
            
            return false
                          
        }
    }
    
    open func getFileURLsInFolder(folder: String) -> [URL]? {
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentsDirectoryURL.appendingPathComponent(folder)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print("Error accessing files in folder: \(error.localizedDescription)")
            return nil
        }
    }

    
    open func deleteWorksheets() -> Bool{
        let driveURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent("xl/worksheets/")
                
        print(driveURL?.absoluteString as Any)
                
        //        https://stackoverflow.com/questions/26931355/how-to-create-directory-using-swift-code-nsfilemanager/26931481
                
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: driveURL!.path)

                for item in items {
                    try FileManager.default.removeItem(at: driveURL!.appendingPathComponent(item))
                     print(item)
                }

                   
            } catch {
                                   
                return false
                                                 
            }
    

            return true
        
       
    }
    
    func uploadFileToICloud(url: URL) {
            // Implement file upload logic to iCloud Drive using FileManager or CloudKit APIs
            // For example:
            do {
                let fileManager = FileManager.default
                let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(url.lastPathComponent)
                try fileManager.copyItem(at: url, to: iCloudURL!)
                print("File uploaded to iCloud Drive successfully")
            } catch {
                print("Error uploading file to iCloud Drive: \(error.localizedDescription)")
            }
        }
    
    
    
}


extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}
class XMLValidator: NSObject, XMLParserDelegate {
    
    var validationError: Error?
    
    func validateXML(xmlString: String) -> Bool {
        let parser = XMLParser(data: xmlString.data(using: .utf8)!)
        parser.delegate = self
        
        return parser.parse()
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        validationError = parseError
    }
}
