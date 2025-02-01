//
//  ExcelHelper.swift
//  HWCSV
//
//  Created by yano on 2024/12/07.
//  Copyright © 2024 Credera. All rights reserved.
//


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
    
    

    func readExcel2(path:String, wsIndex:Int){
        let excelFunctions = [
            //"SUM",
            //"AVERAGE",
            //"MIN",
            //"MAX",
            "COUNT",
            "COUNTA",
            "PRODUCT",
            "SUMIF",
            "ROUND",
            "INT",
            "CONCATENATE",
            "LEFT",
            "RIGHT",
            "MID",
            "LEN",
            "FIND",
            "SUBSTITUTE",
            "UPPER",
            "LOWER",
            "TRIM",
            "TODAY",
            "NOW",
            "DATE",
            "TIME",
            "DAY",
            "MONTH",
            "YEAR",
            "HOUR",
            "MINUTE",
            "SECOND",
            "VLOOKUP",
            "HLOOKUP",
            "INDEX",
            "MATCH",
            "OFFSET",
            "CHOOSE",
            "IF",
            "AND",
            "OR",
            "NOT",
            "IFERROR",
            "PMT",
            "FV",
            "PV",
            "RATE",
            "NPV",
            "MEDIAN",
            "MODE",
            "STDEV",
            "VAR",
            "CORREL",
            "FORECAST",
            "ISNUMBER",
            "ISERROR",
            "ISBLANK",
            "ISTEXT",
            // Information Functions
            "CELL",
            "ERROR.TYPE",
            "INFO",
            "N",
            // Lookup and Reference Functions
            "ADDRESS",
            "COLUMN",
            "ROW",
            "TRANSPOSE",
            "INDIRECT",
            // Text Functions
            "REPLACE",
            "REPT",
            "TEXT",
            "CLEAN",
            "CODE",
            // Statistical Functions
            "PERCENTILE",
            "PERCENTRANK",
            "QUARTILE",
            "RANK",
            // Mathematical Functions
            "CEILING",
            "FLOOR",
            "MOD",
            "POWER",
            "GCD",
            // Financial Functions
            "DURATION",
            "MDURATION",
            "YIELD",
            // Date and Time Functions
            "DATEDIF",
            "NETWORKDAYS",
            "WORKDAY",
            "IMPRODUCT",
            "IMSUM",
            "IMSUB",
            "IMCONJUGATE",
            "IMDIV",
            "IMARGUMENT",
            "IMABS",
            "IMRECTANGULAR",
            "COMPLEX",
            "pi",
            "e",
            "asin",
            "acos",
            "atan",
            "sin",
            "cos",
            "tan",
            "exp",
            "logb",
            "logd",
            "log",
            "abs",
            "sqrt"
        ]
       //TODO NOT WORKING SHOULD I REPLACE WHOLE JSON FILES?
       do {
           let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
           let file = XLSXFile(filepath: path)
           appd.sheetNameIds = [String]()
           appd.sheetNames = [String]()
           appd.diff_start_index.removeAll()
           appd.diff_end_index.removeAll()
           appd.excelStyleIdx.removeAll()
           appd.excelStyleLocation.removeAll()
           appd.excelStyleLocationAlphabet.removeAll()
           appd.cellXfs.removeAll()
           appd.cellStyleXfs.removeAll()
           appd.border_lefts.removeAll()
           appd.border_rights.removeAll()
           appd.border_bottoms.removeAll()
           appd.border_tops.removeAll()
           appd.formatCodes.removeAll()
           appd.numFmts.removeAll()
           appd.numFmtIds.removeAll()
           
           
           //get all worksheets
           if let workbook = try file?.parseWorkbooks().first {
               // Extracting non-nil sheet IDs using compactMap
               let sheetNameIds = workbook.sheets.items.compactMap { $0.id }
               print("Sheet Name IDs:", sheetNameIds)
               appd.sheetNameIds = sheetNameIds
               let sheetNames = workbook.sheets.items.compactMap { $0.name }
               print("Sheet Names:", sheetNames)
               appd.sheetNames = sheetNames
           }
           
           //appd.ws_total_pages = sheetsNumber
           //only show first page.
           //for path in try file!.parseWorksheetPaths() {
           let paths = try file!.parseWorksheetPaths()
           // Filter files with "sheet1.xml" in their file name
           var sheet1Files = paths.filter { $0.hasSuffix("sheet" + String(wsIndex) + ".xml") }
           if sheet1Files == nil{
               let reIdx = appd.sheetNameIds.firstIndex(of: String(wsIndex))
               sheet1Files = paths.filter { $0.hasSuffix("sheet" + String(reIdx ?? 0) + ".xml") }
           }
           if let path = try sheet1Files.first {
               print("path",path)
               //Cleaning instances on table data
               columnName = []
               stringLocation = []
               stringContent = []
               valueLocation = []
               valueContent = []
               
               let container = try file!.parseWorksheet(at: path).data?.rows.flatMap { $0.cells } ?? []
               columnName = uniquing(src:container.map { $0.reference.column.value })//AA AS AW E
               
               
               //mergedcells initialization
               let mergedCells = try file?.parseWorksheet(at: path).mergeCells
               if mergedCells?.items.first != nil {
                   let mergedCellFirstReferences = mergedCells!.items.map { $0.reference }
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
                   //you need to update sharedstring count and use count or it throws out of index error
                   let k = String(columnName[i])
                   if k.count != 0 {
                       let columnCStrings = ws.cells(atColumns: [ColumnReference(k)!])
                       // in format internals "s" stands for "shared"
                           .filter { $0.type?.rawValue ?? nil == "s" }
                           .filter { $0.value != nil }
                       
                       // Rich Text
                       let temp = columnCStrings.compactMap { $0.value }.compactMap { Int($0)}.compactMap { sharedStrings?.items[$0].richText }
                       
                       // Normal Text
                       var temp2 = [String]()
                       if (sharedStrings != nil){
                           temp2 = columnCStrings.compactMap { $0.value }.compactMap { Int($0)}.compactMap { sharedStrings!.items[$0].text }
                       }
                       
                       
                       
                       // RitchTextArray
                       var keyValues = [Int: String]()
                       for i in 0..<temp.count{
                           var strapi = ""
                           for j in 0..<temp[i].count{
                               if String(describing: temp[i][j].text).count > 0{
                                   
                                   strapi.append("\(String(temp[i][j].text ?? ""))")
                                   // seems working now..
                               }
                           }
                           if strapi != "" {
                               keyValues[i] = strapi
                           }
                       }
                       
                       //get style
                       let allCells = ws.cells(atColumns: [ColumnReference(k)!])
                       for l in 0..<allCells.count {
                           //get styleindex
                           let styleIdx = allCells[l].styleIndex ?? -1
                           let locationIdx =   String(allCells[l].reference.row) + "," + String(columnToInt(allCells[l].reference.column.value)!)
                           //let locationIdx = String(columnToInt(columnCStrings[l].reference.column.value)!) + "," + String(columnCStrings[l].reference.row)
                           
                           appd.excelStyleIdx.append(styleIdx)
                           appd.excelStyleLocation.append(locationIdx)
                           appd.excelStyleLocationAlphabet.append(allCells[l].reference.description)
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
                               let containsItem = excelFunctions.contains { formulaContent! == $0 }
                               if !containsItem{
                                   formulaCheck.append("=" + formulaContent!)
                               }
                               
                               if containsItem{
                                   //TODO
                                   formulaCheck.append(valueContent!)
                               }
                           }
                           
                       }
                       valueContent.append(contentsOf: formulaCheck)//$0.value
                       valueLocation.append(contentsOf: columnCStrings.compactMap { $0.reference.description })
                       
                   }
               }
               
               
               let content1 = UserDefaults.standard
               //content1.set(valueContent + stringContent, forKey: "NEWTMCONTENT")
               content1.synchronize()
               
               //heavy
               //print("content",valueContent+stringContent)
               
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
                   columnsInAlphabet.append(GetExcelColumnName(columnNumber: index))
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

               var rowsize = GetRowSize(srcAry: valueLocation+stringLocation,fromMergedcells: appd.diff_end_index)
 
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
                                          "columnsize": columnsize+1,
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
           print(error)
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
       return last + 1 //consider cell 0,0
    }



    func GetRowSize(srcAry:[String],fromMergedcells:[String])->Int{
        var numberOnly = [Int]()
    
        for i in 0..<srcAry.count {
            numberOnly.append(Int(srcAry[i].filter("0123456789.".contains))!)
        }
        
        for i in 0..<fromMergedcells.count {
            numberOnly.append(Int(fromMergedcells[i].filter("0123456789.".contains))!)
        }
        
        var maxrow = numberOnly.max()
        
        if maxrow == nil {
            maxrow = 0
        }
        
        let rowsize = UserDefaults.standard
        rowsize.set(maxrow!+10, forKey: "NEWRsize")
        rowsize.synchronize()
   
        
        return maxrow!+10
        
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
    
    func columnToInt(_ column: String) -> Int? {
        // Convert the string to uppercase to handle lowercase inputs
        let uppercasedColumn = column.uppercased()
        
        // Calculate the integer value by subtracting the unicode value of "A" and adding 1
        guard let unicodeScalar = uppercasedColumn.unicodeScalars.first
              else {
            return nil
        }
        
        let asciiValue = unicodeScalar.value
        
        // Check if the character is within the range of A-Z
        guard asciiValue >= 65 && asciiValue <= 90 else {
            return nil
        }
        
        // Return the integer value (A=1, B=2, ..., Z=26)
        return Int(asciiValue - 64)
    }
    
    func excel_sum(src:String,cursor:String,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        //merge2array
        let jc = fc + lc
        let jl = fl + ll
        let jle = fle + lle
        let jr = fr + lr
        
        //SUM(A12:D50)
        let rangeString = src.replacingOccurrences(of: "SUM(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "=", with: "")
        
        let rangeComponents = rangeString.split(separator: ":")
        guard rangeComponents.count == 2 else {
            return "error"
        }
        
        let startCell = String(rangeComponents[0])
        let endCell = String(rangeComponents[1])
        
        //check if cursor inside the range first
        if isCellInsideRange(cell: cursor, startCell: startCell, endCell: endCell) {
            //print("\(cursor) is inside the range col,row")
            return "error"
        }
        
        if isRangeSyntaxError(cell: cursor, startCell: startCell, endCell: endCell) {
            print("invalid inputs")
            return "error"
        }
        
        var sum = 0.0
        var cnt = 0
        for (i, cell) in jl.enumerated() {
            let colnumber = cell.components(separatedBy: ",")[0]
            let rownumber = cell.components(separatedBy: ",")[1]
            let colintnumber = Int(colnumber)
            let letters = GetExcelColumnName(columnNumber: colintnumber!)
            if isCellInsideRange(cell: cell, startCell: startCell, endCell: endCell) {
                let index = "\(letters)" + rownumber
                //print("\(index) is inside the range col,row")
                if jr[i] == "error"{
                    return "error"
                }
                if Double(jr[i]) != nil{
                    sum += Double(jr[i])!
                    cnt += 1
                }
            } else {
                //print("\(cell) is outside the range col,row")
            }
        }
        
        if cnt == 0{
            return "error"
        }
        
        return String(sum)
        
    }
    
    func excel_average(src:String,cursor:String,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        //merge2array
        let jc = fc + lc
        let jl = fl + ll
        let jle = fle + lle
        let jr = fr + lr
        
        //SUM(A12:D50)
        let rangeString = src.replacingOccurrences(of: "AVERAGE(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "=", with: "")
        
        let rangeComponents = rangeString.split(separator: ":")
        guard rangeComponents.count == 2 else {
            return "error"
        }
        
        let startCell = String(rangeComponents[0])
        let endCell = String(rangeComponents[1])
        
        //check if cursor inside the range first
        if isCellInsideRange(cell: cursor, startCell: startCell, endCell: endCell) {
            //print("\(cursor) is inside the range col,row")
            return "error"
        }
        
        if isRangeSyntaxError(cell: cursor, startCell: startCell, endCell: endCell) {
            print("invalid inputs")
            return "error"
        }
        
        var sum = 0.0
        var cnt = 0
        var avg = 0.0
        for (i, cell) in jl.enumerated() {
            let colnumber = cell.components(separatedBy: ",")[0]
            let rownumber = cell.components(separatedBy: ",")[1]
            let colintnumber = Int(colnumber)
            let letters = GetExcelColumnName(columnNumber: colintnumber!)
            if isCellInsideRange(cell: cell, startCell: startCell, endCell: endCell) {
                let index = "\(letters)" + rownumber
                //print("\(index) is inside the range col,row")
                if jr[i] == "error"{
                    return "error"
                }
                if Double(jr[i]) != nil{
                    sum += Double(jr[i])!
                    cnt += 1
                    avg = sum/Double(cnt)
                    let numberOfPlaces = 5.0
                    let multiplier = pow(10.0, numberOfPlaces)
                    var calculated = avg * multiplier
                    calculated = round(calculated) / multiplier
                    avg = calculated
                }
            } else {
                //print("\(cell) is outside the range col,row")
            }
        }
        
        if cnt == 0{
            return "error"
        }
        
        return String(avg)
        
    }
    
    func excel_min(src:String,cursor:String,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        //merge2array
        let jc = fc + lc
        let jl = fl + ll
        let jle = fle + lle
        let jr = fr + lr
        
        //SUM(A12:D50)
        let rangeString = src.replacingOccurrences(of: "MIN(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "=", with: "")
        
        let rangeComponents = rangeString.split(separator: ":")
        guard rangeComponents.count == 2 else {
            return "error"
        }
        
        let startCell = String(rangeComponents[0])
        let endCell = String(rangeComponents[1])
        
        //check if cursor inside the range first
        if isCellInsideRange(cell: cursor, startCell: startCell, endCell: endCell) {
            //print("\(cursor) is inside the range col,row")
            return "error"
        }
        
        if isRangeSyntaxError(cell: cursor, startCell: startCell, endCell: endCell) {
            print("invalid inputs")
            return "error"
        }
        
        var items = [Double]()
        for (i, cell) in jl.enumerated() {
            let colnumber = cell.components(separatedBy: ",")[0]
            let rownumber = cell.components(separatedBy: ",")[1]
            let colintnumber = Int(colnumber)
            let letters = GetExcelColumnName(columnNumber: colintnumber!)
            if isCellInsideRange(cell: cell, startCell: startCell, endCell: endCell) {
                let index = "\(letters)" + rownumber
                //print("\(index) is inside the range col,row")
                if jr[i] == "error"{
                    return "error"
                }
                if Double(jr[i]) != nil{
                    items.append(Double(jr[i])!)
                    items.sort()//0.0,1.41,12.7
                }
            } else {
                //print("\(cell) is outside the range col,row")
            }
        }
        
        
        if let firstItem = items.first {
            return String(firstItem) // Correctly converts the Double to a String
        }
        
        return "error"
    }
    
    func excel_max(src:String,cursor:String,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        //merge2array
        let jc = fc + lc
        let jl = fl + ll
        let jle = fle + lle
        let jr = fr + lr
        
        //SUM(A12:D50)
        let rangeString = src.replacingOccurrences(of: "MAX(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "=", with: "")
        
        let rangeComponents = rangeString.split(separator: ":")
        guard rangeComponents.count == 2 else {
            return "error"
        }
        
        let startCell = String(rangeComponents[0])
        let endCell = String(rangeComponents[1])
        
        //check if cursor inside the range first
        if isCellInsideRange(cell: cursor, startCell: startCell, endCell: endCell) {
            //print("\(cursor) is inside the range col,row")
            return "error"
        }
        
        if isRangeSyntaxError(cell: cursor, startCell: startCell, endCell: endCell) {
            print("invalid inputs")
            return "error"
        }
        
        var items = [Double]()
        for (i, cell) in jl.enumerated() {
            let colnumber = cell.components(separatedBy: ",")[0]
            let rownumber = cell.components(separatedBy: ",")[1]
            let colintnumber = Int(colnumber)
            let letters = GetExcelColumnName(columnNumber: colintnumber!)
            if isCellInsideRange(cell: cell, startCell: startCell, endCell: endCell) {
                let index = "\(letters)" + rownumber
                //print("\(index) is inside the range col,row")
                if jr[i] == "error"{
                    return "error"
                }
                if Double(jr[i]) != nil{
                    items.append(Double(jr[i])!)
                    items.sort()//0.0,1.41,12.7
                }
            } else {
                //print("\(cell) is outside the range col,row")
            }
        }
        
        
        if let lastItem = items.last {
            return String(lastItem) // Correctly converts the Double to a String
        }
        
        return "error"
    }
        
    // Function to check if a cell is inside a range
    func isCellInsideRange(cell: String, startCell: String, endCell: String) -> Bool {
        // Parse the input cell (e.g., "1,2" -> row = 1, column = 2)
        let cellComponents = cell.split(separator: ",")
        guard cellComponents.count == 2,
              let cellRow = Int(cellComponents[1]),
              let cellColumn = Int(cellComponents[0]) else {
            return false
        }
            
        // Parse the start and end cells
        let startColumnInt = ExcelHelper().columnToInt(ExcelHelper().alphabetOnlyString(text: startCell)) ?? 0
        let startRowInt = Int(ExcelHelper().numberOnlyString(text: startCell)) ?? 0
        let endColumnInt = ExcelHelper().columnToInt(ExcelHelper().alphabetOnlyString(text: endCell)) ?? 0
        let endRowInt = Int(ExcelHelper().numberOnlyString(text: endCell)) ?? 0

        print(startColumnInt,startRowInt)
        print(endColumnInt,endRowInt)
        // Check if the cell is within the range
        return (cellColumn >= (startColumnInt) && cellColumn <= (endColumnInt)) && (cellRow >= (startRowInt) && cellRow <= (endRowInt))
        
    }
    
    // Function to check if a cell is inside a range
    func isRangeSyntaxError(cell: String, startCell: String, endCell: String) -> Bool {
        // Parse the start and end cells
        let startColumnInt = ExcelHelper().columnToInt(ExcelHelper().alphabetOnlyString(text: startCell)) ?? 0
        let startRowInt = Int(ExcelHelper().numberOnlyString(text: startCell)) ?? 0
        let endColumnInt = ExcelHelper().columnToInt(ExcelHelper().alphabetOnlyString(text: endCell)) ?? 0
        let endRowInt = Int(ExcelHelper().numberOnlyString(text: endCell)) ?? 0

        print(startColumnInt,startRowInt)
        print(endColumnInt,endRowInt)
        // Check if the cell is within the range
        if (startColumnInt > endColumnInt || startRowInt > endRowInt){
            return true
        }
        if (startColumnInt == 0 || startRowInt == 0){
            return true
        }
        
        
        return false
    }

}




