//
//  service.swift
//  xmlProject
//
//  Created by yujin on 2020/10/21.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation
import Zip

class Service{
    var sheetNumber:Int
    var stringContents:[String]
    
    var locations:[String]
    
    var sheetIdx:[Int]
    
    var customFileName:String
    
    var formulaContens:[String]
    
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
    
    func tesstSandBox(fp: String = "", url: URL? = nil) {
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
                            }
                    
                    // Construct the URL for the destination file
                    let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                           //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
                           
                           // Check if the file already exists at the destination
                           if FileManager.default.fileExists(atPath: destinationURL.path) {
                               print("File already exists at the destination.")
                               
                               do {
                                   //unzip
                                   let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                                   
                                       print("File unzipped successfully.")
                                   } catch {
                                       print("Error unzipping file: \(error)")
                                   }
                           } else {
                               // Move the file to the subdirectory
                               try FileManager.default.moveItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                               print("File moved successfully to: \(destinationURL.path)")
                           }
                    
                    
                    
                    
                    
                    let files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    print("this is excel dir",files)
                    
                    
                    
                        } else {
                            // Handle the case where the specified path doesn't exist
                            print("File or directory does not exist at path: \(fp)")
                        }
                
                // Check if the directory exists
                let fp_or_default_variable = fp.isEmpty ? driveURL.path : fp
                if FileManager.default.fileExists(atPath: fp_or_default_variable) {
                    // Get a list of files in the directory
                    let files = try FileManager.default.contentsOfDirectory(at:
                                                                                URL.init(fileURLWithPath: fp_or_default_variable), includingPropertiesForKeys: nil)
                    print("fp",fp)
                    print("here is the files list",files)
                    
                    // Zip the files (assuming you have a Zip library)
                    //let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                    
                    //try Zip.quickUnzipFile(zipFilePath)
                        
//
//                    if FileManager.default.fileExists(atPath: zipFilePath.path) {
//                        // Copy the zip file to the specified path
//                        try FileManager.default.copyItem(at: zipFilePath, to: path.appendingPathComponent(fileName))
//                        print("Done: ", path.appendingPathComponent(fileName).path)
//                    }
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



