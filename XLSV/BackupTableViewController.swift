import UIKit
import CoreXLSX
import Foundation
import SwiftyXMLParser


class BackupTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var backupFiles: [URL] = []
    let cellId = "cell"
    
    let tableView = UITableView()
    
    let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.title = "Backups"
        
        setupLayout()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        
        loadData()
    }

    func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(backButton)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: backButton.topAnchor, constant: -10)
        ])
    }

    @objc func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    func loadData() {
        self.backupFiles = ExcelHelper().getBackupFiles()
        tableView.reloadData()
    }

    // MARK: - TableView Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return backupFiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = backupFiles[indexPath.row].lastPathComponent
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedFileURL: URL = backupFiles[indexPath.row]
        
        print("Selected file: \(selectedFileURL.lastPathComponent)")
        
        
        let fileName = selectedFileURL.lastPathComponent
        
        let actionSheet = UIAlertController(title: "Options", message: fileName, preferredStyle: .actionSheet)
        
    
        actionSheet.addAction(UIAlertAction(title: "Restore", style: .default) { _ in
            self.restore(selectedFileURL: selectedFileURL)
        })
        
     
        actionSheet.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
            self.rename(fileName: fileName, selectedFileURL: selectedFileURL)
        })
        

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = actionSheet.popoverPresentationController {
            if let cell = tableView.cellForRow(at: indexPath) {
                popoverController.sourceView = cell
                popoverController.sourceRect = cell.bounds
            }
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func rename(fileName:String,selectedFileURL:URL){
        let renameAlert = UIAlertController(title: "Rename File", message: "Enter new name", preferredStyle: .alert)
        
        renameAlert.addTextField { textField in
            textField.text = (fileName as NSString).deletingPathExtension
        }
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let newName = renameAlert.textFields?.first?.text, !newName.isEmpty else { return }
            
            let fileExtension = selectedFileURL.pathExtension
            let directoryURL = selectedFileURL.deletingLastPathComponent()
            let newFileURL = directoryURL.appendingPathComponent(newName).appendingPathExtension(fileExtension)
            
            do {
                try FileManager.default.moveItem(at: selectedFileURL, to: newFileURL)
                print("Renamed to: \(newFileURL.lastPathComponent)")
 
                self.loadData()
                
            } catch {
                print("Error renaming file: \(error.localizedDescription)")
            }
        }
        
        renameAlert.addAction(confirmAction)
        renameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(renameAlert, animated: true)
    }
    
    func restore(selectedFileURL:URL){
        if selectedFileURL.absoluteString.contains(".xlsx"){
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            
            let fnameArry = selectedFileURL.absoluteString.split(separator: "/")
            let fnameA = fnameArry.last!.split(separator: ".")
            excelName = String(fnameA.first!) + "." + String(fnameA.last!)
            
            //excel process
            let fp = selectedFileURL.path
            print("excel file")
            print("yourExcelfile",fp)
            appd.imported_xlsx_file_path=fp
            appd.excelfilename=excelName
            readExcel(path: fp)
            
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            let url = serviceInstance.testSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
            //createxlsxSheet()
            
            replaceLocalFileWithImportedOne()
            
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController//Landscape
            targetViewController.isExcel = true
            
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                   let window = appDelegate.window {
                    
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        window.rootViewController = targetViewController
                    }, completion: nil)
                    
                    window.makeKeyAndVisible()
                }
        }
    }
    //Delete Backups Function, swipe the row
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let fileURLToDelete = backupFiles[indexPath.row]
            
            do {
                try FileManager.default.removeItem(at: fileURLToDelete)
                print("Deleted file: \(fileURLToDelete.lastPathComponent)")
                
                backupFiles.remove(at: indexPath.row)
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                
            } catch {
                print("Could not delete file: \(error.localizedDescription)")
                
                loadData()
            }
        }
    }

    
    func replaceLocalFileWithImportedOne() {
        let appd = UIApplication.shared.delegate as! AppDelegate
        let pathDirectory = getRootDocumentsDirectory()
        let overWrittenfilePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent("initialXLSX.xlsx")
        
        let overWritingfilePath = URL(fileURLWithPath: appd.imported_xlsx_file_path)
        
        let backupDir = ExcelHelper().getBackupDirectory()
        let isFromBackup = backupDir.map { overWritingfilePath.path.contains($0.path) } ?? false

        do {
            let fileManager = FileManager.default
            
            //Want to keep backup files
            if isFromBackup {
                if fileManager.fileExists(atPath: overWrittenfilePath.path) {
                    try fileManager.removeItem(at: overWrittenfilePath)
                }
                try fileManager.copyItem(at: overWritingfilePath, to: overWrittenfilePath)
                print("Restore: Copied from backup to local.")
            } else {
                //Ok to delete temp imported files
                try fileManager.replaceItemAt(overWrittenfilePath, withItemAt: overWritingfilePath)
                print("Import: Replaced local file and removed temp.")
            }
            
            appd.imported_xlsx_file_path = overWrittenfilePath.path
        } catch {
            print("Error during file replacement: \(error.localizedDescription)")
        }
    }

    
    func readExcel(path:String, wsIndex:Int = 1){
        let excelFunctionsNotSupportedInXLSV = [
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
            "sqrt",
            "PI()",
            "EXP(1)",
            "ASIN",
            "ACOS",
            "ATAN",
            "SIN",
            "COS",
            "TAN",
            "EXP",
            "LOG",
            "LOG10",
            "LN",
            "ABS",
            "SQRT"
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

                tempSheets.sort { $0.id < $1.id }

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
