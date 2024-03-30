//
//  service.swift
//  xmlProject
//
//  Created by yujin on 2020/10/21.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation
import Zip


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
                    let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
                    var items = modified.components(separatedBy: "!")
                    //first is always ""
                    let item = items[1] ?? ""
                    print("item", item)
                    //string
                    if(item.contains("<v>") && item.contains("t=\"s\"")){
                        var startCpart = item.components(separatedBy:"<v>").first
                        print("string", startCpart)//+<v>new value</v> + endCpart <c r=\"B1\" s=\"89\" t=\"s\"><v>0</v></c>
                        //startCpart = startCpart!.replacingOccurrences(of: "t=\"s\"", with: "")
                        if((vIndex) != nil){
                            let replacing = startCpart! + "<v>" + String(vIndex!) + "</v></c>"
                            let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                            return replaced
                        }
                        let replacing = startCpart!.replacingOccurrences(of: ">", with: "/>")
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        return replaced
                    }
                    
                    //value
                    if(item.contains("<v>")){
                        var startCpart = item.components(separatedBy:"<v>").first
                        startCpart = startCpart!.replacingOccurrences(of: ">", with: " t=\"s\">")
                        if((vIndex) != nil){
                            let replacing = startCpart! + "<v>" + String(vIndex!) + "</v></c>"
                            let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                            return replaced
                        }
                        let replacing = startCpart!.replacingOccurrences(of: ">", with: "/>")
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        return replaced
                        
                    }
                    
                    //empty <c r="B2" s="4"/>
                    if((vIndex) != nil){
                        let replacing = item.replacingOccurrences(of: "/>", with: " t=\"s\">") + "<v>" + String(vIndex!) + "</v></c>"
                        let replaced = xmlString?.replacingOccurrences(of: item, with: replacing)
                        return replaced
                    }
                    return item
                }
            }
        }
        return nil
    }
    
    func testUpdateValue(url:URL? = nil, newValue:Float?, index:String?) -> String?{
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
                // Print the extracted texts
//                print("t",delegate.texts)
//                print("t count", delegate.texts.count)
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

    func checkSharedStringsIndex(url:URL? = nil, SSlist:[String] = [], word:String)->Int?{
        var new_count : Int?
        var new_count2 : Int?
        
        if word == ""{
            return nil
        }
        
        if let url2 = url{
            var xmlString = try? String(contentsOf: url2)
            let INDEX_1_DIFF_ADJUST = 1
            
            //
            if let idx = SSlist.firstIndex(of:word) {
                print("String exists at", idx + INDEX_1_DIFF_ADJUST)
                return idx + INDEX_1_DIFF_ADJUST
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
                    
                    // Write the modified XML data back to the file
                    try? xmlString?.write(to: url2, atomically: true, encoding: .utf8)
                    
                    print("New <si> element inserted successfully.")
                    return SSlist.count
                } else {
                    print("Failed to find </sst> in the XML data.")
                }
            }
        }
        return nil
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
                    
                    let oldAry = testStringUniqueAry(url: shardStringXMLURL)
                    
                    let idx = checkSharedStringsIndex(url: shardStringXMLURL,SSlist:oldAry!,word: "goodbyework")
                    
                    
                        let replacedWithNewString = testUpdateString(url:worksheetXMLURL, vIndex: String(idx!), index: "N2")
                        // Write the modified XML data back to the file
                    if(idx != nil && replacedWithNewString != nil){
                        try? replacedWithNewString!.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                    }
                    
                    let newAry = testStringUniqueAry(url: shardStringXMLURL)
                    
                    let oldUniqueCount = testStringOldUniqueCount(url: shardStringXMLURL)
                    
                    
                    
                    //update Values
                    let replacedWithNewValue = testUpdateValue(url: worksheetXMLURL,newValue: -30, index: "E2")
                    
                    // Write the modified XML data back to the file
                    try? replacedWithNewValue?.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                    
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



