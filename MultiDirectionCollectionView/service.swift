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
    
    func validateXML(xmlString: String) -> Bool {
        do {
            let _ = try XML.parse(xmlString)
            return true
        } catch {
            print("XML validation error: \(error)")
            return false
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
    
    //making now
    func testExtractStyle(url:URL? = nil){
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
        }
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
                    let matchingSubstring = xmlString![matchRange]
                    var replacing0 = matchingSubstring.components(separatedBy: "><v>").first! + "/>"
                    
                    let replaced = xmlString?.replacingOccurrences(of: matchingSubstring, with: replacing0)
                    return replaced
                }
            }
        }
        return nil
    }
    
    //making now
    func testUpdateString(url:URL? = nil, vIndex:String?, index:String?) -> String?{
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
            let pattern = "<c r=\"\(String(index!))\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
            
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
                    let matchingSubstring = xmlString![matchRange]
                    //let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
                    //var items = modified.components(separatedBy: "!")
                    //first is always ""
                    let occurrences = String(matchingSubstring).components(separatedBy: "<c").count
                    var item = String(matchingSubstring)
                    if occurrences > 1{
                        item = "<c" + String(matchingSubstring).components(separatedBy: "<c")[1]
                    }
                    print("item", item)
                    //string
                    if(item.contains("<v>") && item.contains("t=\"s\"")){
                        var startCpart = item.components(separatedBy:"<v>").first
                        print("string", startCpart)//+<v>new value</v> + endCpart <c r=\"B1\" s=\"89\" t=\"s\"><v>0</v></c>
                        //startCpart = startCpart!.replacingOccurrences(of: "t=\"s\"", with: "")
                        if((vIndex) != nil){
                            let replacing = startCpart! + "<v>" + String(vIndex!) + "</v></c>"
                            let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                            if validateXML(xmlString: replaced!) {
                                print("XML is valid.")
                                return replaced
                            } else {
                                print("XML is not valid.")
                                print(replaced)
                                return backUpXmlString
                            }
                        }
                        let replacing = startCpart!.replacingOccurrences(of: ">", with: "/>")
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        
                        if validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                            return replaced
                        } else {
                            print("XML is not valid.")
                            print(replaced)
                            return backUpXmlString
                        }
                    }
                    
                    //value
                    if(item.contains("<v>") && item.contains("t=\"s\"")){
                        var startCpart = item.components(separatedBy:"<v>").first
                        startCpart = startCpart!.replacingOccurrences(of: ">", with: " t=\"s\">")
                        if((vIndex) != nil){
                            let replacing = startCpart! + "<v>" + String(vIndex!) + "</v></c>"
                            let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                            if validateXML(xmlString: replaced!) {
                                print("XML is valid.")
                                return replaced
                            } else {
                                print("XML is not valid.")
                                print(replaced)
                                return backUpXmlString
                            }
                        }
                        let replacing = startCpart!.replacingOccurrences(of: ">", with: "/>")
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        if validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                            return replaced
                        } else {
                            print("XML is not valid.")
                            print(replaced)
                            return backUpXmlString
                        }
                    }
                    
                    //empty <c r="B2" s="4"/>
                    //"<c r=\"B2\" s=\"61\"><v>2023</v></c>"
                    if((vIndex) != nil && item.hasSuffix("/>") ){
                        let replacing = item.replacingOccurrences(of: "/>", with: " t=\"s\">") + "<v>" + String(vIndex!) + "</v></c>"
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        if validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                            return replaced
                        } else {
                            print("XML is not valid.")
                            print(replaced)
                            return backUpXmlString
                        }
                    }
                    return backUpXmlString
                }
            }else{
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
                            let newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                            
                            var replacing = targetRowTag.replacingOccurrences(of: "</row>", with: "")
                            replacing = replacing + newElement + "</row>"
                            let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                            print(replaced)
                            if validateXML(xmlString: replaced!) {
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
                                    let matchingSubstring = targetRowTag[matchRange]
                                    let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
                                    var items = modified.components(separatedBy: "!")
                                    //first is always ""
                                    let item = items[1] ?? ""
                                    print("item", item)
                                    let newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                                    // Find the correct position to insert the new element
                                    if let range = xmlString?.range(of: item) {
                                        // Insert the new element after the element with r="J2"
                                        xmlString?.insert(contentsOf: newElement, at: range.lowerBound)
                                        if validateXML(xmlString: xmlString!) {
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
                        if targetRowTag == ""{
                            let newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c></row>"
                            let replaced = xmlString?.replacingOccurrences(of: "<sheetData>", with: newElement)
                           
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
                                            let ary = [indices1,indices2]
                                            
                                            let sortedArray = ary.sorted { (string1, string2) -> Bool in
                                                return string1! < string2! // Compare strings in descending order
                                            }
                                            
                                            print(ary)
                                              
                                            
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
                                        //print(cell)
                                    }
                                }
                            } else {
                                print("No rows found or there are no children under the specified path")
                            }
                            
                            if validateXML(xmlString: xml.description) {
                                print("XML is valid.")
                                return xml.description
                            } else {
                                print("XML is not valid.")
                                print(xml.description)
                                return backUpXmlString
                            }
                        }else{
                            //targetRowTag   "<row r=\"1\"><c r=\"B1\" t=\"s\"><v>78</v></c></row>"
                            var rowPart = targetRowTag.components(separatedBy: "><c").first! + ">"
                            let rowNumber = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            let newElement2 = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                            
                            var replacing = targetRowTag.replacingOccurrences(of: "</row>", with: "")
                            replacing = replacing + newElement2 + "</row>"
                            if replacing .contains("/><c"){
                                let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing.replacingOccurrences(of: "/><c", with: "><c"))
                                if validateXML(xmlString: replaced!) {
                                    print("XML is valid.")
                                    return replaced
                                } else {
                                    print("XML is not valid.")
                                    print(xmlString)
                                    return backUpXmlString
                                }
                            }
                            let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                            let old = xmlString
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
                            
                            let final = old!.replacingOccurrences(of: targetRowTag, with: rowPart + "</row>")
                            if validateXML(xmlString: final) {
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
            
        }
        return nil
    }
    
    //todo creating
    func testUpdateValue(url:URL? = nil, vIndex:String?, index:String?) -> String?{
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
            let pattern = "<c r=\"\(String(index!))\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
            
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
                    let matchingSubstring = xmlString![matchRange]
                    //let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
                    //var items = modified.components(separatedBy: "!")
                    //first is always ""
                    let occurrences = String(matchingSubstring).components(separatedBy: "<c").count
                    var item = String(matchingSubstring)
                    if occurrences > 1{
                        item = "<c" + String(matchingSubstring).components(separatedBy: "<c")[1]
                    }
                    print("item", item)
                    //string
                    if(item.contains("<v>") && item.contains("t=\"s\"")){
                        var startCpart = item.components(separatedBy:"<v>").first
                        print("string", startCpart)//+<v>new value</v> + endCpart <c r=\"B1\" s=\"89\" t=\"s\"><v>0</v></c>
                        //startCpart = startCpart!.replacingOccurrences(of: "t=\"s\"", with: "")
                        if((vIndex) != nil){
                            let replacing = startCpart! + "<v>" + String(vIndex!) + "</v></c>"
                            let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                            if validateXML(xmlString: replaced!) {
                                print("XML is valid.")
                                return replaced
                            } else {
                                print("XML is not valid.")
                                print(replaced)
                                return backUpXmlString
                            }
                        }
                        let replacing = startCpart!.replacingOccurrences(of: ">", with: "/>")
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        
                        if validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                            return replaced
                        } else {
                            print("XML is not valid.")
                            print(replaced)
                            return backUpXmlString
                        }
                    }
                    
                    //value
                    if(item.contains("<v>") && item.contains("t=\"s\"")){
                        var startCpart = item.components(separatedBy:"<v>").first
                        startCpart = startCpart!.replacingOccurrences(of: ">", with: " t=\"s\">")
                        if((vIndex) != nil){
                            let replacing = startCpart! + "<v>" + String(vIndex!) + "</v></c>"
                            let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                            if validateXML(xmlString: replaced!) {
                                print("XML is valid.")
                                return replaced
                            } else {
                                print("XML is not valid.")
                                print(replaced)
                                return backUpXmlString
                            }
                        }
                        let replacing = startCpart!.replacingOccurrences(of: ">", with: "/>")
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        if validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                            return replaced
                        } else {
                            print("XML is not valid.")
                            print(replaced)
                            return backUpXmlString
                        }
                    }
                    
                    //empty <c r="B2" s="4"/>
                    //"<c r=\"B2\" s=\"61\"><v>2023</v></c>"
                    if((vIndex) != nil && item.hasSuffix("/>") ){
                        let replacing = item.replacingOccurrences(of: "/>", with: " t=\"s\">") + "<v>" + String(vIndex!) + "</v></c>"
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        if validateXML(xmlString: replaced!) {
                            print("XML is valid.")
                            return replaced
                        } else {
                            print("XML is not valid.")
                            print(replaced)
                            return backUpXmlString
                        }
                    }
                    return backUpXmlString
                }
            }else{
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
                            let newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                            
                            var replacing = targetRowTag.replacingOccurrences(of: "</row>", with: "")
                            replacing = replacing + newElement + "</row>"
                            let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                            print(replaced)
                            if validateXML(xmlString: replaced!) {
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
                                    let matchingSubstring = targetRowTag[matchRange]
                                    let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
                                    var items = modified.components(separatedBy: "!")
                                    //first is always ""
                                    let item = items[1] ?? ""
                                    print("item", item)
                                    let newElement = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                                    // Find the correct position to insert the new element
                                    if let range = xmlString?.range(of: item) {
                                        // Insert the new element after the element with r="J2"
                                        xmlString?.insert(contentsOf: newElement, at: range.lowerBound)
                                        if validateXML(xmlString: xmlString!) {
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
                        if targetRowTag == ""{
                            let newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c></row>"
                            let replaced = xmlString?.replacingOccurrences(of: "<sheetData>", with: newElement)
                           
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
                                            let ary = [indices1,indices2]
                                            
                                            let sortedArray = ary.sorted { (string1, string2) -> Bool in
                                                return string1! < string2! // Compare strings in descending order
                                            }
                                            
                                            print(ary)
                                              
                                            
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
                                        //print(cell)
                                    }
                                }
                            } else {
                                print("No rows found or there are no children under the specified path")
                            }
                            
                            if validateXML(xmlString: xml.description) {
                                print("XML is valid.")
                                return xml.description
                            } else {
                                print("XML is not valid.")
                                print(xml.description)
                                return backUpXmlString
                            }
                        }else{
                            //targetRowTag   "<row r=\"1\"><c r=\"B1\" t=\"s\"><v>78</v></c></row>"
                            var rowPart = targetRowTag.components(separatedBy: "><c").first! + ">"
                            let rowNumber = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            let newElement2 = "<c r=\"\(String(index!))\" t=\"s\"><v>\(String(vIndex!))</v></c>"
                            
                            var replacing = targetRowTag.replacingOccurrences(of: "</row>", with: "")
                            replacing = replacing + newElement2 + "</row>"
                            if replacing .contains("/><c"){
                                let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing.replacingOccurrences(of: "/><c", with: "><c"))
                                if validateXML(xmlString: replaced!) {
                                    print("XML is valid.")
                                    return replaced
                                } else {
                                    print("XML is not valid.")
                                    print(xmlString)
                                    return backUpXmlString
                                }
                            }
                            let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
                            let old = xmlString
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
                            
                            let final = old!.replacingOccurrences(of: targetRowTag, with: rowPart + "</row>")
                            if validateXML(xmlString: final) {
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
            
        }
        return nil
    }
    
    func _old_testUpdateValue(url:URL? = nil, newValue:Float?, index:String?) -> String?{
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
            
            // Define the regular expression pattern
            //let pattern = "<c r=\"D2\".*?>(.*?)</c>"//#"<c\s+r="B1".*?</c>"#
            let pattern = "<c r=\"\(String(index!))\".*?>(.*?)</c>"
            
            // Create the regular expression object
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches = regex.matches(in: xmlString!, range: range)
            
            // Extract matching substrings
            let match = matches.first
            if let matchRange = Range(match!.range, in: xmlString!) {
                let matchingSubstring = xmlString![matchRange]
                let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
                var items = modified.components(separatedBy: "!")
                //first is always ""
                let item = items[1] ?? ""
                print("item", item)
                //string
                if(item.contains("<v>") && item.contains("t=")){
                    var startCpart = item.components(separatedBy:"<v>").first
                    print("string", startCpart)//+<v>new value</v> + endCpart <c r=\"B1\" s=\"89\" t=\"s\"><v>0</v></c>
                    startCpart = startCpart!.replacingOccurrences(of: "t=\"s\"", with: "")
                    if((newValue) != nil){
                        let replacing = startCpart! + "<v>" + String(newValue!) + "</v></c>"
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        return replaced
                    }
                    let replacing = startCpart!.replacingOccurrences(of: ">", with: "/>")
                    let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                    return replaced
                }
                
                //value
                if(item.contains("<v>")){
                    let startCpart = item.components(separatedBy:"<v>").first
                    if((newValue) != nil){
                        let replacing = startCpart! + "<v>" + String(newValue!) + "</v></c>"
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        return replaced
                    }
                    let replacing = startCpart!.replacingOccurrences(of: ">", with: "/>")
                    let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                    return replaced
                    
                }
                
                //empty <c r="B2" s="4"/>
                if((newValue) != nil){
                    let replacing = item.replacingOccurrences(of: "/>", with: ">") + "<v>" + String(newValue!) + "</v></c>"
                    let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                    return replaced
                }
                return item
            }
        }
        return nil
    }
    
    func testStringUniqueAry(url:URL? = nil)->[String]?{
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
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
        return []
    }
    
    func testStringOldUniqueCount(url:URL? = nil){
        if let url2 = url{
            var xmlString = try? String(contentsOf: url2)
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
            let INDEX_1_DIFF_ADJUST = 1
            
            //
            if let idx = SSlist.firstIndex(of:word) {
                print("String exists at", idx + INDEX_1_DIFF_ADJUST)
                return (idx + INDEX_1_DIFF_ADJUST, xmlString)
            } else {
                print("String not exists.")
                // Find the position to insert the new <si> element
                if let range = xmlString!.range(of: "</sst>") {
                    // Construct the new <si> element
                    let newSIElement = "<si><t>" + word + "</t></si>"
                    
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
                    
                    //extract sytles
                    let styleXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("styles.xml")
                    testExtractStyle(url:styleXMLURL)
                    
                    
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
                    
                    
                    
                    //update Values
                    //let replacedWithNewValue = testUpdateValue(url: worksheetXMLURL,newValue: -30, index: "E2")
                    
                    // Write the modified XML data back to the file
                    //try? replacedWithNewValue?.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                    
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
                    testExtractStyle(url:styleXMLURL)
                    
                   
               
                    //update Values
                    //let replacedWithNewValue = testUpdateValue(url: worksheetXMLURL,newValue: -30, index: "E2")
                    
                    // Write the modified XML data back to the file
                    //try? replacedWithNewValue?.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                    
                    let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                    var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                    let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                        for file in sheetFiles {
                            print("Found .xml file:", file.lastPathComponent)
                        }
                    print("sheetFiles: ", sheetXMLFiles)
                    
                    
//                    //ready to zip
//                    var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
//                    let fpURL = URL(fileURLWithPath: fp)
//                    let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
//                    //appendingPathComponent("imported2.xlsx")
//                    let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
//                    let rlt = try FileManager.default.copyItem(at: zipFilePath, to: productURL)
//                    
//                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
//                    print("Done: ", files)
                    
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
    
    func testUpdateStringBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "") -> URL? {
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
                    let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                    let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                    
                    
                    let oldAry = testStringUniqueAry(url: shardStringXMLURL)
                    
                    if input.count > 0{
                        var check = false
                        let shredStringId = checkSharedStringsIndex(url: shardStringXMLURL,SSlist:oldAry!,word: input)
                        if shredStringId.0 == nil && (Float(input) != nil){
                            //value todo complete this function
                            let replacedWithNewString = testUpdateValue(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString)!//A3
                            // Write the modified XML data back to the file
                            if(replacedWithNewString != ""){
                                try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                                
                                //update sharedstring xml here
                                
                            }
                            check = true
                        }
                        let replacedWithNewString = testUpdateString(url:worksheetXMLURL, vIndex: String(shredStringId.0!), index: cellIdxString)!//A3
                        // Write the modified XML data back to the file
                        if(!check && replacedWithNewString != ""){
                            try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                            
                            // Write the modified XML data back to the file
                            try? shredStringId.1!.write(to: shardStringXMLURL, atomically: true, encoding: .utf8)
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


