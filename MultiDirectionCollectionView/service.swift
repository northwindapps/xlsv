//
//  service.swift
//  xmlProject
//
//  Created by yujin on 2020/10/21.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation
import Zip




// Define a class to act as the delegate for the XMLParser
class XMLParserHelper: NSObject, XMLParserDelegate {
    var siElementCount: Int = -1
    var currentElement: String?
    var currentText: String?

    // Called when the parser finds the start of an element
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "si" {
            siElementCount += 1
        }
    }

    // Called when the parser finds the characters inside an element
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText = (currentText ?? "") + string
    }

    // Called when the parser finds the end of an element
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "t" {
            //print("Content of <t> element:", currentText)
            currentText = ""
        }
    }
}

class CustomXMLParserDelegate: XMLParserHelper {
    var foundTargetElement = false
    var extractedPart: String?

    override func parser(_ parser: XMLParser, foundCharacters string: String) {
        if foundTargetElement {
            extractedPart = (extractedPart ?? "") + string
        }
    }

    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "c" && attributeDict["r"] == "B1" {
            foundTargetElement = true
            // Start building the extracted part string
            extractedPart = "<\(elementName)"
            for (key, value) in attributeDict {
                extractedPart! += " \(key)=\"\(value)\""
            }
            extractedPart! += ">"
        }
    }

    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if foundTargetElement && elementName == "c" {
            foundTargetElement = false
            // Close the extracted part string
            extractedPart! += "</\(elementName)>"
        }
    }
}

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
    
    func testUpdateValue(url:URL? = nil, newValue:Float?) -> String?{
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
            let pattern = "<c r=\"B2\".*?>(.*?)</c>"//#"<c\s+r="B1".*?</c>"#
            
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

    func testXml(url:URL? = nil){
        var new_count : Int?
        var new_count2 : Int?
        if let url2 = url{
            var xmlString = try? String(contentsOf: url2)
            
            // Find the position to insert the new <si> element
            if let range = xmlString!.range(of: "</sst>") {
                // Construct the new <si> element
                let newSIElement = "<si><t>def</t></si>"
                
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
                
                // Write the modified XML data back to the file
                try? xmlString?.write(to: url2, atomically: true, encoding: .utf8)
                
                print("New <si> element inserted successfully.")
            } else {
                print("Failed to find </sst> in the XML data.")
            }
            
            //
            // Regular expression pattern to match the count attribute
            let pattern = #"\bcount\s*=\s*"(\d+)""#

            // Regular expression options
            let options: NSRegularExpression.Options = [.caseInsensitive]

            // Create a regular expression object
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                fatalError("Invalid regular expression pattern")
            }
            
            //
            // Find the first match of the count attribute
            if let match = regex.firstMatch(in: xmlString!, options: [], range: NSRange(xmlString!.startIndex..., in: xmlString!)) {
                // Extract the count value from the match
                if let range = Range(match.range(at: 1), in: xmlString!),
                   let count = Int(xmlString![range]) {
                    print("Count attribute value:", count)
                    new_count = count + 1
                } else {
                    print("Failed to extract count attribute value")
                }
            } else {
                print("Count attribute not found")
            }

            
            // New value for the attribute
            if (new_count != nil){
                // Replace the count and uniqueCount attributes with new values
                // Replace the count attribute with the new value
                let modifiedString = regex.stringByReplacingMatches(in: xmlString!, options: [], range: NSRange(xmlString!.startIndex..., in: xmlString!), withTemplate: "count=\"\(new_count!)\"")
                xmlString = modifiedString
                
                // Write the modified XML data back to the file
                try? xmlString?.write(to: url2, atomically: true, encoding: .utf8)
            }
            
            // Regular expression pattern to match the count and uniqueCount attributes
            let pattern2 = #"\buniqueCount\s*=\s*"(\d+)""#

            // Regular expression options
            let options2: NSRegularExpression.Options = [.caseInsensitive]

            // Create a regular expression object
            guard let regex2 = try? NSRegularExpression(pattern: pattern2, options: options2) else {
                fatalError("Invalid regular expression pattern")
            }

            // Find matches for count and uniqueCount attributes
            let matches2 = regex2.matches(in: xmlString!, options: [], range: NSRange(xmlString!.startIndex..., in: xmlString!))

            // Iterate through the matches and extract the attribute values
            for match in matches2 {
                for i in 1..<match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: xmlString!),
                       let value = Int(xmlString![range]) {
                        let attributeName = (xmlString! as NSString).substring(with: match.range(at: 0))
                        print("\(attributeName) attribute value:", value)
                        new_count2 = value + 1
                    }
                }
            }
            
            // New value for the attribute
            if (new_count2 != nil){
                // Replace the count and uniqueCount attributes with new values
                // Replace the count attribute with the new value
                let modifiedString = regex2.stringByReplacingMatches(in: xmlString!, options: [], range: NSRange(xmlString!.startIndex..., in: xmlString!), withTemplate: "uniqueCount=\"\(new_count2!)\"")
                xmlString = modifiedString
                
                // Write the modified XML data back to the file
                try? xmlString?.write(to: url2, atomically: true, encoding: .utf8)
            }
        }
    }
    
    func tesstSandBox(fp: String = "", url: URL? = nil) -> URL? {
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
                                let files = try FileManager.default.contentsOfDirectory(at:
                                                                                            subdirectoryURL, includingPropertiesForKeys: nil)
                                for fileURL in files {
                                           do {
                                               try FileManager.default.removeItem(at: fileURL)
                                               print("Deleted file:", fileURL.lastPathComponent)
                                           } catch {
                                               print("Error deleting file:", error)
                                           }
                                       }
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
                    
                    testXml(url: shardStringXMLURL)
                    
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    
                    //value update test
                    let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet1.xml")
                    
                    let replacedWithNewValue = testUpdateValue(url: worksheetXMLURL,newValue: -13.3)
                    
                    // Write the modified XML data back to the file
                    try? replacedWithNewValue?.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                    
                    
                    //ready to zip
                    let productURL = subdirectoryURL.appendingPathComponent("imported2.xlsx")
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
    
}


extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}



