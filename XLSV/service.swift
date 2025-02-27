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
              

         //zip folder here
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
            let pattern = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
            
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
                    let matchingSubstring = xmlString![matchRange].description
                    return xmlString?.replacingOccurrences(of: matchingSubstring, with: "")
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
                    let matchingSubstring = xmlString![matchRange].description
                    //<c>...</c> check if the ms has this structure.
                    return xmlString?.replacingOccurrences(of: matchingSubstring, with: "")
                }
            }
        }
        return nil
    }
    
    func testDeleteStringBulk(url: URL? = nil, index: [String]? = nil) -> String? {
        guard let url2 = url, let indices = index else { return nil }
        
        do {
            // Read the XML data
            let xmlData = try Data(contentsOf: url2)
            var xmlString = String(data: xmlData, encoding: .utf8)
            
            for singleIndex in indices {
                // Define the regular expression pattern for the current index
                //let pattern = "<c[^>]*r=\"\(singleIndex)\"[^>]*>(.*?)</c>"
                let pattern = "<c[^>]*r=\"\(singleIndex)(?!\\d)\"[^>]*>(.*?)</c>"
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                    fatalError("Failed to create regular expression")
                }
                
                // Find matches in the XML string
                let range = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
                if let match = regex.firstMatch(in: xmlString!, range: range) {
                    if let matchRange = Range(match.range, in: xmlString!) {
                        let matchingSubstring = xmlString![matchRange].description
                        
                        //matchingSubstring="<c s=\"1\" r=\"B10\"/><c r=\"C10\" t=\"s\"><v>9</v></c>"
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: "")
                        continue
                    }
                }
                
                // Define the second pattern
                let pattern2 = "<c[^>]*r=\"\(singleIndex)(?!\\d)\"[^>]*>.*?</c>"
                guard let regex2 = try? NSRegularExpression(pattern: pattern2, options: []) else {
                    fatalError("Failed to create regular expression")
                }
                
                // Find matches in the XML string for the second pattern
                let range2 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
                if let match2 = regex2.firstMatch(in: xmlString!, range: range2) {
                    if let matchRange2 = Range(match2.range, in: xmlString!) {
                        let matchingSubstring = xmlString![matchRange2].description
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: "")
                        continue
                    }
                }
            }
            
            return xmlString
        } catch {
            print("Error reading or processing file: \(error.localizedDescription)")
            return nil
        }
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
            if xmlData == nil{
                return nil
            }
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
                        //print(xmlString)
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
                        //print(xmlString)
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
                        //print(xmlString)
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
                        //print(xmlString)
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
                        
                    let pattern1 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*>(.*?)</c>"
                    let pattern2 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*/>" //#"<c\s+r="B1".*?</c>"#
                    
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
                                        //print(xmlString)
                                        return backUpXmlString
                                    }
                                }
                            }
                        }
                    }
                
                }else{
                    //first c tag with sharedstring idx == nil no row yet
                    var sortedRowstr = ""
                    var sortedRowcnt = [String]()
                    var sortedRowInt = [Int]()
                    if targetRowTag == ""{
                        var newElement = "<sheetData><row r=\"\(row)\"><c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c></row>"
                        if styleIdx > 0{
                            newElement = "<sheetData><row r=\"\(row)\"><c r=\"\(String(index!))\" s=\"\(String(styleIdx))\" t=\"s\"><v>\(String(vIndex!))</v></c></row>"
                        }
                        
                        var replaced = xmlString
                        
                        if replaced!.contains("<sheetData/>"){
                            replaced = replaced!.replacingOccurrences(of: "<sheetData/>", with: "<sheetData></sheetData>")
                        }
                        
                        replaced = replaced!.replacingOccurrences(of: "<sheetData>", with: newElement)
                        
                        
                        
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
                                let idx = cell.element?.attribute(by: "r")?.text.description
                                sortedRowcnt.append(cell.description)
                                sortedRowInt.append(Int(idx!)!)
                            }
                            print("row",sortedRowstr)
                        }

                        let sheetDataSubstring = extractSheetDataSubstring(from: replaced!)
                        if sheetDataSubstring == nil{
                            return backUpXmlString
                        }
                        if (sheetDataSubstring != nil) {
                            let zippedArray = zip(sortedRowcnt, sortedRowInt)

                            // Sort the zipped array based on the second element (sortedRowInt)
                            let sortedZippedArray = zippedArray.sorted { $0.1 < $1.1 }

                            // Extract the sorted strings from the sorted zipped array
                            let sortedStrings = sortedZippedArray.map { $0.0 }
                            
                            let rowSortedStr = replaced!.replacingOccurrences(of: sheetDataSubstring!, with:"<sheetData>" + sortedStrings.joined(separator: "") + "</sheetData>")
                            xml = XMLHash.parse(rowSortedStr)
                        }
                        
                        let validator = XMLValidator()
                        
                        if validator.validateXML(xmlString:xml.description) {
                            print("XML is valid.")
                            return xml.description
                        } else {
                            print("XML is not valid.")
                            return backUpXmlString
                        }
                    }else{
                        //targetRowTag   "<row r=\"1\"><c r=\"B1\" row exists t=\"s\"><v>78</v></c></row>"
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
                            //print(xmlString)
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
    
    //making row
    func testUpdateRow(url:URL? = nil, index:String?, overWrittenIndice:[String],overWritingIndice:[String]) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
          
            //regular expression
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            
            for (i,each) in overWritingIndice.enumerated(){
                xmlString = xmlString?.replacingOccurrences(of: overWrittenIndice[i], with: each)
            }
            
            xmlString = xmlString?.replacingOccurrences(of: "!____!", with: "")
                    
            var xml = XMLHash.parse(xmlString!)
            //TODO Row Delete?
            let validator = XMLValidator()
            if validator.validateXML(xmlString: xmlString!) {
                print("XML is valid.")
                return xmlString
            } else {
                print("XML is not valid.")
                //print(xmlString)
                return backUpXmlString
            }
        
        }
            
        return nil
    }
    
    //todo creating
    func testUpdateValue(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil) -> String?{
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
            if xmlData == nil{
                return nil
            }
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
                    var functionstr = ""
                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
                    if (fString != nil){
                        functionstr = "<f>\(fString!)</f>"
                    }
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
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
                        //print(xmlString)
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
                    var functionstr = ""
                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
                    if (fString != nil){
                        functionstr = "<f>\(fString!)</f>"
                    }
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
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
                        //print(xmlString)
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
                    
                    var functionstr = ""
                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
                    if (fString != nil){
                        functionstr = "<f>\(fString!)</f>"
                    }
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
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
                        //print(xmlString)
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
                    
                    var functionstr = ""
                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
                    if (fString != nil){
                        functionstr = "<f>\(fString!)</f>"
                    }
                    
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
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
                        //print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
            //
            
            
            //get the list of locations
            do {
                var functionstr = ""
                if (fString != nil){
                    functionstr = "<f>\(fString!)</f>"
                }
                
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
                        var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
                        
                        if styleIdx > 0{
                            newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
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
                        //                    let pattern1 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)/>"
                        //                    let pattern2 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
                        let pattern1 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*>(.*?)</c>"
                        let pattern2 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*/>"
                        
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
                                var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
                                
                                if styleIdx > 0{
                                    newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
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
                                        //print(xmlString)
                                        return backUpXmlString
                                    }
                                }
                            }
                        }
                    }
                    
                }else{
                    //row not exists
                    //first c tag with sharedstring idx == nil
                    var sortedRowcnt = [String]()
                    var sortedRowstr = ""
                    var sortedRowInt = [Int]()
                    if targetRowTag == ""{
                        //"<sheetData><row r=\"4\"><c r=\"A4\" s=\"1\"><v>10</v></c></row>"
                        //var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
                        var newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" >\(functionstr)<v>\(String(vIndex!))</v></c></row>"
                        if (sValueId != nil && sValueId! != 0){
                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c></row>"
                        }
                        
                        if styleIdx > 0{
                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c></row>"
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
                                
                                return text1 < text2
                            }
                            
                            // Use the sorted cells
                            // For example, print them
                            for cell in sortedCells {
                                let idx = cell.element?.attribute(by: "r")?.text.description
                                sortedRowcnt.append(cell.description)
                                sortedRowInt.append(Int(idx!)!)
                                sortedRowstr += cell.description
                            }
                        }
                        
                        if let sheetDataSubstring = extractSheetDataSubstring(from: replaced!) {
                            
                            let zippedArray = zip(sortedRowcnt, sortedRowInt)
                            
                            // Sort the zipped array based on the second element (sortedRowInt)
                            let sortedZippedArray = zippedArray.sorted { $0.1 < $1.1 }
                            
                            // Extract the sorted strings from the sorted zipped array
                            let sortedStrings = sortedZippedArray.map { $0.0 }
                            
                            let rowSortedStr = replaced!.replacingOccurrences(of: sheetDataSubstring, with:"<sheetData>" + sortedStrings.joined(separator: "") + "</sheetData>")
                            xml = XMLHash.parse(rowSortedStr)
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
                        var newElement2 = "<c r=\"\(String(index!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
                        if (sValueId != nil && sValueId! != 0){
                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
                        }
                        
                        if (styleIdx > 0){
                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
                        }
                        
                        
                        
                        var replacing = rowPart.replacingOccurrences(of: "</row>", with: "")
                        replacing = replacing + newElement2 + "</row>"
                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                        let validator0 = XMLValidator()
                        if validator0.validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                        } else {
                            print("XML is not valid.")
                            //print(xmlString)
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
                    //print("si",delegate.sis)
                    //print("si count", delegate.sis.count)
                    //var xmlString = try? String(contentsOf: url2)
                    
                    //try? xmlString?.write(to: url2, atomically: true, encoding: .utf8)
                    return delegate.sis
                }
            }
        }
        return []
    }
    
    func testUpdateFormula(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "") -> String?{
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
                    var functionstr = ""
                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
                    if (fString != nil){
                        functionstr = "<f>\(fString!)</f>"
                    }
                    if (fString == nil){
                        functionstr = "<f>\(String(vIndex!).replacingOccurrences(of: "=", with: ""))</f>"
                    }
                    
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
                    }
                    
                    //"<c r=\"D14\" s=\"54\"><v>0.375</v></c><c r=\"E14\" s=\"55\"><v>0.75</v></c><c r=\"F14\" s=\"56\"><v>0.5</v></c><c r=\"G14\" s=\"57\"><v>0.54166666666666663</v></c><c r=\"H14\" s=\"56\"/>"
                    xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        //print(xmlString)
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
                    var functionstr = ""
                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
                    if (fString != nil){
                        functionstr = "<f>\(fString!)</f>"
                    }
                    if (fString == nil){
                        functionstr = "<f>\(String(vIndex!).replacingOccurrences(of: "=", with: ""))</f>"
                    }
                    //<c r="B4"><f>SUM(A1:A7)</f><v>8</v></c>
                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
                    
                    if styleIdx > 0{
                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
                    }
                    
                    //"<c r=\"D14\" s=\"54\"><v>0.375</v></c><c r=\"E14\" s=\"55\"><v>0.75</v></c><c r=\"F14\" s=\"56\"><v>0.5</v></c><c r=\"G14\" s=\"57\"><v>0.54166666666666663</v></c><c r=\"H14\" s=\"56\"/>"
                    
                    xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
                    
                    let validator = XMLValidator()
                    if validator.validateXML(xmlString: xmlString!) {
                        print("XML is valid.")
                        return xmlString
                    } else {
                        print("XML is not valid.")
                        //print(xmlString)
                        return backUpXmlString
                    }
                }
            }
            
            
            //get the list of locations
            do {
                var functionstr = ""
                if (fString != nil){
                    functionstr = "<f>\(fString!)</f>"
                }
                if (fString == nil){
                    functionstr = "<f>\(String(vIndex!).replacingOccurrences(of: "=", with: ""))</f>"
                }
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
                        var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
                        
                        if styleIdx > 0{
                            newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
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
                        //                    let pattern1 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)/>"
                        //                    let pattern2 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
                        let pattern1 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*>(.*?)</c>"
                        let pattern2 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*/>"
                        
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
                                var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
                                
                                if styleIdx > 0{
                                    newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
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
                                        //print(xmlString)
                                        return backUpXmlString
                                    }
                                }
                            }
                        }
                    }
                    
                }else{
                    //row not exists
                    //first c tag with sharedstring idx == nil
                    var sortedRowcnt = [String]()
                    var sortedRowstr = ""
                    var sortedRowInt = [Int]()
                    if targetRowTag == ""{
                        //"<sheetData><row r=\"4\"><c r=\"A4\" s=\"1\"><v>10</v></c></row>"
                        //var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
                        var newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" >\(functionstr)<v>\(calculated)</v></c></row>"
                        if (sValueId != nil && sValueId! != 0){
                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c></row>"
                        }
                        
                        if styleIdx > 0{
                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c></row>"
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
                                
                                return text1 < text2
                            }
                            
                            // Use the sorted cells
                            // For example, print them
                            for cell in sortedCells {
                                let idx = cell.element?.attribute(by: "r")?.text.description
                                sortedRowcnt.append(cell.description)
                                sortedRowInt.append(Int(idx!)!)
                                sortedRowstr += cell.description
                            }
                        }
                        
                        if let sheetDataSubstring = extractSheetDataSubstring(from: replaced!) {
                            
                            let zippedArray = zip(sortedRowcnt, sortedRowInt)
                            
                            // Sort the zipped array based on the second element (sortedRowInt)
                            let sortedZippedArray = zippedArray.sorted { $0.1 < $1.1 }
                            
                            // Extract the sorted strings from the sorted zipped array
                            let sortedStrings = sortedZippedArray.map { $0.0 }
                            
                            let rowSortedStr = replaced!.replacingOccurrences(of: sheetDataSubstring, with:"<sheetData>" + sortedStrings.joined(separator: "") + "</sheetData>")
                            xml = XMLHash.parse(rowSortedStr)
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
                        var newElement2 = "<c r=\"\(String(index!))\">\(functionstr)<v>\(calculated)</v></c>"
                        if (sValueId != nil && sValueId! != 0){
                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
                        }
                        
                        if (styleIdx > 0){
                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
                        }
                        
                        
                        
                        var replacing = rowPart.replacingOccurrences(of: "</row>", with: "")
                        replacing = replacing + newElement2 + "</row>"
                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                        let validator0 = XMLValidator()
                        if validator0.validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                        } else {
                            print("XML is not valid.")
                            //print(xmlString)
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
    
    func alphabetOnlyString(text: String) -> String {
       let okayChars = Set("ABCDEFGHIJKLKMNOPQRSTUVWXYZ")
       return text.filter {okayChars.contains($0) }
    }

    func numberOnlyString(text: String) -> String {
       let okayChars = Set("1234567890")
       return text.filter {okayChars.contains($0) }
    }
    
    func testDeleteRows(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "", rowRange:[Int] = [], locationInExcel:[String] = []) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if rowRange.count == 0{
            return nil
        }
        //get style id
        var styleIdx = -1
        let slocatinIdx = appd.excelStyleLocationAlphabet.firstIndex(of: String(index!))
        var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
        if (slocatinIdx != nil){
            styleIdx = appd.excelStyleIdx[slocatinIdx!]
        }
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            if xmlData == nil{
                return nil
            }
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
            let rowNumber = appd.DEFAULT_ROW_NUMBER
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
                    
            //TODO DELETE ROW
            for(i,each) in rowRange.enumerated(){
                // Retrieve all row tags
                let patternRow = "<row r=\"\(each)\".*?>(.*?)</row>"
                guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                    fatalError("Failed to create regular expression")
                }
                
                // Find all matches in the XML snippet
                let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
                
                var targetRowTag = ""
                for match in matchesRow {
                    // Extract the row number from the match
                    let nsRange = match.range(at: 1) // Use the capture group index
                    if let range = Range(nsRange, in: xmlString!) {
                        if let matchRange = Range(match.range, in: xmlString!) {
                            targetRowTag = String(xmlString![matchRange]).description
                            //assume this case targetRowTag    String    "<row r=\"9\"><c s=\"1\" r=\"B9\"><v>2</v></c></row>"
                            let bkString = xmlString
                            xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            let validator = XMLValidator()
                            if validator.validateXML(xmlString: xmlString!) {
                                print("XML is valid.")
                            } else {
                                print("XML is not valid.")
                                xmlString = bkString
                            }
                        }
                    }
                }
            }
            print("locationInExcel",locationInExcel)
            //TODO decrease other rowNums
            for i in 0..<rowNumber {
                if i-rowRange.count > 0 && i >= rowRange.min()!{
                    //
                    var rowNumAry = [Int]()
                    var lettersAry = [String]()
                    var fullAddressAry = [String]()
                    for j in 0..<locationInExcel.count {
                        if numberOnlyString(text: locationInExcel[j]) == String(i){
                            rowNumAry.append(Int(numberOnlyString(text: locationInExcel[j]))!)
                            lettersAry.append(alphabetOnlyString(text: locationInExcel[j]))
                            fullAddressAry.append(locationInExcel[j])
                        }
                    }
                    if rowNumAry.count > 0{
                        // Retrieve all row tags
                        let patternRow = "<row r=\"\(i)\".*?>(.*?)</row>"
                        guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                            fatalError("Failed to create regular expression")
                        }
                        
                        // Find all matches in the XML snippet
                        let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
                        
                        var targetRowTag = ""
                        for match in matchesRow {
                            // Extract the row number from the match
                            let nsRange = match.range(at: 1) // Use the capture group index
                            if let range = Range(nsRange, in: xmlString!) {
                                if let matchRange = Range(match.range, in: xmlString!) {
                                    targetRowTag = String(xmlString![matchRange]).description
                                    //assume this case targetRowTag    String    "<row r=\"9\"><c s=\"1\" r=\"B9\"><v>2</v></c></row>"
                                    let bkString = xmlString
                                    var newTargetRowTag = targetRowTag
                                    let presentRow = "r=\"\(i)\""
                                    let newRow = "r=\"____\(i-rowRange.count)\""
                                    newTargetRowTag = newTargetRowTag.replacingOccurrences(of: presentRow, with: newRow)
                                    
                                    for k in 0..<fullAddressAry.count{
                                        let presentRow = "r=\"\(fullAddressAry[k])\""
                                        let newRow = "r=\"____\(lettersAry[k])\(rowNumAry[k]-rowRange.count)\""
                                        newTargetRowTag = newTargetRowTag.replacingOccurrences(of: presentRow, with: newRow)
                                    }
                                    xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: newTargetRowTag)
                                    let validator = XMLValidator()
                                    if validator.validateXML(xmlString: xmlString!) {
                                        print("XML is valid.")
                                    } else {
                                        print("XML is not valid.")
                                        xmlString = bkString
                                    }
                                }
                            }
                        }
                    }
                }
            }
            xmlString = xmlString?.replacingOccurrences(of: "____", with: "")
            print("deleted\(xmlString)")
            return xmlString
        }
        return nil
    }
    
    func testAddRows(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "", rowRange:[Int] = [], locationInExcel:[String] = []) -> String?{
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
            let rowNumber = appd.DEFAULT_ROW_NUMBER
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
            
            //TODO increase rowNums
            for i in 0..<rowNumber {
                if i >= rowRange.min() ?? -1 {
                    //
                    var rowNumAry = [Int]()
                    var lettersAry = [String]()
                    var fullAddressAry = [String]()
                    for j in 0..<locationInExcel.count {
                        if numberOnlyString(text: locationInExcel[j]) == String(i){
                            print("test row\(i)")
                            rowNumAry.append(Int(numberOnlyString(text: locationInExcel[j]))!)
                            lettersAry.append(alphabetOnlyString(text: locationInExcel[j]))
                            fullAddressAry.append(locationInExcel[j])
                        }
                    }
                    if rowNumAry.count > 0{
                        // Retrieve all row tags
                        let patternRow = "<row r=\"\(i)\".*?>(.*?)</row>"
                        guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                            fatalError("Failed to create regular expression")
                        }
                        
                        // Find all matches in the XML snippet
                        let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
                        
                        var targetRowTag = ""
                        for match in matchesRow {
                            // Extract the row number from the match
                            let nsRange = match.range(at: 1) // Use the capture group index
                            if let range = Range(nsRange, in: xmlString!) {
                                if let matchRange = Range(match.range, in: xmlString!) {
                                    targetRowTag = String(xmlString![matchRange]).description
                                    //assume this case targetRowTag    String    "<row r=\"9\"><c s=\"1\" r=\"B9\"><v>2</v></c></row>"
                                    let bkString = xmlString
                                    let presentRow = "r=\"\(i)\""
                                    let newRow = "r=\"____\(i+rowRange.count)\""
                                    xmlString = xmlString?.replacingOccurrences(of: presentRow, with: newRow)
                                    for k in 0..<fullAddressAry.count{
                                        let presentRow = "r=\"\(fullAddressAry[k])\""
                                        let newRow = "r=\"____\(lettersAry[k])\(rowNumAry[k]+rowRange.count)\""
                                        xmlString = xmlString?.replacingOccurrences(of: presentRow, with: newRow)
                                    }
                                    let validator = XMLValidator()
                                    if validator.validateXML(xmlString: xmlString!) {
                                        print("XML is valid.")
                                    } else {
                                        print("XML is not valid.")
                                        xmlString = bkString
                                    }
                                }
                            }
                        }
                    }
                }
            }
            xmlString = xmlString?.replacingOccurrences(of: "____", with: "")
            print("added\(xmlString)")
            return xmlString
        }
        return nil
    }
    
    func testAddCols(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "", colRange:[Int] = [], locationInExcel:[String] = []) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //appd.numberofColumn you need this
        let newColSize = appd.numberofColumn+colRange.count+1//DEFAULT_COLUMN_NUMBER numberofColumn
        var newExcelColList = [String]()
        for i in 0..<newColSize{
            newExcelColList.append(GetExcelColumnName(columnNumber: i))
        }
        print(newExcelColList)
        
        if colRange.count == 0{
            return nil
        }
        //
        var rowIntAry = [Int]()
        var lettersAry = [String]()
        var fullAddressAry = [String]()
        for i in 0..<locationInExcel.count {
            for j in 1..<newExcelColList.count {
                if alphabetOnlyString(text: locationInExcel[i]) == newExcelColList[j]{
                    print("test col\(i)")
                        lettersAry.append(alphabetOnlyString(text: locationInExcel[i]))
                        rowIntAry.append(Int(numberOnlyString(text:locationInExcel[i]))!)
                        fullAddressAry.append(locationInExcel[i])
                }
            }
        }
        
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
            let startCol = colRange.min()!
            for (i,each) in fullAddressAry.enumerated(){
                let presentCol = "r=\"\(each)\""
                let rowInt = rowIntAry[i]
                let colIdx = newExcelColList.firstIndex(of: lettersAry[i])!
                let newAddress = newExcelColList[colIdx+colRange.count] + String(rowInt)
                let newCol = "r=____\"\(newAddress)\""
                if colIdx >= startCol{
                    xmlString = xmlString?.replacingOccurrences(of: presentCol, with: newCol)
                }
            }
            
            xmlString = xmlString?.replacingOccurrences(of: "____", with: "")
            print("added\(xmlString)")
            return xmlString
        }
        return nil
    }
    
    func testDeleteCols(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "", colRange:[Int] = [], locationInExcel:[String] = []) -> String?{
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
            
            //
            let newColSize = appd.numberofColumn
            var newExcelColList = [String]()
            for i in 0..<newColSize{
                newExcelColList.append(GetExcelColumnName(columnNumber: i))
            }
            print(newExcelColList)
            var rowIntAry = [Int]()
            var lettersAry = [String]()
            var fullAddressAry = [String]()
            for i in 0..<locationInExcel.count {
                for j in 1..<newExcelColList.count {
                    if alphabetOnlyString(text: locationInExcel[i]) == newExcelColList[j]{
                        print("test col\(i)")
                            lettersAry.append(alphabetOnlyString(text: locationInExcel[i]))
                            rowIntAry.append(Int(numberOnlyString(text:locationInExcel[i]))!)
                            fullAddressAry.append(locationInExcel[i])
                    }
                }
            }
            
            
            var patternFound = false
            // Start parsing
            if parser.parse() {
                // Retrieve the extracted part
                let extractedPart = delegate.extractedPart
                //print(extractedPart)
            }
            
            //regular expression
            let rowNumber = appd.DEFAULT_ROW_NUMBER
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
            //TODO DELETE ROW
            for(i,each) in fullAddressAry.enumerated(){
                // Retrieve all row tags
                //<c s=\"1\" r=\"B9\"><v>2</v></c>
//                let patternRow = "<c r=\"\(each)\".*?>(.*?)</c>"
//                let patternRow = #"<c\s+([^>]*)>.*?</c>"#
                let patternRow = #"<c[^>]*>.*?</c>"#
                guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                    fatalError("Failed to create regular expression")
                }
                
                var targetRowTag = ""
                if let regex = try? NSRegularExpression(pattern: patternRow, options: []) {
                    let range = NSRange(xmlString!.startIndex..., in: xmlString!)
                    let matches = regex.matches(in: xmlString!, options: [], range: range)
                    
                    for match in matches {
                        targetRowTag = (xmlString! as NSString).substring(with: match.range)
                        //assume this case targetRowTag    String    "<c s=\"1\" r=\"B9\"><v>2</v></c>"
                        var deleteCols = [String]()
                        let bkString = xmlString
                        
                        for m in 0..<colRange.count{
//                            targetRowTag    String    "<c s=\"1\" r=\"B2\"><v>1</v></c>"
                            let selectedColLetter = GetExcelColumnName(columnNumber: colRange[m])
                            if targetRowTag.contains("r=\"\(selectedColLetter+"1")\""){
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            }
                            if targetRowTag.contains("r=\"\(selectedColLetter+"2")\""){
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            }
                            if targetRowTag.contains("r=\"\(selectedColLetter+"3")\""){
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            }
                            if targetRowTag.contains("r=\"\(selectedColLetter+"4")\""){
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            }
                            if targetRowTag.contains("r=\"\(selectedColLetter+"5")\""){
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            }
                            if targetRowTag.contains("r=\"\(selectedColLetter+"6")\""){
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            }
                            if targetRowTag.contains("r=\"\(selectedColLetter+"7")\""){
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            }
                            if targetRowTag.contains("r=\"\(selectedColLetter+"8")\""){
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            }
                            if targetRowTag.contains("r=\"\(selectedColLetter+"9")\""){
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            }
                        }
                        
                        
                        
                        
                        let validator = XMLValidator()
                        if validator.validateXML(xmlString: xmlString!) {
                            print("XML is valid.")
                        } else {
                            print("XML is not valid.")
                            xmlString = bkString
                        }
                    }
                }
            }
            print("locationInExcel",locationInExcel)
            //TODO decrease other rowNums
            for i in 0..<rowNumber {
                //
                var rowNumAry = [Int]()
                var lettersAry = [String]()
                var fullAddressAry = [String]()
                for j in 0..<locationInExcel.count {
                    if numberOnlyString(text: locationInExcel[j]) == String(i){
                        rowNumAry.append(Int(numberOnlyString(text: locationInExcel[j]))!)
                        lettersAry.append(alphabetOnlyString(text: locationInExcel[j]))
                        fullAddressAry.append(locationInExcel[j])
                    }
                }
                //take care other cells
                for (k,each) in fullAddressAry.enumerated(){
                    // Retrieve all row tags
//                    let patternRow = "<c r=\"\(each)\".*?>(.*?)</c>"
//                    let patternRow = #"<c\s+([^>]*)>.*?</c>"#
                    let patternRow = #"<c[^>]*>.*?</c>"#
                    guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                        fatalError("Failed to create regular expression")
                    }
                    var targetRowTag = ""
                    if let regex = try? NSRegularExpression(pattern: patternRow, options: []) {
                        let range = NSRange(xmlString!.startIndex..., in: xmlString!)
                        let matches = regex.matches(in: xmlString!, options: [], range: range)
                        for match in matches {
                            targetRowTag = (xmlString! as NSString).substring(with: match.range)
                            if !targetRowTag.hasSuffix("</c>") || !targetRowTag.hasPrefix("<c") || !targetRowTag.contains(each){
                                continue
                            }
                            //assume this case targetRowTag    String    "<c s=\"1\" r=\"B9\"><v>2</v></c>"
                            let bkString = xmlString
                            var newTargetRowTag = targetRowTag
                            let presentRow = "r=\"\(each)\""
                            let letterKIdx = newExcelColList.firstIndex(of: lettersAry[k]) ?? -1
                            let newAddress = GetExcelColumnName(columnNumber:letterKIdx-colRange.count) + String(rowNumAry[k])
                            let newRow = "r=\"____\(newAddress)\""
                            if letterKIdx > 0 && GetExcelColumnName(columnNumber:letterKIdx-colRange.count) != ""{
                                newTargetRowTag = newTargetRowTag.replacingOccurrences(of: presentRow, with: newRow)
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: newTargetRowTag)
                            }
                            
                            let validator = XMLValidator()
                            if validator.validateXML(xmlString: xmlString!) {
                                print("XML is valid.")
                            } else {
                                print("XML is not valid.")
                                xmlString = bkString
                            }
                        }
                    }
                }
            }
            xmlString = xmlString?.replacingOccurrences(of: "____", with: "")
            print("deleted\(xmlString)")
            return xmlString
        }
        return nil
    }
    
    func GetExcelColumnName(columnNumber: Int) -> String
    {
        var dividend = columnNumber
        var columnName = ""
        var modulo = 0
        
        while (dividend > 0)
        {
            modulo = (dividend - 1) % 26;
            columnName = String(65 + modulo) + "," + columnName
            dividend = Int((dividend - modulo) / 26)
        }
        
        var alphabetsAry = [String]()
        alphabetsAry = columnName.components(separatedBy: ",")
        
        var fstring = ""
        for i in 0..<alphabetsAry.count {
            let a:Int! = Int(alphabetsAry[i])
            if a != nil{
                let b:UInt8 = UInt8(a)
                fstring.append(String(UnicodeScalar(b)))
            }
            
            
        }
        
        return fstring
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
                        //print(xmlString)
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
    
    
    func testUpdateStringBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int?, fString:String? = nil, bulkAry:[String] = [], calculated:String = "") -> URL? {
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {

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
                    //print(xmlString)
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
                        let replacedWithNewString = testUpdateValue(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString) ?? ""//A3
                        // Write the modified XML data back to the file
                        if(replacedWithNewString != ""){
                            try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                        }
                        check = true
                    }
                    if (shredStringId.0 != nil && input.hasPrefix("=") && calculated != ""){
                        //value update
                        let replacedWithNewString = testUpdateFormula(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString, calculated: calculated) ?? ""//A3
                        // Write the modified XML data back to the file
                        if(replacedWithNewString != ""){
                            try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                        }
                        check = true
                    }
                    if (shredStringId.0 != nil && !input.hasPrefix("=")){
                        let replacedWithNewString = testUpdateString(url:worksheetXMLURL, vIndex: String(shredStringId.0!), index: cellIdxString)//A3
                        // Write the modified XML data back to the file
                        if(!check && replacedWithNewString != nil && replacedWithNewString != ""){
                            try? replacedWithNewString!.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                            
                            // Write the modified XML data back to the file
                            try? shredStringId.1!.write(to: shardStringXMLURL, atomically: true, encoding: .utf8)
                        }
                    }
                        
                }else{
                    var replacedWithNewString = ""
                    if bulkAry.count == 0{
                        //delete
                        replacedWithNewString = testDeleteString(url:worksheetXMLURL, index: cellIdxString) ?? ""//A3
                    }
                    
                    if bulkAry.count > 0{
                        replacedWithNewString = testDeleteStringBulk(url:worksheetXMLURL, index: bulkAry) ?? ""//A3
                    }
                    
                    // Write the modified XML data back to the file
                    if(replacedWithNewString != nil && replacedWithNewString != ""){
                        do {
                            try replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                            print("File written successfully to \(worksheetXMLURL.path)")
                        } catch {
                            print("Failed to write file: \(error.localizedDescription)")
                        }
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
    
    func testRowsDeleteBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, bulkAry:[String] = [], calculated:String = "", rowRange:[Int] = [], locationInExcel:[String] = []) -> URL? {
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
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                let replacedWithNewString = testDeleteRows(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString, calculated: calculated,rowRange: rowRange, locationInExcel:locationInExcel) ?? ""//A3
                // Write the modified XML data back to the file
                if(replacedWithNewString != ""){
                    try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                }
                    
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
    
    func testRowsAddBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, bulkAry:[String] = [], calculated:String = "", rowRange:[Int] = [], locationInExcel:[String] = []) -> URL? {
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
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                let replacedWithNewString = testAddRows(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString, calculated: calculated,rowRange: rowRange, locationInExcel:locationInExcel) ?? ""//A3
                // Write the modified XML data back to the file
                if(replacedWithNewString != ""){
                    try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                }
                    
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
    
    func testColsAddBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, bulkAry:[String] = [], calculated:String = "", colRange:[Int] = [], locationInExcel:[String] = []) -> URL? {
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
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                let replacedWithNewString = testAddCols(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString, calculated: calculated,colRange: colRange, locationInExcel:locationInExcel) ?? ""//A3
                // Write the modified XML data back to the file
                if(replacedWithNewString != ""){
                    try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                }
                    
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
    
    func testColsDeleteBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, bulkAry:[String] = [], calculated:String = "", colRange:[Int] = [], locationInExcel:[String] = []) -> URL? {
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
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                let replacedWithNewString = testDeleteCols(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString, calculated: calculated,colRange: colRange, locationInExcel:locationInExcel) ?? ""//A3
                // Write the modified XML data back to the file
                if(replacedWithNewString != ""){
                    try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                }
                    
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
    
    func testAddSheetBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, filename: String = "") -> URL? {
        do {
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
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
                
                var code = ""
                let randamChar = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
                
                for _ in 0..<8 {
                    let idx = Int.random(in: 0..<16)
                    code.append(randamChar[idx])
                }
                
                
                //create new sheet
                var sheetContent = "<worksheet mc:Ignorable=\"x14ac xr xr2 xr3\" xr:uid=\"{" + code + "-0001-0000-0000-000000000000}\" xmlns:mc=\"http://schemas.openxmlformats.org/markup-compatibility/2006\" xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:xr2=\"http://schemas.microsoft.com/office/spreadsheetml/2015/revision2\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns:xr=\"http://schemas.microsoft.com/office/spreadsheetml/2014/revision\" xmlns:x14ac=\"http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac\" xmlns:xr3=\"http://schemas.microsoft.com/office/spreadsheetml/2016/revision3\"><dimension ref=\"A1\"></dimension><sheetViews><sheetView tabSelected=\"1\" workbookViewId=\"0\"><selection sqref=\"B5\" activeCell=\"B5\"></selection></sheetView></sheetViews><sheetFormatPr defaultRowHeight=\"13.5\"></sheetFormatPr><sheetData></sheetData><pageMargins header=\"0.3\" right=\"0.7\" footer=\"0.3\" bottom=\"0.75\" top=\"0.75\" left=\"0.7\"></pageMargins></worksheet>"

                
                
                
                    
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                var dup = false
                for each in sheetFiles{
                    let checkXmlString = try? String(contentsOf: each)
                    let count = (checkXmlString?.components(separatedBy: code).count ?? 0)
                    if (count>0){
                        dup = true
                        break
                    }
                }
                if dup{
                    var code2 = ""
                    for _ in 0..<8 {
                        let idx = Int.random(in: 0..<16)
                        code2.append(randamChar[idx])
                    }
                    
                    
                    //create new sheet
                    var sheetContent = "<worksheet mc:Ignorable=\"x14ac xr xr2 xr3\" xr:uid=\"{" + code + "-0001-0000-0000-0000" + code2 + "}\" xmlns:mc=\"http://schemas.openxmlformats.org/markup-compatibility/2006\" xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:xr2=\"http://schemas.microsoft.com/office/spreadsheetml/2015/revision2\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns:xr=\"http://schemas.microsoft.com/office/spreadsheetml/2014/revision\" xmlns:x14ac=\"http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac\" xmlns:xr3=\"http://schemas.microsoft.com/office/spreadsheetml/2016/revision3\"><dimension ref=\"A1\"></dimension><sheetViews><sheetView tabSelected=\"1\" workbookViewId=\"0\"><selection sqref=\"B5\" activeCell=\"B5\"></selection></sheetView></sheetViews><sheetFormatPr defaultRowHeight=\"13.5\"></sheetFormatPr><sheetData></sheetData><pageMargins header=\"0.3\" right=\"0.7\" footer=\"0.3\" bottom=\"0.75\" top=\"0.75\" left=\"0.7\"></pageMargins></worksheet>"

                }
                
                print("sheetFiles: ", sheetXMLFiles.count)
                
                let sortedFiles = sheetXMLFiles.sorted {
                    let num1 = Int(numberOnlyString(text: $0.lastPathComponent)) ?? 0
                    let num2 = Int(numberOnlyString(text: $1.lastPathComponent)) ?? 0
                    return num1 < num2
                }
                
                let lastNum = Int(numberOnlyString(text: sortedFiles.last!.lastPathComponent))!
                
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(lastNum+1) + ".xml")
                
                try? sheetContent.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                
                //xl/_res/workbook
                let _relsDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("_rels").appendingPathComponent("workbook.xml.rels")
                
                var xmlString = try? String(contentsOf: _relsDirectoryURL)
                var rIdNums = [Int]()
                let lines = xmlString?.components(separatedBy: "rId")
                for (i,line) in lines!.enumerated(){
                    if i > 0{
                        let numberOrNot = line.components(separatedBy: " ").first!
                        let tryFilter = numberOnlyString(text: numberOrNot)
                        if Int(tryFilter) != nil{
                            rIdNums.append(Int(tryFilter)!)
                        }
                    }
                }
                
                let max = rIdNums.max()//(xmlString?.components(separatedBy: "rId").count ?? 0) - 1//lines - 1 this returns count
  
                let relContent = "<Relationship Id=\"rId" + String(max!+1) + "\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet" + String(lastNum+1) + ".xml\"/></Relationships>"
                xmlString = xmlString?.replacingOccurrences(of: "</Relationships>", with: relContent)
                try? xmlString?.write(to: _relsDirectoryURL, atomically: true, encoding: .utf8)
                
                
                //xl/book
                let wkbookDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("workbook.xml")
                
                var xmlString3 = try? String(contentsOf: wkbookDirectoryURL)
                //let count3 = (xmlString3?.components(separatedBy: "rId").count ?? 0) - 1
                let newBook = "<sheet name=\"" + filename + "\" sheetId=\"" + String(lastNum+1) + "\" r:id=\"rId" + String(max!+1) + "\"/></sheets>"
                xmlString3 = xmlString3?.replacingOccurrences(of: "</sheets>", with: newBook)
                try? xmlString3?.write(to: wkbookDirectoryURL, atomically: true, encoding: .utf8)
                
                
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
    
    func testDeleteSheetBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, sheetname: String = "") -> URL? {
        do {
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
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
                
                //starts here
                //workbook
                let wkbookDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("workbook.xml")
                var xmlString3 = try? String(contentsOf: wkbookDirectoryURL)
                var rIdValue = ""
                var sheetIdValue = ""
                var snippet = ""
                //xl/workbook
                // Define regex pattern to match the sheet snippet
                let pattern = "<sheet name=\"\(sheetname)\"[^>]+/>"
                if let range = xmlString3?.range(of: pattern, options: .regularExpression) {
                    snippet = String(xmlString3![range])
                    print("snippet",snippet) // Output: <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
                    let pattern2 = #"r:id="([^"]+)""#
                    if let regex2 = try? NSRegularExpression(pattern: pattern2),
                       let match2 = regex2.firstMatch(in: snippet, range: NSRange(snippet.startIndex..., in: snippet)) {
                        if let range2 = Range(match2.range(at: 1), in: snippet) {
                            rIdValue = String(snippet[range2])
                            print(rIdValue) // Output: rId1
                        }
                    } else {
                        print("r:id not found")
                    }
                    let pattern3 = #"sheetId="([^"]+)""#
                    if let regex3 = try? NSRegularExpression(pattern: pattern3),
                       let match3 = regex3.firstMatch(in: snippet, range: NSRange(snippet.startIndex..., in: snippet)) {
                        if let range3 = Range(match3.range(at: 1), in: snippet) {
                            sheetIdValue = String(snippet[range3])
                            print(sheetIdValue) // Output: rId1
                        }
                    } else {
                        print("sheetId not found")
                    }
                } else {
                    print("Sheet not found")
                }
                
                
                
                if rIdValue != "" && snippet != "" && sheetIdValue != ""{
                    xmlString3 = xmlString3?.replacingOccurrences(of: snippet, with: "")
                    try? xmlString3?.write(to: wkbookDirectoryURL, atomically: true, encoding: .utf8)
                    
                    
                    let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                    
                    
                    let rIdValueNumber = numberOnlyString(text: rIdValue)
                    let sheetIdValueNumber = numberOnlyString(text: sheetIdValue)
                    //print("sheetFiles: ", sheetXMLFiles.count)
                    //TODO delete the xml file
                    let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(sheetIdValueNumber)  + ".xml")
                    try FileManager.default.removeItem(at: worksheetXMLURL)
       
                    //xl/_res/workbook
                    let _relsDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("_rels").appendingPathComponent("workbook.xml.rels")
                    
                    var xmlString = try? String(contentsOf: _relsDirectoryURL)
                    let pattern_xlres = "<Relationship Id=\"\(rIdValue)\"[^>]+/>"
                    if let range_xlres = xmlString?.range(of: pattern_xlres, options: .regularExpression) {
                        let snippet_xlres = String(xmlString![range_xlres])
                        print("snippet_xlres",snippet_xlres )
                        xmlString = xmlString?.replacingOccurrences(of: snippet_xlres, with: "")
                        try? xmlString?.write(to: _relsDirectoryURL, atomically: true, encoding: .utf8)
                    } else {
                        print("Relationship not found")
                    }
                }
                
                
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
    
    //TODO implement it
    func testReplaceStringBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int?, fString:String? = nil) -> URL? {
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
                
                //check missing files and create the missing ones
                if !FileManager.default.fileExists(atPath: shardStringXMLURL.path) {
                    let content = """
                    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                    <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="1" uniqueCount="1"></sst>
                    """
                    
                    try? content.write(to: shardStringXMLURL, atomically: true, encoding: .utf8)
                }
                
                
                //value and string update test TODO change it
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                
                let oldAry = testStringUniqueAry(url: shardStringXMLURL)
                
                if input.count > 0{
                    var check = false
                    //sharedString
                    let shredStringId = checkSharedStringsIndex(url: shardStringXMLURL,SSlist:oldAry!,word: input)
                    if shredStringId.0 == nil && (Float(input) != nil){
                        //value update
                        let replacedWithNewString = testUpdateValue(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString) ?? ""//A3
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
    
    func extractFunctionSubstring(from input: String) -> String? {
        let pattern1 = "<f.*?/>"
        if let range = input.range(of: pattern1, options: .regularExpression) {
            return String(input[range])
        }
        
        let pattern2 = "<f>(.*?)</f>"
        if let range = input.range(of: pattern2, options: .regularExpression) {
            return String(input[range])
        }
        return ""
    }
    
    //TODO
    //b: Boolean (0 or 1)
    //d: Date (in ISO 8601 format)
    //e: Error (error message text)
    //inlineStr: Inline string (actual string value stored directly in the cell element)
    //n: Number
    //s: Shared string (an index to the shared string table)
    func extractFunctionTtagSubstring(from input: String) -> String? {
        if input.contains("t=\"str\""){
            return "t=\"str\""
        }
        if input.contains("t=\"str\""){
            return "t=\"str\""
        }
        return ""
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
                let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent(url.lastPathComponent)
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
