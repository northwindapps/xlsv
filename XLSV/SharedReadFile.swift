//
//  ReadFile.swift
//  read_write_file
//
//  Created by yujin on 2020/02/29.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation
import Zip
import SSZipArchive
// Looks Ok.
class SharedReadFile {
    var myData: Data!
    let FILE_PATH = Bundle.main.url(forResource: "original/xl/sharedStrings", withExtension: "xml")
    let HEADER1 = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    var header2 = "<sst uniqueCount=\"UNIQUE_WORDS_COUNT\" xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"
    let FOOTER = "</sst>"
    let OPEN_ITEM_TAG = "<si><t>"
    let CLOSE_ITEM_TAG = "</t></si>"
    let COMMA = ","
    let NONE = ""
    var content_array = [String]()
    var location_array = [String]()
    
    func checking(){
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("unziped/xl/sharedStrings.xml")
            
            //override
            do
            {
                // If a file with the same name already here, the file would be deleted.
                if FileManager.default.fileExists(atPath: fileURL.path){
                    try FileManager.default.removeItem(at: fileURL)
                    print("file removed")
                }
                
                
            }catch let error {
                print(error.localizedDescription)
            }
            
            writeFile(fileURL: fileURL)
        }
    }
    
    func writeFile(fileURL: URL) {
        do {
            var thankyouForCorporation = [String]()
            var thankyouToo = [String]()
            var thankyourHelp = [String]()
            var productstr = ""
            var test_c = [String]()
            var test_l = [String]()
            
            // Pre process
            if (UserDefaults.standard.object(forKey: "NEWTMCONTENT") != nil) {
                test_c = UserDefaults.standard.object(forKey: "NEWTMCONTENT") as! Array
            }
            
            if (UserDefaults.standard.object(forKey: "NEWTMLOCATION") != nil) {
                test_l = UserDefaults.standard.object(forKey: "NEWTMLOCATION") as! Array
            }
            
            
            (productstr, thankyouForCorporation, thankyouToo, thankyourHelp) = setupFileContent(newtmc: test_c,newtml: test_l)
                
            myData = productstr.data(using: String.Encoding.utf8)
            try myData.write(to: fileURL)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func removeArrayItem(input:[String], keyword:String) -> [String]{
        var output = [String]()
        for v in 0..<input.count {
            if input[v].contains(keyword){
                
            }else{
                output.append(input[v])
            }
        }
        return output
    }
    
    func setupFileContent(newtmc:[String],newtml:[String])-> (String, [String], [String], [String]){
        
        var local_content = [String]()
        
        content_array = newtmc
        local_content = content_array
        content_array = uniquing(src: content_array)
        location_array = newtml
        
        
        //not sure it is correct..
        header2 = header2.replacingOccurrences(of: "UNIQUE_WORDS_COUNT", with: String(content_array.count))
        
        var content = ""
        content.append(HEADER1)
        content.append("\n")
        content.append(header2)
        
        for v in 0..<content_array.count {
            content.append(OPEN_ITEM_TAG)
            content.append(content_array[v]) //uniequewords
            content.append(CLOSE_ITEM_TAG)
        }
        
        content.append(FOOTER)//"</sst>"
        print("SharedRead:",content)
        
        //Wait this content array does not contain index values..remember that.
        var shared_xml_location = [String]()//0,1,2,3
        var shared_xml_reference = [String]()//A1
        for v in 0..<local_content.count{
            let idx = content_array.firstIndex(of: local_content[v])
            shared_xml_location.append(String(idx!))
            
            //Reference
            let ary = location_array[v].split(separator: ",")
            let number = Int(ary[0])
            let rownumber = Int(ary[1])
            let columnName = SpreadSheet().getExcelColumnName(columnNumber: number!)//it contains index? or not?
            shared_xml_reference.append(columnName + String(rownumber!))//C1
        }
        
        let shared_xml_unique_value = content_array
        
        // return text content and the locations of that
        return (content, shared_xml_location, shared_xml_reference, shared_xml_unique_value)
    }
    
//    <?xml version="1.0" encoding="UTF-8"?>
//    <sst uniqueCount="2" xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><si><t>v2</t></si><si><t>white</t></si></sst>

    
    
    func clearTheFolder(){
        let fileManager = FileManager.default
        
        //first flor! root folder clean up
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        //print("Directory: \(paths)")
        
        do
        {
            let fileName = try fileManager.contentsOfDirectory(atPath: paths)
            
            for file in fileName {
                // For each file in the directory, create full path and delete the file
                let filePath = URL(fileURLWithPath: paths).appendingPathComponent(file).absoluteURL
                try fileManager.removeItem(at: filePath)
            }
        }catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    func removeX(){
        let fileManager = FileManager.default
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        print("Directory: \(paths)")
        
        do
        {
            
            let url1 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let filePath = URL(fileURLWithPath: url1).appendingPathComponent("output.zip")
            
            
            if let fileData = NSData(contentsOf: filePath) {
                
                try fileManager.removeItem(at: filePath)
                print("removeX")
            }
            
        }catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    //Making the array with unique values
    func uniquing(src:[String]) -> [String]{
        var unique = [String]()
        
        for i in 0 ..< src.count {
            if unique.contains(src[i])
            {
                
            }else{
                unique.append(src[i])
            }
        }
        return unique
    }
    

}


