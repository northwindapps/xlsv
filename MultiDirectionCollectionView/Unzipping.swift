//
//  Unzip.swift
//  read_write_file
//
//  Created by yujin on 2020/03/07.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation
import SSZipArchive
import Zip

class Unzipping {
    // maybe this class is ok.
    func unzip() {
        
        let url00 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dst = URL(fileURLWithPath: url00).appendingPathComponent("unziped/").path//sub root

        
        if FileManager.default.fileExists(atPath: dst) {
            print("overriding file")
//            clearTheFolder(paths: dst)
            //Good job securedcopy, thank you for deleting existing ones.
        }else{
            do {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: url00).appendingPathComponent("unziped/"), withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print("Something went wrong")
            }
        }
        
       
        let rootzDir  = URL(fileURLWithPath: url00).appendingPathComponent("macX/").path
        let success: Bool = SSZipArchive.unzipFile(atPath: rootzDir,
                                                   toDestination: dst,
                                                   preserveAttributes: true,
                                                   overwrite: true,
                                                   nestedZipLevel: 1,
                                                   password: nil,
                                                   error: nil,
                                                   delegate: nil,
                                                   progressHandler: nil,
                                                   completionHandler: nil)
        if success != false {
        print("Success unzip")
            
            
            
            
            
        } else {
            print("No success unzip")
            
            return
        }
        
        
    }
    
    func zip(){
        let url00 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

        do {
            
            //check..looks ok
            let dst2 = URL(fileURLWithPath: url00).appendingPathComponent("sub/").path//sub root
            if FileManager.default.fileExists(atPath: dst2) {
                let list = try FileManager.default.contentsOfDirectory(atPath: dst2)
                print("sub",list)
            }
            
            if FileManager.default.fileExists(atPath: url00) {
                //It's odd. It created file on the root directory.
                removeX()
                print("removex")
            }
            
            
            
            let dst = URL(fileURLWithPath: url00).appendingPathComponent("unziped/").path//sub root
            
            //check..looks ok
            if FileManager.default.fileExists(atPath: dst) {
                let list = try FileManager.default.contentsOfDirectory(atPath: dst)
                print("unziped", list)
            }
            
            
            
            let files = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: dst), includingPropertiesForKeys: nil)
            let zipFilePath = try Zip.quickZipFiles(files, fileName: "output") // Zip
            
            if FileManager.default.fileExists(atPath: zipFilePath.path) {
                //It's odd. It created file on the root directory.
                print("Done: ", zipFilePath.path)
            }
            
        }
        catch {
            print("Something went wrong")
        }
    }
    
    func clearTheFolder(paths:String){
        let fileManager = FileManager.default
        
        //let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        print("Directory: \(paths)")
        
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
    
    func loadLoacalXlsxfile(){
        //todo is to make a xlsx parser to get cells styles, bgcolor, tcolor, textsize.
    }
}
