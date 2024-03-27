//
//  ExcelHelper.swift
//  MultiDirectionCollectionView
//
//  Created by yujin on 2024/03/27.
//  Copyright © 2024 Credera. All rights reserved.
//

import UIKit
import CoreXLSX
import Foundation


class ExcelHelper{
    
    var location = [String]()
    var contents = [String]()
    
    
    //excel file
    var columnName = [String]()
    var stringLocation = [String]()
    var stringContent = [String]()
    var valueLocation = [String]()
    var valueContent = [String]()
    
    var excelName = ""
    var dict = [[String:AnyObject]]()// = [-1:["location":["a2","b2"],"content":["apple","orange"],"column":20,"row":30] as AnyObject]
    var dictMergedCellList = [String]()
    var mergedCellsLocation = [[String:AnyObject]]()
    
    

    func readExcel(path:String, wsIndex:Int = 1){
       //TODO NOT WORKING SHOULD I REPLACE WHOLE JSON FILES?
       do {
           let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
           appd.ws_total_pages = 0
           appd.ws_path = path
           let file = XLSXFile(filepath: path)
           
           //appd.ws_total_pages = sheetsNumber
           //only show first page.
           //for path in try file!.parseWorksheetPaths() {
           let paths = try file!.parseWorksheetPaths()
           // Filter files with "sheet1.xml" in their file name
           let sheet1Files = paths.filter { $0.hasSuffix("sheet" + String(wsIndex) + ".xml") }
           if let path = try sheet1Files.first {
               print("path",path)
               //Cleaning instances on table data
               columnName = []
               stringLocation = []
               stringContent = []
               valueLocation = []
               valueContent = []
               
               let container = try file!.parseWorksheet(at: path).data?.rows.flatMap { $0.cells } ?? []
    //                let container = try file!.parseWorksheetPaths() too slow...
    //                    .compactMap { try file!.parseWorksheet(at: $0) }
    //                    .flatMap { $0.data?.rows ?? [] }
    //                    .flatMap { $0.cells }
               columnName = uniquing(src:container.map { $0.reference.column.value })//AA AS AW E
               
               
               //mergedcells initialization
               appd.diff_start_index.removeAll()
               appd.diff_end_index.removeAll()
               let mergedCells = try file!.parseWorksheetPaths()
                   .compactMap { try file!.parseWorksheet(at: $0) }
                   .compactMap { $0.mergeCells}
               if mergedCells.count > 0 {
                   let mergedCellFirstReferences = mergedCells[0].items.map { $0.reference }
                   var tmpDictionary = [String: String]()
                   for (key,mergedCell) in mergedCellFirstReferences.enumerated(){
                       tmpDictionary[String(key)] = mergedCell.description
                       let references = mergedCell.description.components(separatedBy: ":")
                       let start_index = references[0]//AB
                       let end_index = references[1]
                       appd.diff_start_index.append(start_index)
                       appd.diff_end_index.append(end_index)
                   }
               }
               
               let sharedStrings = try file!.parseSharedStrings()
               let ws = try file!.parseWorksheet(at: path)
               appd.CELL_HEIGHT_EXCEL_GSHEET = Double(ws.formatProperties?.defaultRowHeight ?? "-1")!
               appd.CELL_WIDTH_EXCEL_GSHEET = Double(ws.formatProperties?.defaultRowHeight ?? "-1")!
               
               //Getting strings
               for i in 0..<columnName.count {
                   let k = String(columnName[i])
                   if k.count != 0 {
                       let columnCStrings = ws.cells(atColumns: [ColumnReference(k)!])
                       // in format internals "s" stands for "shared"
                           .filter { $0.type?.rawValue ?? nil == "s" }
                           .filter { $0.value != nil }
                       
                       // Rich Text
                       let temp = columnCStrings.compactMap { $0.value }.compactMap { Int($0)}.compactMap { sharedStrings!.items[$0].richText }
                       
                       // Normal Text
                       var temp2 = columnCStrings.compactMap { $0.value }.compactMap { Int($0)}.compactMap { sharedStrings!.items[$0].text }
                       
                       
                       
                       // RitchTextArray
                       var keyValues = [Int: String]()
                       for i in 0..<temp.count{
                           var strapi = ""
                           for j in 0..<temp[i].count{
                               if String(describing: temp[i][j].text).count > 0{
                                   
                                   strapi.append("\(String(describing: temp[i][j].text))")
                                   // seems working now..
                               }
                           }
                           if strapi != "" {
                               keyValues[i] = strapi
                           }
                       }
                       
                       
                       var aPlusbArray = [String](repeating: "", count:temp2.count + keyValues.count)
                       for (k,value) in keyValues {
                           aPlusbArray[k] = String(value)
                       }
                       
                       for l in 0..<aPlusbArray.count{
                           if aPlusbArray[l] == "" {
                               aPlusbArray[l] = temp2.first!
                               temp2.remove(at: 0)
                           }
                       }
                       stringContent.append(contentsOf: aPlusbArray)
                       
                       
                       stringLocation.append(contentsOf: columnCStrings.compactMap { $0.reference.description })//A2
                   }
               }
               
               var LARGIST_ROW_IN_MERGEDCELLS = 0
               
               //Getting values
               //if let formula = cell.formula?.value { returnString = formula } }
               for i in 0..<columnName.count {
                   let k = String(columnName[i])
                   if k.count != 0 {
                       let columnCStrings = ws.cells(atColumns: [ColumnReference(k)!])
                           .filter { $0.type?.rawValue ?? nil != "s"  }
                           .filter { $0.value != nil }
                       
                       var formulaCheck = [String]()
                       for i in 0..<columnCStrings.count {
                           let formulaContent = columnCStrings[i].formula?.value
                           let valueContent = columnCStrings[i].value
                           
                           if formulaContent == nil {
                               formulaCheck.append(valueContent!)
                           }else{
                               formulaCheck.append("=" + formulaContent!)
                           }
                           
                       }
                       valueContent.append(contentsOf: formulaCheck)//$0.value
                       valueLocation.append(contentsOf: columnCStrings.compactMap { $0.reference.description })
                       
                   }
               }
               
               
               let content1 = UserDefaults.standard
               //content1.set(valueContent + stringContent, forKey: "NEWTMCONTENT")
               content1.synchronize()
               
               print("content",valueContent+stringContent)
               
               var finalL_value = [String]()
               var finalL_string = [String]()
               // Needed for LocationData (3,2) (3,4) (1,3)
               let columnvalue = SortColumnName(srcAry: columnName) //AA,AB,AC
               var columnsize = GetLastColumnInt(srcAry: columnvalue)
               if columnsize < appd.DEFAULT_COLUMN_NUMBER {
                   columnsize = appd.DEFAULT_COLUMN_NUMBER
               }
               var columnsInAlphabet = [String]()
               for index in 0..<columnsize {
                   columnsInAlphabet.append(getExcelColumnName(columnNumber: index))
               }
               

               for i in 0..<valueLocation.count {
                   let columnL_value = valueLocation[i].components(separatedBy: CharacterSet.decimalDigits).joined()
               
                   let columnL = columnsInAlphabet.firstIndex(of: columnL_value)!
                   let rowL = valueLocation[i].filter("0123456789.".contains)
                   //https://stackoverflow.com/questions/36594179/remove-all-non-numeric-characters-from-a-string-in-swift
                   //colum index 0 is empty. empty, A,B,C ...
                   finalL_value.append(String(columnL) + "," + rowL)
               }
               
               for i in 0..<stringLocation.count {
                   let columnL_value = stringLocation[i].components(separatedBy: CharacterSet.decimalDigits).joined()
                   
                   let columnL = columnsInAlphabet.firstIndex(of: columnL_value)!
                   let rowL = stringLocation[i].filter("0123456789.".contains)
                   //https://stackoverflow.com/questions/36594179/remove-all-non-numeric-characters-from-a-string-in-swift
                   //colum index 0 is empty. empty, A,B,C ...
                   finalL_string.append(String(columnL) + "," + rowL)
               }
               
               
               if finalL_string.count != stringContent.count{
                   let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                   appd.wentWrong = true
                   
                   
                   
               }else if finalL_string.count == stringContent.count {
                   let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                   appd.wentWrong = false
               }
               
               
               print("location",finalL_value + finalL_string)
               
               
               
               var rowsize = GetRowSize(srcAry: valueLocation+stringLocation,fromMergedcells: LARGIST_ROW_IN_MERGEDCELLS)
               
               if rowsize < appd.DEFAULT_ROW_NUMBER{
                   rowsize = appd.DEFAULT_ROW_NUMBER
               }
               
               
               
               
               let today: Date = Date()
               let dateFormatter: DateFormatter = DateFormatter()
               dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
               let date = dateFormatter.string(from: today)
               
               
               var fontSize = [String]()
               var fontColor = [String]()
               var bgColor = [String]()
               for i in 0..<finalL_value.count+finalL_string.count{
                   fontSize.append(String(13))
                   bgColor.append("white")
                   fontColor.append("black")
               }
               
               
               let dict : [String:Any] = ["filename": "sheet" + String(wsIndex) + ".xml",
                                          "date": date,
                                          "content": valueContent+stringContent,
                                          "location": finalL_value + finalL_string,
                                          "fontsize": fontSize,
                                          "fontcolor": fontColor,
                                          "bgcolor": bgColor,
                                          "rowsize": rowsize,
                                          "columnsize": columnsize,
                                          "customcellWidth":[String](),
                                          "customcellHeight": [String](),
                                          "ccwLocation": [String](),
                                          "cchLocation": [String](),
                                          "formulaResult":[String](),
                                          "inputOrder":[String]()]
               
               
               
               let test = ReadWriteJSON()
               print("savingImportJSON")
               test.saveJsonFile(source: dict, title: "sheet" + String(wsIndex) + ".xml")
               //this library is too slow, abound it in the next version
               
               
               appd.customSizedHeight.removeAll()
               appd.customSizedWidth.removeAll()
               appd.cshLocation.removeAll()
               appd.cswLocation.removeAll()
               appd.numberofRow = rowsize
               appd.numberofColumn = columnsize
           }
               
       } catch {
           print("sorry pal cant copy it.")
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


    func getRootDocumentsDirectory() -> URL {
       let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
       return paths[0]
    }


    func SortColumnName(srcAry:[String])->[String]{
       var alphabetOnly = [String]()
       for i in 0..<srcAry.count {
           alphabetOnly.append((srcAry[i].components(separatedBy: CharacterSet.decimalDigits)).joined(separator: ""))
       }
       return uniquing(src: alphabetOnly)
    }

    func GetLastColumnInt(srcAry:[String])->Int{
       var last = 0
       for i in 0..<srcAry.count {
           if last < columnToNumber(srcAry[i])!{
               last = columnToNumber(srcAry[i])!
           }
       }
       return last
    }



    func GetRowSize(srcAry:[String],fromMergedcells:Int)->Int{
       var numberOnly = [Int]()

       for i in 0..<srcAry.count {
           numberOnly.append(Int(srcAry[i].filter("0123456789.".contains))!)
       }
       
       var maxrow = numberOnly.max()
       
       if maxrow == nil {
           maxrow = 0
       }
       
       if maxrow! < fromMergedcells{
           maxrow = fromMergedcells
       }
       
       let rowsize = UserDefaults.standard
       rowsize.set(maxrow!+2, forKey: "NEWRsize")
       rowsize.synchronize()

       
       return maxrow!+2
       
    }



    func getExcelColumnName(columnNumber: Int) -> String
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

    //https://stackoverflow.com/questions/32851720/how-to-remove-special-characters-from-string-in-swift-2
    func removeSpecialCharsFromString(text: String) -> String {
       let okayChars = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-=.!_:")
       return text.filter {okayChars.contains($0) }
    }

    func alphabetOnlyString(text: String) -> String {
       let okayChars = Set("ABCDEFGHIJKLKMNOPQRSTUVWXYZ")
       return text.filter {okayChars.contains($0) }
    }

    func numberOnlyString(text: String) -> String {
       let okayChars = Set("1234567890")
       return text.filter {okayChars.contains($0) }
    }

    func columnToNumber(_ column: String) -> Int? {
       let uppercaseColumn = column.uppercased()
       var result = 0
       for char in uppercaseColumn {
           guard let asciiValue = char.asciiValue else {
               return nil // Return nil if the character is not valid
           }
           let intValue = Int(asciiValue) - 64 // Subtracting ASCII value of 'A' (65) gives 1 for A
           if intValue < 1 || intValue > 26 {
               return nil // Return nil if the character is not in the range A-Z
           }
           result = result * 26 + intValue
       }
       return result
    }

}



