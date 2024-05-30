//
//  ViewController4.swift
//  dictionary
//
//  Created by 矢野悠人 on 2017/06/22.
//  Copyright © 2017年 yumiya. All rights reserved.
//

import UIKit
import CoreXLSX
import Foundation
//import GoogleAPIClientForREST
//import GoogleSignIn
import SwiftyXMLParser


class iCloudViewController: UIViewController,UIDocumentMenuDelegate,UIDocumentPickerDelegate,UINavigationControllerDelegate,FileManagerDelegate{
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
//    let driveService  = GTLRDriveService()
//    func downloadFile(file: GTLRDrive_File){
//        let url = "https://www.googleapis.com/drive/v3/files/\(file.identifier!)?alt=media"
//
//        let fetcher = driveService.fetcherService.fetcher(withURLString: url)

//   dont need it     fetcher.beginFetchWithDelegate(
//            self,
//            didFinishSelector: #selector(ViewController.finishedFileDownload(_:finishedWithData:error:)))
//    }
    
    
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
    
    var test = true
    
    @IBOutlet weak var aci: UIActivityIndicatorView!
    //var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        super.viewDidLoad()
        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: false)
        appd.ws_path = ""
        appd.wsIndex = 1
        appd.imported_xlsx_file_path=""
        // Do any additional setup after loading the view.
        startLoading()
    }
    
    func startLoading() {
           // Start animating the activity indicator
           aci.startAnimating()
           
           // Optionally, disable user interaction to prevent interaction during loading
           view.isUserInteractionEnabled = false
       }

       func stopLoading() {
           // Stop animating the activity indicator
           aci.stopAnimating()
           
           // Re-enable user interaction
           view.isUserInteractionEnabled = true
       }
    
    
    //https://qiita.com/KikurageChan/items/5b33f95cbec9e0d8a05f
    @objc func timerUpdate() {
        print("update")
        
        let source = ["public.data"]//["public.comma-separated-values-text"]
        let documentPicker = UIDocumentPickerViewController(documentTypes: source, in: UIDocumentPickerMode.import)//Import
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
            print("this is url")
            print(url)
            print(url.absoluteString)
            //g.sheet 未対応
            //csvPath = url.absoluteString
            //http://stackoverflow.com/questions/28641325/using-uidocumentpickerviewcontroller-to-import-text-in-swift
            //http://qiita.com/nwatabou/items/898bc4395adbb2e05f8d
            //http://stackoverflow.com/questions/32263893/cast-nsstringcontentsofurl-to-string
            //http://qiita.com/nwatabou/items/898bc4395adbb2e05f8d
            //http://miyano-harikyu.jp/sola/devlog/2013/11/22/post-113/
            //https://developer.apple.com/reference/foundation/nsfilemanager
            //
            
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.CELL_HEIGHT_EXCEL_GSHEET = -1.0
            appd.CELL_WIDTH_EXCEL_GSHEET = -1.0
            
            var isExcel = false
            
            //
            if url.absoluteString.contains(".csv"){
                
            let fnameArry = url.absoluteString.split(separator: "/")
            let fnameA = fnameArry.last!.split(separator: ".")
            excelName = String(fnameA.first!) + "." + String(fnameA.last!)
            let mydata = try! Data(contentsOf: url)
            let str = swiftDataToString(someData: mydata)
            var elementArray = str?.components(separatedBy: "\n")
                var rowcount:Int = elementArray!.count
            
            for i in 0..<rowcount {

                if (elementArray![i].contains("\r")){
                    elementArray![i] = elementArray![i].replacingOccurrences(of: "\r", with: "")
                    elementArray![i] = elementArray![i].replacingOccurrences(of: "\n", with: "")
                }
            }

            //
            location.removeAll()
            contents.removeAll()
            //
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
            
            //Let's start
            var columncount = 0
            for r in 0..<rowcount//the number of rows
            {
                let wordsArray: [String] = elementArray![r].components(separatedBy: ",")
                
                if columncount < wordsArray.count {
                    columncount = wordsArray.count
                }
                
                if wordsArray.count < columncount{
                    
                }
                else
                {
                    for c in 0..<columncount
                    {
                        if wordsArray[c] == "" || wordsArray[c] == " "
                        {
                            
                        }
                        else
                        {
                            let targetlocation:String = String(c+1) + "," + String(r+1)//Something is wrong.. String(i+1) + "," + String(j+1)
                            
                            location.append(targetlocation)
                            contents.append(wordsArray[c])
                        }
                    }
                }
            }
                
            if columncount < appd.DEFAULT_COLUMN_NUMBER {
                columncount = appd.DEFAULT_COLUMN_NUMBER
            }
            
            if rowcount < appd.DEFAULT_ROW_NUMBER {
                rowcount = appd.DEFAULT_ROW_NUMBER
            }

            let csvData = UserDefaults.standard
            csvData.set(location, forKey: "NEWTMLOCATION")
            csvData.set(contents, forKey: "NEWTMCONTENT")
            csvData.set(rowcount, forKey: "NEWRsize")
            csvData.set(columncount, forKey: "NEWCsize")
            csvData.synchronize()

           let today: Date = Date()
           let dateFormatter: DateFormatter = DateFormatter()
           dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
           let date = dateFormatter.string(from: today)
           var fontSize = [String]()
           var fontColor = [String]()
           var bgColor = [String]()
           for i in 0..<location.count{
               fontSize.append(String(13))
               bgColor.append("white")
               fontColor.append("black")
           }
 
            let dict : [String:Any] = ["filename": "csv_sheet1",
                                  "date": date,
                                  "content": contents,
                                  "location": location,
                                  "fontsize": fontSize,
                                  "fontcolor": fontColor,
                                  "bgcolor": bgColor,
                                  "rowsize": rowcount,
                                  "columnsize": columncount,
                                  "customcellWidth":[String](),
                                  "customcellHeight": [String](),
                                  "ccwLocation": [String](),
                                  "cchLocation": [String](),
                                  "formulaResult":[String](),
                                  "inputOrder":[String]()]

       

            let test = ReadWriteJSON()
            print("savingImportJSON CSV")
            test.saveuserAll()
            test.saveJsonFile(source: dict, title: "csv_sheet1")
            appd.customSizedHeight.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.cswLocation.removeAll()
            appd.numberofRow = rowcount+1
            appd.numberofColumn = columncount+1
            isExcel = false
            print("end iCloudController")
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController//Landscape
            targetViewController.isExcel = isExcel
            targetViewController.sheetIdx = 1
            targetViewController.modalPresentationStyle = .fullScreen
            DispatchQueue.main.async {
                self.present(targetViewController, animated: true, completion: nil)
            }
            
            
            return
            
        }
        
        if url.absoluteString.contains(".xlsx"){
            
            //excel process
            print("excel file")
            let fnameArry = url.absoluteString.split(separator: "/")
            let pathDirectory = getRootDocumentsDirectory()
            try? FileManager().createDirectory(at: pathDirectory, withIntermediateDirectories: true)
            let filePath = pathDirectory.appendingPathComponent(String(fnameArry.last!))
            let fnameA = fnameArry.last!.split(separator: ".")
            excelName = String(fnameA.first!) + "." + String(fnameA.last!)
            if FileManager.default.fileExists(atPath: filePath.path) {
                do{
                    print("remove file")
                    try FileManager.default.removeItem(at: filePath)
                    
                }catch {
                    print("new to this app")
                }
            }
            
            do{
                print("move file", filePath)
                try FileManager.default.moveItem(at: url, to: filePath)
            }catch let error{
                //dump(error)
            }
            
            let path2 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let url2 = URL(fileURLWithPath: path2)
            let filename = String(fnameArry.last!)
            let fp = url2.appendingPathComponent(filename).path
            print("yourExcelfile",fp)
            appd.imported_xlsx_file_path=fp
            readExcel(path: fp)
            isExcel = true
            
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let url = serviceInstance.testSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
            //createxlsxSheet()
            
        
        print("end iCloudController")
        
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController//Landscape
        targetViewController.isExcel = isExcel
        targetViewController.sheetIdx = 1
        targetViewController.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
            return
        }
            
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController//Landscape
        targetViewController.isExcel = isExcel
        targetViewController.sheetIdx = 1
        targetViewController.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        
        
    }
    
    func loadInitialXLSX(url: URL) {
            print("this is url")
            print(url)
            print(url.absoluteString)
            //g.sheet 未対応
            //csvPath = url.absoluteString
            //http://stackoverflow.com/questions/28641325/using-uidocumentpickerviewcontroller-to-import-text-in-swift
            //http://qiita.com/nwatabou/items/898bc4395adbb2e05f8d
            //http://stackoverflow.com/questions/32263893/cast-nsstringcontentsofurl-to-string
            //http://qiita.com/nwatabou/items/898bc4395adbb2e05f8d
            //http://miyano-harikyu.jp/sola/devlog/2013/11/22/post-113/
            //https://developer.apple.com/reference/foundation/nsfilemanager
            //
            
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.CELL_HEIGHT_EXCEL_GSHEET = -1.0
            appd.CELL_WIDTH_EXCEL_GSHEET = -1.0
            
            var isExcel = false
        
        if url.absoluteString.contains(".xlsx"){
            //excel process
            print("excel file")
            let fnameArry = url.absoluteString.split(separator: "/")
            let pathDirectory = getRootDocumentsDirectory()
            try? FileManager().createDirectory(at: pathDirectory, withIntermediateDirectories: true)
            let filePath = pathDirectory.appendingPathComponent(String(fnameArry.last!))
            let fnameA = fnameArry.last!.split(separator: ".")
            excelName = String(fnameA.first!) + "." + String(fnameA.last!)
            if FileManager.default.fileExists(atPath: filePath.path) {
                do{
                    print("remove file")
                    try FileManager.default.removeItem(at: filePath)
                    
                }catch {
                    print("new to this app")
                }
            }
            
            do{
                print("copy file", filePath)
                try FileManager.default.copyItem(at: url, to: filePath)
            }catch let error{
                //dump(error)
            }
            
            let path2 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let url2 = URL(fileURLWithPath: path2)
            let filename = String(fnameArry.last!)
            let fp = url2.appendingPathComponent(filename).path
            if FileManager.default.fileExists(atPath: fp) {
                print("yourExcelfile",fp)
            }
            appd.imported_xlsx_file_path=fp
            readExcel(path: fp)
            isExcel = true
            
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let url = serviceInstance.testSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
            print("end iCloudController")
        }
        return
    }
    
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        //dismiss(animated: true, completion: nil)
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.imported_xlsx_file_path = ""
        appd.sheetNameIds = [String]()
        appd.sheetNames = [String]()
        appd.diff_start_index.removeAll()
        appd.diff_end_index.removeAll()
        appd.ws_path = ""
        appd.wsIndex = 1
        appd.isAppStarted = false
        
        let sheet1Json = ReadWriteJSON()
        sheet1Json.deleteJsonFile(title: "csv_sheet1")
        
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "LoadingViewController" )
        targetViewController.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        
        
    }
    
    
    
    
    //https://stackoverflow.com/questions/44160111/what-is-the-equivalent-of-string-encoding-utf8-rawvalue-in-objective-c
    func swiftDataToString(someData:Data) -> String? {
        return String(data: someData, encoding: .utf8)
    }
    
    func swiftStringToData(someStr:String) ->Data? {
        return someStr.data(using: .utf8)
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    func readExcel(path:String, wsIndex:Int = 1){
        let excelFunctions = [
            "SUM",
            "AVERAGE",
            "MIN",
            "MAX",
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
            "AVERAGE",
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
            "WORKDAY"
        ]
        //TODO NOT WORKING SHOULD I REPLACE WHOLE JSON FILES?
        do {
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.ws_path = path
            appd.wsIndex = wsIndex
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
            let paths = try file?.parseWorksheetPaths()
            // Filter files with "sheet1.xml" in their file name
            let sheet1Files = paths?.filter { $0.hasSuffix("sheet1.xml") }
            if let path = try sheet1Files?.first {
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
                                //normal values
                                formulaCheck.append(valueContent!)
                            }else{
                                let containsItem = excelFunctions.contains { formulaContent!.contains($0) }
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
                        valueLocation.append(contentsOf: columnCStrings.map { $0.reference.description })
                        
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
                for index in 0...columnsize {
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
                
                
                let dict : [String:Any] = ["filename": "sheet1.xml",
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
                test.saveJsonFile(source: dict, title: "sheet1.xml")
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
        
//        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
//        if appd.DEFAULT_ROW_NUMBER > maxrow + 10{
//
//        }
        let rowsize = UserDefaults.standard
        rowsize.set(maxrow!+10, forKey: "NEWRsize")
        rowsize.synchronize()
   
        
        return maxrow!+10
        
    }
    
    // Rest in peace..
    func CsvSave(FILENAME:String, ROWSIZE:Int, COLUMNSIZE:Int, content:[String], location:[String],counter:Int)
    {
       
        //http://stackoverflow.com/questions/32593516/how-do-i-exactly-export-a-csv-file-from-ios-written-in-swift
        let mailString = NSMutableString()
        
        for i in (1..<ROWSIZE)
        {
            for j in (1..<COLUMNSIZE)
            {
                let PATH :String =  String(j) + "," + String(i)//String(i) + "," + String(j)
                
                 if location.contains(PATH){
                    let k = location.index(of: PATH)
                    
                    
                    if content[k!].contains(","){
                        mailString.append(content[k!].replacingOccurrences(of: ",", with: "#comma#"))
                    }else if content[k!].contains("\n"){
                        
                    }else{
                        
                        mailString.append(content[k!])
                        
                    }
                    
                }
                else{
                    
                    mailString.append(" ")
                    
                }
                
                if j == COLUMNSIZE-1 {
                    //last element
                }else{
                    mailString.append(",")
                }
            }
            
            mailString.append("\n")

        }
        
        var data: Data? = nil
        data = mailString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        {
            let fileURL = dir.appendingPathComponent(excelName)
            
            do
            {
                //https://stackoverflow.com/questions/45993238/permission-denied-when-trying-to-create-a-directory-in-application-support
                try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true, attributes: nil)

            }
            catch let error as NSError
            {
                print("Unable to create directory \(error.debugDescription)")
            }
            
            
            
            //writing
            let path = excelName + "/" + FILENAME + ".csv"
            let s = dir.appendingPathComponent(path)
            
            do{
                
                try FileManager.default.removeItem(at: s)
                print("hey I'm taking your place from now.")
                
                
            }catch{
                print("new to this app")
                
            }
            
            
            do {
                try data!.write(to: s)

                do {
                    let fileURLs = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)
                    
                } catch {
                    print("Error while enumerating files")
                }
                
            }
            catch {print("Writing File Error")}
        }
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
}



