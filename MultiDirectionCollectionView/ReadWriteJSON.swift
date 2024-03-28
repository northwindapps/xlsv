//
//  ReadWriteJSON.swift
//  MultiDirectionCollectionView
//
//  Created by yujin on 2020/05/09.
//  Copyright © 2020 Credera. All rights reserved.
//

import Foundation
import UIKit

class ReadWriteJSON {


    var content = [String]()
    var location = [String]()
    var fontsize = [String]()
    var fontcolor = [String]()
    var bgcolor = [String]()
    var rowsize = Int()
    var columnsize = Int()
    var customcellWidth = [Double]()
    var customcellHeight = [Double]()
    var ccwLocation = [Int]()
    var cchLocation = [Int]()
    var formulaResult = [String]()
    
    //https://stackoverflow.com/questions/28768015/how-to-save-an-array-as-a-json-file-in-swift
    func saveJsonFile(source:Dictionary<String, Any>, title :String){
        let pathDirectory = getDocumentsDirectory()
        
        //checking /sub root folder existance
        if FileManager.default.fileExists(atPath: pathDirectory.path){
           
        }else{
            do{
                try? FileManager().createDirectory(at: pathDirectory, withIntermediateDirectories: true)
                print("/json/sub folder created")
            }
        }
        
        
        
        let filePath = pathDirectory.appendingPathComponent("/" + title)
        var datedata = Date()
        
        //let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
        
        do {
                //let fileURLs = try FileManager.default.contentsOfDirectory(at: pathDirectory, includingPropertiesForKeys: nil)
                if FileManager.default.fileExists(atPath: filePath.path){
                    let attr = try FileManager.default.attributesOfItem(atPath: filePath.path)
                    datedata = attr[FileAttributeKey.modificationDate] as! Date //modificationDate
                    
                    deleteJsonFile(title: title)
                    print("overwritten ")
                }
            
        } catch {
            print("Failed to write JSON data: \(error.localizedDescription)")
        }
        
        do{
             try! JSONSerialization.data(withJSONObject: source).write(to: filePath)
            print("savedJson",filePath)
         
        }
        
        do {
            //https://stackoverflow.com/questions/33846694/setting-file-attributes-in-swift
            //https://stackoverflow.com/questions/13497500/retrieve-file-creation-or-modification-date/13516795
            
            let attributes = [
                FileAttributeKey.modificationDate : datedata
            ]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: filePath.path)
//            print("setdate",datedata)
            
            //
            let attr = try FileManager.default.attributesOfItem(atPath: filePath.path)
            let check = attr[FileAttributeKey.creationDate] as! Date //modificationDate
//            print("setdate-check",check)
        } catch {
            print(error)
        }
    }
    
    // https://stackoverflow.com/questions/28768015/how-to-save-an-array-as-a-json-file-in-swift
    // https://stackoverflow.com/questions/26386093/array-from-dictionary-keys-in-swift
    //func readJsonFIle()-> ([String],[String]) {
    func readJsonFile(title:String)->Bool {
        let pathDirectory = getDocumentsDirectory()
        let filePath = pathDirectory.appendingPathComponent("/" + title + ".xml")//title:shee1,sheet2,sheet3...
        let fileManager = FileManager.default
        print("readFile",filePath)
        if fileManager.fileExists(atPath: filePath.path){
            
            do {
                let data = try Data(contentsOf: filePath, options: [])
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any>

                for (key, value) in dict! {
                    // access all key / value pairs in dictionary
                    switch key {
                    case "content":
                        content = value as! [String]
                        break
                    case "location":
                        location = value as! [String]
                        break
                    case "fontsize":
                        fontsize = value as! [String]
                        break
                    case "fontcolor":
                        fontcolor = value as! [String]
                        break
                    case "bgcolor":
                        bgcolor = value as! [String]
                        break
                    case "rowsize":
                        rowsize = value as! Int
                        break
                    case "columnsize":
                        columnsize = value as! Int
                        break
                    case "customcellWidth":
                        customcellWidth = value as! [Double]
                        break
                    case "customcellHeight":
                        customcellHeight = value as! [Double]
                        break
                    case "ccwLocation":
                        ccwLocation = value as! [Int]
                        break
                    case "cchLocation":
                        cchLocation = value as! [Int]
                        break
                    
                    default:
                        break
                    }
                }
                saveuserAll()
                return true
                
            } catch {
                print(error)
            }
        }
        return false
        
    }
    
    func readJsonForSheet(title:String)->([String],[String],[String],[String]) {
            var file_content = [String]()
            var file_content_location = [String]()
            var file_formula_result = [String]()
            var input_order = [String]()
           
           let pathDirectory = getDocumentsDirectory()
           let filePath = pathDirectory.appendingPathComponent("/" + title)
           let fileManager = FileManager.default
           if fileManager.fileExists(atPath: filePath.path){
               
               do {
                   let data = try Data(contentsOf: filePath, options: [])
                   let dict = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any>

                   for (key, value) in dict! {
                       // access all key / value pairs in dictionary
                       switch key {
                       case "content":
                           file_content = value as! [String]
                           break
                       case "location":
                           file_content_location = value as! [String]
                           break
                       case "formulaResult":
                            file_formula_result = value as! [String]
                            break
                        case "inputOrder":
                            input_order = value as! [String]
                            break
                  
                       default:
                           break
                       }
                   }
                   
               } catch {
                   print(error)
               }
           }
           return (file_content,file_content_location,file_formula_result,input_order)
       }
    
    func fileModificationDate(url: URL) -> Date? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            return attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
    func deleteJsonFile(title :String){
        print("Delete")
        let pathDirectory = getDocumentsDirectory()
       
        let filePath = pathDirectory.appendingPathComponent("/" + title)
        
        //let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
        
        do {
            //let fileURLs = try FileManager.default.contentsOfDirectory(at: pathDirectory, includingPropertiesForKeys: nil)
            if FileManager.default.fileExists(atPath: filePath.path){
                try FileManager.default.removeItem(at: filePath)
            }
        } catch {
            print("Failed to delete JSON data: \(error.localizedDescription)")
        }
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        
        do
        {
            if FileManager.default.fileExists(atPath: paths[0].appendingPathComponent("sub/").path){
              
            }else{
                print("json/ recreate")
                try FileManager.default.createDirectory(at: paths[0].appendingPathComponent("sub/"), withIntermediateDirectories: true, attributes: nil)
            }
        }
        catch let error as NSError
        {
            print("Unable to create directory \(error.debugDescription)")
        }
       
//        print("JSONFOLDER",paths[0].appendingPathComponent("sub/"))
        return paths[0].appendingPathComponent("sub/")
    }
    
    func saveuserAll() {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let location1 = UserDefaults.standard
        location1.set(location, forKey: "NEWTMLOCATION")
        location1.synchronize()
        
        let content1 = UserDefaults.standard
        content1.set(content, forKey: "NEWTMCONTENT")
        content1.synchronize()
        
        let appheight = UserDefaults.standard
        appheight.set(columnsize, forKey: "NEWCsize")
        appheight.synchronize()
        
        let appheight2 = UserDefaults.standard
        appheight2.set(rowsize, forKey: "NEWRsize")
        appheight2.synchronize()
        
        let content2 = UserDefaults.standard
        content2.set(bgcolor, forKey: "NEWTMBGCOLOR")
        content2.synchronize()
        
        
        let content3 = UserDefaults.standard
        content3.set(fontcolor, forKey: "NEWTMTCOLOR")
        content3.synchronize()
        
        let content4 = UserDefaults.standard
        content4.set(fontsize, forKey: "NEWTMSIZE")
        content4.synchronize()
        
        appd.customSizedWidth = customcellWidth
        let r2 = UserDefaults.standard
        r2.set(appd.customSizedWidth, forKey: "NEW_CELL_WIDTH")
        r2.synchronize()
        
        appd.cswLocation = ccwLocation
        let r3 = UserDefaults.standard
        r3.set(appd.cswLocation, forKey: "NEW_CELL_WIDTH_LOCATION")
        r3.synchronize()
        
        appd.customSizedHeight = customcellHeight
        let r4 = UserDefaults.standard
        r4.set(appd.customSizedHeight, forKey: "NEW_CELL_HEIGHT")
        r4.synchronize()
        
        appd.cshLocation = cchLocation
        let r5 = UserDefaults.standard
        r5.set(appd.cshLocation, forKey: "NEW_CELL_HEIGHT_LOCATION")
        r5.synchronize()
        
        print("saved on userdefault")
    }
}
