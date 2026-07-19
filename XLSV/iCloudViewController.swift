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

    // Set by the presenting controller before this view loads (FileFillViewController
    // sets this to true in its icloudview(_:)). Determines both which local file the
    // imported xlsx lands at (replaceLocalFileWithImportedOne) and which controller
    // documentPicker(_:didPickDocumentAt:) returns to afterward, so an import
    // triggered from FF mode never ends up overwriting/showing in ViewController.
    var isFileFillMode = false

    @IBOutlet weak var aci: UIActivityIndicatorView!
    //var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        super.viewDidLoad()
        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: false)
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
        let bkupFolder = ExcelHelper().getBackupDirectory()
        print("backup",bkupFolder)
        //https://www.hackingwithswift.com/example-code/system/how-to-read-the-contents-of-a-directory-using-filemanager
//            let fm = FileManager.default
//            let path = Bundle.main.resourcePath!
//
//            do {
//                let items = try fm.contentsOfDirectory(atPath: path)
//
//                for item in items {
//                    print("Found \(item)")
//                }
//            } catch {
//                // failed to read directory – bad permissions, perhaps?
//            }
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
        if url.absoluteString.hasSuffix(".csv"){
            //temporary susupend feature
            let targetViewController: UIViewController
            if isFileFillMode {
                let ffViewController = self.storyboard!.instantiateViewController( withIdentifier: "Filefill" ) as! FileFillViewController
                ffViewController.isExcel = true
                ffViewController.isCSV = false
                targetViewController = ffViewController
            } else {
                let vc = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController
                vc.isExcel = true
                vc.isCSV = false
                targetViewController = vc
            }
            targetViewController.modalPresentationStyle = .fullScreen
            DispatchQueue.main.async {
                //just return and start with an initial xlsx file
                self.present(targetViewController, animated: true, completion: nil)
            }
            return
        }
        
        if url.absoluteString.hasSuffix(".xlsx"){
                
            //excel process
            print("excel file")
            let pathDirectory = getRootDocumentsDirectory()
            
                        let fm = FileManager.default
                        let path = Bundle.main.resourcePath!
            
                        do {
                            let items = try fm.contentsOfDirectory(atPath: pathDirectory.path)
            
                            for item in items {
                                print("Found \(item)")
                            }
                        } catch {
                            // failed to read directory – bad permissions, perhaps?
                        }
            
            try? FileManager().createDirectory(at: pathDirectory, withIntermediateDirectories: true)
            let lastComponent = url.lastPathComponent
            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
            let extensionPart = url.pathExtension
            excelName = "\(nameWithoutExtension).\(extensionPart)"
            let fnameArry = url.absoluteString.split(separator: "/")
            let filePath = pathDirectory.appendingPathComponent(String(fnameArry.last!))
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
            appd.excelfilename = excelName
            readExcel(path: fp)
            isExcel = true
            
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let url = serviceInstance.testSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
            
            
            replaceLocalFileWithImportedOne()

            print("end iCloudController")

            // Return to whichever controller triggered this import -- FileFillViewController
            // set isFileFillMode before presenting; otherwise this came from ViewController's
            // own "Local Load" and must land back there, not in FF mode.
            let rootViewController: UIViewController
            if isFileFillMode {
                let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "Filefill" ) as! FileFillViewController
                targetViewController.isExcel = isExcel
                rootViewController = targetViewController
            } else {
                let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController
                targetViewController.isExcel = isExcel
                rootViewController = targetViewController
            }
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
               let window = appDelegate.window {

                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = rootViewController
                }, completion: nil)

                window.makeKeyAndVisible()
            }
            return
        }
                
        // Unsupported file type -- no import happened, just return to whichever
        // controller triggered the picker.
        let targetViewController: UIViewController
        if isFileFillMode {
            let ffViewController = self.storyboard!.instantiateViewController( withIdentifier: "Filefill" ) as! FileFillViewController
            ffViewController.isExcel = true
            ffViewController.isCSV = false
            targetViewController = ffViewController
        } else {
            let vc = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController
            vc.isExcel = true
            vc.isCSV = false
            targetViewController = vc
        }
        targetViewController.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
    }
    
    func replaceLocalFileWithImportedOne() {
        let appd = UIApplication.shared.delegate as! AppDelegate
        let pathDirectory = getRootDocumentsDirectory()
        // FF-mode imports land at their own dedicated file, never ViewController's
        // initialXLSX.xlsx -- see isFileFillMode above.
        let destinationFileName = isFileFillMode ? "initialXLSX_ff.xlsx" : "initialXLSX.xlsx"
        let destinationfilePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent(destinationFileName)
        
        let currentfilePath = URL(fileURLWithPath: appd.imported_xlsx_file_path)
        

        let backupDir = ExcelHelper().getBackupDirectory()
        let isFromBackup = backupDir.map { currentfilePath.path.contains($0.path) } ?? false

        do {
            let fileManager = FileManager.default
            
            if isFromBackup {
                //clean up before copy
                if fileManager.fileExists(atPath: destinationfilePath.path) {
                    try fileManager.removeItem(at: destinationfilePath)
                }
                //keep the original with copyItem
                try fileManager.copyItem(at: currentfilePath, to: destinationfilePath)
                print("Restore: Copied from backup to local.")
            } else {
                //original currentfile dies, survie at destinationfile path
                try fileManager.replaceItemAt(destinationfilePath, withItemAt: currentfilePath)
                print("Import: Replaced local file and removed temp.")
            }
            
            appd.imported_xlsx_file_path = destinationfilePath.path
        } catch {
            print("Error during file replacement: \(error.localizedDescription)")
        }
    }

    
    func loadInitialXLSX(url: URL) {
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
            let filePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent(String(fnameArry.last!))
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
                let destinationDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("importedExcel")
                    let destinationURL = destinationDirectory.appendingPathComponent("initialXLSX.xlsx")
                    
                    // Ensure the destination directory exists
                    try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
                        
                if FileManager.default.fileExists(atPath: url.path) {
                    print("file exist at the url",url.path)
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                }
            }catch let error{
                //dump(error)
                print(error)
            }
            
            let path2 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let url2 = URL(fileURLWithPath: path2)
            let filename = String(fnameArry.last!)
            let fp = url2.appendingPathComponent("importedExcel").appendingPathComponent(filename).path
            if FileManager.default.fileExists(atPath: fp) {
                print("copied yourExcelfile",fp)
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
    
    func getExcelSheetNamesAndIds(path:String,wsIndex:Int = 1){
        do{
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let file = XLSXFile(filepath: path)
            //get all worksheets
            if let workbook = try file?.parseWorkbooks().first {
                // Extracting non-nil sheet IDs using compactMap. This is where sheetNameIds retrieved
                let sheetNameIds = workbook.sheets.items.compactMap { $0.id }
                print("Sheet Name IDs:", sheetNameIds)
                appd.sheetNameIds = sheetNameIds
                let sheetNames = workbook.sheets.items.compactMap { $0.name }
                print("Sheet Names:", sheetNames)
                appd.sheetNames = sheetNames
            }
        }catch {
            print("sorry pal cant copy it.")
        }
    }
    
    func readExcel(path:String, wsIndex:Int = 1){
        let excelFunctionsNotSupportedInXLSV = [
//            "SUM",
//            "AVERAGE",
//            "MIN",
//            "MAX",
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
//            "pi",
//            "e",
//            "asin",
//            "acos",
//            "atan",
//            "sin",
//            "cos",
//            "tan",
//            "exp",
//            "logb",
//            "logd",
//            "log",
//            "abs",
//            "sqrt",
//            "PI()",
//            "EXP(1)",
//            "ASIN",
//            "ACOS",
//            "ATAN",
//            "SIN",
//            "COS",
//            "TAN",
//            "EXP",
//            "LOG",
//            "LOG10",
//            "LN",
//            "ABS",
//            "SQRT"
        ]
        //TODO NOT WORKING SHOULD I REPLACE WHOLE JSON FILES?
        do {
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
//            appd.wsIndex = wsIndex
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
                let worksheetPaths = try file?.parseWorksheetPathsAndNames(workbook: workbook) ?? []
                
                var tempSheets: [(name: String, id: Int, idString: String)] = []

                for (name, path) in worksheetPaths {
                    guard let name = name else { continue }
                    
                    let idString = path.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    if let id = Int(idString) {
                        tempSheets.append((name: name, id: id, idString: idString))
                    }
                }

                tempSheets.sort {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }

                appd.sheetNames = tempSheets.map { $0.name }
                appd.sheetNameIds = tempSheets.map { $0.idString }
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
                
                // parseWorksheet(at:) re-extracts the zip entry and re-runs the XML decoder
                // from scratch on every call (no caching inside CoreXLSX) -- it was being
                // called 3 separate times below for the same path. Parse it once and reuse.
                let ws = try file!.parseWorksheet(at: path)

                let container = ws.data?.rows.flatMap { $0.cells } ?? []
                columnName = uniquing(src:container.map { $0.reference.column.value })//AA AS AW E

                // Cells bucketed by column, built once from the already-flattened `container`.
                // ws.cells(atColumns:) rescans every row/cell in the sheet on every call, and
                // it was being called 3 times per column below -- O(columns * totalCells).
                let cellsByColumn = Dictionary(grouping: container) { $0.reference.column.value }

                //mergedcells initialization
                let mergedCells = ws.mergeCells
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
                appd.CELL_HEIGHT_EXCEL_GSHEET = Double(ws.formatProperties?.defaultRowHeight ?? "-1")!
                appd.CELL_WIDTH_EXCEL_GSHEET = Double(ws.formatProperties?.defaultRowHeight ?? "-1")!
                
                
                //Getting strings
                for i in 0..<columnName.count {
                    let k = String(columnName[i])
                    if k.count != 0 {
                        let columnCells = cellsByColumn[k] ?? []
                        let columnCStrings = columnCells
                        // in format internals "s" stands for "shared"
                            .filter { $0.type?.rawValue ?? nil == "s" }
                            .filter { $0.value != nil }

                        // Rich Text
                        let temp = columnCStrings.compactMap { $0.value }.compactMap { Int($0)}.compactMap { sharedStrings!.items[$0].richText }

                        // Normal Text
                        var temp2 = columnCStrings.compactMap { $0.value }.compactMap { Int($0)}.compactMap { sharedStrings!.items[$0].text }


                        //get style
                        let allCells = columnCells
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
                        let columnCStrings = (cellsByColumn[k] ?? [])
                            .filter { $0.type?.rawValue ?? nil != "s"  }
                            .filter { $0.value != nil || $0.formula != nil }

                        var formulaCheck = [String]()
                        for i in 0..<columnCStrings.count {
                            let formulaContent = columnCStrings[i].formula?.value
                            let valueContent = columnCStrings[i].value
                            
                            if formulaContent == nil {
                                //normal values
                                formulaCheck.append(valueContent!)
                            }else{
                                let containsItem = excelFunctionsNotSupportedInXLSV.contains { formulaContent! == $0 }
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

                // columnsInAlphabet.firstIndex(of:) was an O(columnsize) scan called once per
                // row below -- O(rows * columnsize). Build an index once instead.
                var columnIndexInAlphabet = [String: Int]()
                columnIndexInAlphabet.reserveCapacity(columnsInAlphabet.count)
                for (idx, name) in columnsInAlphabet.enumerated() {
                    columnIndexInAlphabet[name] = idx
                }

                for i in 0..<valueLocation.count {
                    let columnL_value = valueLocation[i].components(separatedBy: CharacterSet.decimalDigits).joined()

                    let columnL = columnIndexInAlphabet[columnL_value]!
                    let rowL = valueLocation[i].filter("0123456789.".contains)
                    //https://stackoverflow.com/questions/36594179/remove-all-non-numeric-characters-from-a-string-in-swift
                    //colum index 0 is empty. empty, A,B,C ...
                    finalL_value.append(String(columnL) + "," + rowL)
                }

                for i in 0..<stringLocation.count {
                    let columnL_value = stringLocation[i].components(separatedBy: CharacterSet.decimalDigits).joined()

                    let columnL = columnIndexInAlphabet[columnL_value]!
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
                    fontSize.append(String(10))
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
                                           "columnsize": columnsize+1,
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
            print("sorry pal cant copy it.",error)
        }
    }
    
    //Making the array with unique values
    func uniquing(src:[String]) -> [String]{
        var unique = [String]()
        unique.reserveCapacity(src.count)
        var seen = Set<String>()

        for item in src {
            if seen.insert(item).inserted {
                unique.append(item)
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
        

        UserDefaults.standard.set(maxrow!+10, forKey: "NEWRsize")

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
        let uppercasedColumn = column.uppercased()
        var result = 0
        
        for scalar in uppercasedColumn.unicodeScalars {
            let asciiValue = scalar.value
            
            if asciiValue >= 65 && asciiValue <= 90 {
                result = result * 26 + Int(asciiValue - 64)
            } else {
                break
            }
        }
        
        return result > 0 ? result : nil
    }
}



