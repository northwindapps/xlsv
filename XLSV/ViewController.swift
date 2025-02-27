//
//  ViewController.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2016/11/22.
//  Copyright © 2016年 Credera. All rights reserved.
//

import UIKit
import MessageUI
import QuartzCore
import CoreData
import Zip
import SSZipArchive
import CoreFoundation
//import GoogleMobileAds

let reuseIdentifier = "customCell"
var SCREENSIZE_w = ScreenSize.SCREEN_WIDTH
var SCREENSIZE = ScreenSize.SCREEN_HEIGHT

var otherclass = colorclass()


class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate,UITextViewDelegate,MFMailComposeViewControllerDelegate,UICollectionViewDelegateFlowLayout,UIDocumentPickerDelegate,UIGestureRecognizerDelegate{
    
//    @IBOutlet weak var bannerview: GADBannerView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var fileTitle: UILabel!
    
    @IBOutlet weak var FileCollectionView: UICollectionView!
    var KEYBOARDLOCATION:CGFloat = 0.0
    @objc var List: Array<AnyObject> = []
    
    var location = [String]()
    var locationInExcel = [String]() //reset before storeinput
    var content = [String]()
    var old_localFileNames = [String]()
    //
    var search_text = ""
    var replace_text = ""
    var csview = false
    
    @IBOutlet weak var hiddenTextField: UITextField!
    
    //mergedcells
    var nousecells = [[Int]]()
    var columnNames = [String]()
    var localFileNames = [String]()
    var sum_str = ""
    
    //Font location
    var cursor = String()
    var changeaffected = [String]()
    
    var tcolor = [String]()
    var textsize = [String]()
    var bgcolor = [String]()
    
    var columninNumber = [String]()
    var rowinNumber = [String]()
    
    var COLUMNSIZE = 0
    var ROWSIZE = 0
    var FONTEDIT :String = ""
    var orientaion = ""
    var cell_scalevalue = 1.0
    var settingCellSelected = false
    
    var tag_int :Int!
    
    var current_range : NSRange!
    
    //
    var customview3 :Customview3!
    
    var stringboxText = ""
    var pastemode : Bool = false
    var getvaluemode :Bool = false
    var getRefmode : Bool = false
    var clipboard = ""
    
    //http://stackoverflow.com/questions/28360919/my-table-view-reuse-the-selected-cells-when-scroll-in-swift
    
    //http://stackoverflow.com/questions/31706404/ios-8-and-swift-call-a-function-in-another-class-from-view-controller
    //var global = ns()
    var global2 = NilController()
    
    var boolean :Bool! //coulmnsize_check
    
    var numberview = numberkey()
    
    var calcmemory = "0"
    
    var labelsizedouble = 0.0
    var labelsizedouble2 = 0.0
    
    
    var DATABASE_STR = ""
    
    var imageData: NSData? = nil
    
    var up_bool = false
    var down_bool = false
    var right_bool = false
    var left_bool = false
    
    var selection_bool = false
    
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    
    var customview2 :Customview2!
    var Fview :formatview!
    var datainputview :Datainputview!
    var Hintview:Hint!
    
    //forexport
    var data: Data? = nil
    var byproduct: NSMutableString? = nil
    var currentindex : IndexPath!
    var currentindexstr = "1,1"//String!
    var selectedSheet = 0 //initial
    
    //calculation
    var f_content = [String]()
    var f_calculated = [String]()
    var f_location_alphabet = [String]()
    var f_location = [String]()
    var input_order = [String]()
    
    //User feedback
    var selectingColor = "black"
    var selectingSize = 12
    var selectingBgColor = "white"
    
    //isExcelFile?
    var isExcel = false
    var isCSV = false
    var isMail = false
//    var sheetIdx = 0
    
    //RangeSelection reset at the start
    var tempRangeSelected = [IndexPath]()
    
    //
    var localFileName = [String]()
    var currentFileNameCollectionViewIdx = IndexPath(item: 0, section: 0)
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        myCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if collectionView === myCollectionView{
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            
            //#warning Incomplete method implementation -- Return the number of sections
            var rowsize = appd.DEFAULT_ROW_NUMBER//100
            
            if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
                let v = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
                if v > rowsize{
                    rowsize = v
                }
            }
            
            
            if rowsize < 1{
                rowsize = 1
            }
            
            
            
            ROWSIZE = rowsize
            
            
            appd.numberofRow = rowsize
            return rowsize
            
        }else{
            return 1
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView === myCollectionView{
            //#warning Incomplete method implementation -- Return the number of items in the section
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            var columnsize = appd.DEFAULT_COLUMN_NUMBER //27
            if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
                let v = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
                if v > columnsize{
                    columnsize = v
                }
            }
            
            
            if columnsize < 1{
                columnsize = 1
            }
            
            COLUMNSIZE = columnsize// + 1
            
            appd.numberofColumn = columnsize
            
            return columnsize
            
        }else{
            
            return localFileNames.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //something went wrong maybe fix it in future..maybe
        if location.count != textsize.count{
            textsize.removeAll()
            bgcolor.removeAll()
            tcolor.removeAll()
            for _ in 0..<location.count{
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
            }
        }
        
        //Render
        if collectionView === myCollectionView{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CustomCollectionViewCell
            
            
            cell.label2?.lineBreakMode = .byWordWrapping // or NSLineBreakMode.ByWordWrapping
            cell.label2?.numberOfLines = 0
            
            removePanGestureRecognizerFromCell(cell)
            
            //content
            if location.contains(String(indexPath.item)+","+String(indexPath.section)){
                
                let i = location.index(of: String(indexPath.item)+","+String(indexPath.section))
                
                //cell.label2?.text = content[i!].replacingOccurrences(of: "\"\"", with: "\n")
                let notFunc = content[i!]//.replacingOccurrences(of: "\"\"", with: "\n").replacingOccurrences(of: "\n", with: "\n")
                if f_location.contains(String(indexPath.item)+","+String(indexPath.section)){
                    let idx = f_location.index(of: String(indexPath.item)+","+String(indexPath.section))
                    if f_calculated.count-1 < idx!{
                        cell.label2?.text = "error"
                    }else{
                        cell.label2?.text = f_calculated[idx!]
                    }
                    let fl: CGFloat = CGFloat((textsize[i!] as NSString).doubleValue)
                    cell.label2?.font = UIFont.italicSystemFont(ofSize: fl)
                    //                tcolor[i!] = "gray"
                    cell.label2?.textAlignment = .right
                    
                }else if Double(notFunc) != nil {
                    cell.label2?.text = notFunc
                    let fl: CGFloat = CGFloat((textsize[i!] as NSString).doubleValue)
                    cell.label2?.font = UIFont.systemFont(ofSize: fl)
                    cell.label2?.textAlignment = .right
                }else{
                    cell.label2?.text = notFunc
                    let fl: CGFloat = CGFloat((textsize[i!] as NSString).doubleValue)
                    cell.label2?.font = UIFont.systemFont(ofSize: fl)
                    cell.label2?.textAlignment = .left
                }
            }else{
                //empty
                let fl: CGFloat = CGFloat(("13" as NSString).doubleValue)
                cell.label2?.font = UIFont.systemFont(ofSize: fl)
                cell.label2?.text = ""
                cell.label2?.textAlignment = .center
            }
            
            if selection_bool {
                //number or fx only
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
                cell.addGestureRecognizer(panGesture)
            }
            
            
            //Border
            if cursor == (String(indexPath.item)+","+String(indexPath.section)) || changeaffected.contains(String(indexPath.item)+","+String(indexPath.section)){
                
                cell.label2?.layer.borderColor = UIColor(red: 255/255, green: 0/255, blue: 51/255, alpha: 1).cgColor
                cell.label2?.layer.borderWidth = 3.0
            }else{
                cell.label2?.layer.borderColor = UIColor.orange.cgColor
                cell.label2?.layer.borderWidth = 0.5
            }
            
            
            //BG
            if location.contains(String(indexPath.item)+","+String(indexPath.section)){
                let i = location.index(of: String(indexPath.item)+","+String(indexPath.section))
                
                if bgcolor[i!].count > 0 {
                    
                    switch bgcolor[i!] {
                    case "green":
                        cell.label2?.backgroundColor  = UIColor(red: 0/255, green: 102/255, blue: 0/255, alpha: 1)
                        
                    case "water":
                        cell.label2?.backgroundColor  = UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1)
                        
                    case "yellow":
                        cell.label2?.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 1)
                        
                    case "orange":
                        cell.label2?.backgroundColor = UIColor(red: 255/255, green: 102/255, blue: 0/255, alpha: 1)
                        
                    case "lightGray":
                        cell.label2?.backgroundColor  = UIColor.lightGray
                        
                    case "magenta":
                        cell.label2?.backgroundColor = UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1)
                        
                    case "blue":
                        cell.label2?.backgroundColor  = UIColor(red: 51/255, green: 153/255, blue: 255/255, alpha: 1)
                        
                    case "red":
                        cell.label2?.backgroundColor  = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)
                        
                    case "brown":
                        cell.label2?.backgroundColor  = UIColor(red: 102/255, green: 61/255, blue: 0/255, alpha: 1)
                        
                    case "purple":
                        cell.label2?.backgroundColor  = UIColor(red: 40/255, green: 0/255, blue: 100/255, alpha: 1)
                        
                    case "gray":
                        cell.label2?.backgroundColor = UIColor.gray
                        
                    case "white":
                        cell.label2?.backgroundColor  = UIColor.white
                        
                    default:
                        cell.label2?.backgroundColor  = UIColor.white
                        
                    }
                }
                
                if tcolor[i!].count > 0{
                    
                    //textcolor
                    switch tcolor[i!] {
                    case "green":
                        cell.label2?.textColor  = UIColor(red: 0/255, green: 102/255, blue: 0/255, alpha: 1)
                        
                    case "water":
                        cell.label2?.textColor  = UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1)
                        
                    case "yellow":
                        cell.label2?.textColor = UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 1)
                        
                    case "orange":
                        cell.label2?.textColor = UIColor(red: 255/255, green: 102/255, blue: 0/255, alpha: 1)
                        
                    case "lightGray":
                        cell.label2?.textColor   = UIColor.lightGray
                        
                    case "magenta":
                        cell.label2?.textColor = UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1)
                        
                    case "blue":
                        cell.label2?.textColor  = UIColor(red: 51/255, green: 153/255, blue: 255/255, alpha: 1)
                        
                    case "red":
                        cell.label2?.textColor   = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)
                        
                    case "brown":
                        cell.label2?.textColor  = UIColor(red: 102/255, green: 61/255, blue: 0/255, alpha: 1)
                        
                    case "purple":
                        cell.label2?.textColor  = UIColor(red: 40/255, green: 0/255, blue: 100/255, alpha: 1)
                        
                    case "gray":
                        cell.label2?.textColor = UIColor.gray
                        
                    case "white":
                        cell.label2?.textColor  = UIColor.white
                    default:
                        cell.label2?.textColor  = UIColor.black
                        
                    }
                    
                }
                
            }else{
                cell.label2?.backgroundColor = UIColor.white
                cell.label2?.textColor = UIColor.black
                
                if indexPath.item == 0{
                    
                    if indexPath.section > 0{
                        cell.label2?.text = String(indexPath.section)
                        rowinNumber.append("r" + String(indexPath.section))
                    }
                    
                    cell.label2?.backgroundColor = UIColor.lightGray//UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1.0)
                    cell.label2?.layer.borderColor = UIColor.white.cgColor
                    cell.label2?.layer.borderWidth = 0.7
                    cell.setBorder(width: 0.8, color: UIColor.lightGray, sides: .bottom)
                    cell.label2?.textColor = UIColor.black
                    cell.label2?.textAlignment = .center
                }else if indexPath.section == 0{
                    
                    
                    
                    if indexPath.item > 0{//0,0 == greyzone
                        cell.label2?.text = getExcelColumnName(columnNumber: indexPath.item)//ABCDE...
                        columninNumber.append(getExcelColumnName(columnNumber: indexPath.item))
                    }
                    
                    cell.label2?.layer.borderColor = UIColor.white.cgColor
                    cell.label2?.layer.borderWidth = 0.7
                    cell.label2?.backgroundColor = UIColor.lightGray//UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1.0)
                    cell.label2?.textColor = UIColor.black
                    cell.label2?.textAlignment = .center
                }
            }
            
            //http://stackoverflow.com/questions/29381994/swift-check-string-for-nil-empty
            //http://qiita.com/satomyumi/items/b0d071cc906574086ac4
            
            //print("width size",cell.frame.width)
            let predifinedIds = [31]
            let ipstr = String(indexPath.section) + "," + String(indexPath.row)
            let styleId = appd.excelStyleLocation.firstIndex(of: ipstr)
            if (styleId != nil && (appd.excelStyleIdx[styleId!] != -1) && appd.cellXfs.count != 0 && appd.numFmtIds.count != 0 && appd.numFmts.count != 0 && appd.excelStyleIdx.count != 0){
                var c = 0
                let borderId = appd.cellXfs[appd.excelStyleIdx[styleId!]]
                let numId = appd.numFmtIds[appd.excelStyleIdx[styleId!]]
                var idx = appd.numFmts.firstIndex(of: String(numId))
                if idx == nil{
                    idx = appd.numFmtIds.firstIndex(of: numId)
                }
                //https://c-rex.net/samples/ooxml/e1/Part4/OOXML_P4_DOCX_numFmt_topic_ID0EHDH6.html
                if idx == nil && predifinedIds.contains(numId){
                    idx = 0
                }
                
                if (idx != nil) {
                    var a = false
                    
                    //id first
                    if numId == 14 {
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                             
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MM/dd/yyyy"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                    
                    if numId == 31 && !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                             
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy/MM/dd"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                    
                    if numId == 20 || (appd.formatCodes.count > idx! &&  appd.formatCodes[idx!] == "[h]:mm") || (appd.formatCodes.count > idx! && appd.formatCodes[idx!] == "hh:mm"){
                        if let labelText = cell.label2.text, let inputValue = Decimal(string:labelText) {
                            let totalHours = inputValue * Decimal(24)
                            let input24 = inputValue * Decimal(24)
                            let strHours = String(floor(input24.doubleValue))
                            let fractionHours = totalHours - Decimal(floor(input24.doubleValue))
                            let decimalMinutes = fractionHours * Decimal(60)
                           
                           
                            let roundingBehavior = NSDecimalNumberHandler(roundingMode: .plain, scale: 4, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
                            let resultAsNSDecimalNumber = NSDecimalNumber(decimal: decimalMinutes)
                            let roundedResult = resultAsNSDecimalNumber.rounding(accordingToBehavior: roundingBehavior)

                            var strMinutes = String(roundedResult.description)
                            if fractionHours * 60 < 10.0{
                                strMinutes = "0" + strMinutes
                            }
                            cell.label2.text = strHours.components(separatedBy: ".").first! + ":" + strMinutes.components(separatedBy: ".").first!
                            a = true
                        }
                    }
                    
                    //numId> 49 not predefined number by xlsx?
                    if numId > 49 && (appd.formatCodes.count > idx! && appd.formatCodes[idx!].contains("yyyy") && appd.formatCodes[idx!].contains("mm") && appd.formatCodes[idx!].contains("dd")) && !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                             
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy/MM/dd"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                    
                    if numId > 49 && ((appd.formatCodes.count > idx! && appd.formatCodes[idx!].contains("yyyy") && appd.formatCodes[idx!].contains("mm") ) || (appd.formatCodes.count > idx! && appd.formatCodes[idx!].contains("yyyy") && appd.formatCodes[idx!].contains("m"))) &&  !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400) // Your timestamp
                            
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy/MM"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                    
                if  numId > 49 && (appd.formatCodes.count > idx! && appd.formatCodes[idx!].contains("mm") && appd.formatCodes[idx!].contains("dd")) && !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                            
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MM/dd"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                
                    
                    if numId > 49 && (appd.formatCodes.count > idx! && appd.formatCodes[idx!] == "d") && !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                            
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "d"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                        }
                    }
                    
                }
                if borderId < appd.border_lefts.count && appd.border_lefts[borderId] > 0{
                    cell.setBorder(width: 0.8, color: UIColor.lightGray, sides: .left)
                    c+=1
                }
                
                if borderId < appd.border_rights.count && appd.border_rights[borderId] > 0{
                    cell.setBorder(width: 0.8, color: UIColor.lightGray, sides: .right)
                    c+=1
                }
                
                if borderId < appd.border_tops.count && appd.border_tops[borderId] > 0{
                    cell.setBorder(width: 0.8, color: UIColor.lightGray, sides: .top)
                    c+=1
                }
                
                if borderId < appd.border_bottoms.count && appd.border_bottoms[borderId] > 0{
                    cell.setBorder(width: 0.8, color: UIColor.lightGray, sides: .bottom)
                    c+=1
                }
                
                if c == 0{
                    cell.setBorder(width: 0.5, color: UIColor.lightGray, sides: .all)
                }
            }else{
                cell.setBorder(width: 0.5, color: UIColor.lightGray, sides: .all)
            }
            
            return cell
            
        }else{
            //sheet cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FileCollectionViewCell
            let title = localFileNames[indexPath.item]
            cell.FileLabel.text = title
            
            if isExcel && currentFileNameCollectionViewIdx != IndexPath() && indexPath.item == currentFileNameCollectionViewIdx.item{
                cell.FileLabel.backgroundColor = UIColor.lightGray
                cell.FileLabel.textColor = UIColor.white
                return cell
            }
            
            //if !isExcel && indexPath.item == selectedSheet {
            if !isExcel && indexPath.item == selectedSheet {
                cell.FileLabel.backgroundColor = UIColor.lightGray
                cell.FileLabel.textColor = UIColor.white
                return cell
            }

            cell.FileLabel.backgroundColor = UIColor.white
            cell.FileLabel.textColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
            return cell
        }
    }
    
    // Method to remove the pan gesture recognizer from a cell
    func removePanGestureRecognizerFromCell(_ cell: UICollectionViewCell) {
        if let gestureRecognizers = cell.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer is UIPanGestureRecognizer {
                    cell.removeGestureRecognizer(recognizer)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
    
    
    //Hiding Keyboard
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            changeaffected.removeAll()
            
            //data input
            input()
            
            saveuserF()
            saveuserD()
            
//            if selectedSheet >= 0{
            //if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex{
            if !isExcel{
                print("saved")
                saveAsLocalJson(filename: "csv_sheet1")
            }
            //}
            
            
            let locationIdx = location.firstIndex(of: currentindexstr)
            if locationIdx != nil && content[locationIdx!] != ""{
                datainputview.stringbox.text = content[locationIdx!]
            }
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                print("wsSheetIndex",appd.wsSheetIndex)
                //let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
                self.loadExcelSheet(idx: appd.wsSheetIndex)
                // Assuming `collectionView` is your UICollectionView instance
                if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                    customLayout.resetCellAttrsDictionaryItemZindex()
                    customLayout.prepare()
                    customLayout.invalidateLayout() // Call the method on the instance
                    self.myCollectionView.reloadData()
                } else {
                    print("CustomCollectionViewLayout is not set as the current layout")
                }
                
            }
            return false
        }
        return true
    }
    
    
    //touch cell touch
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === myCollectionView{
            //reset change history
            currentindex = indexPath
            currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
            
            
            getIndexlabel()
            cursor = currentindexstr
            
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appd.collectionViewCellSizeChanged = 0
                
                changeaffected.removeAll()
                //sizing column width and height
                if indexPath.item == 0{
                    //do nothing
                    //settingCellSelected = true
                    //numberviewopen()
                    
                    
                }else if indexPath.section == 0{
                    //do nothing
                    //settingCellSelected  = true
                    //numberviewopen()
                    
                }else{
                    //version 1.3.6 csv mode only not in excel file viewer mode
                    //if !isExcel && !settingCellSelected{
                    if !settingCellSelected{
                        if datainputview == nil{
                            //if there's not
                            opendatainputview()
                        
                        }
                        let locationIdx = location.firstIndex(of: currentindexstr)
                        if (locationIdx != nil) && datainputview != nil {
                            datainputview.stringbox.text = content[locationIdx!]
                        }
                        if (locationIdx == nil && datainputview != nil){
                            datainputview.stringbox.text = ""
                        }
                        
                        self.myCollectionView.reloadData()
                    }
                }
            
        }else{
            //FileNameCollectionview Change Page
            //sheet cell get touched
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
        
            print("go to file view")
            print("selectedSheet",Int(appd.sheetNameIds[indexPath.item]))
            currentFileNameCollectionViewIdx = indexPath
            let sheetIdx = Int(appd.sheetNameIds[indexPath.item])
            print(currentFileNameCollectionViewIdx.item)
//            appd.wsSheetIndex = indexPath.item + 1
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
//                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx:Int(appd.sheetNameIds[indexPath.item]) )
                // Assuming `collectionView` is your UICollectionView instance
                if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                    customLayout.resetCellAttrsDictionaryItemZindex()
                    customLayout.prepare()
                    customLayout.invalidateLayout() // Call the method on the instance
                    self.myCollectionView.reloadData()
                } else {
                    print("CustomCollectionViewLayout is not set as the current layout")
                }
                
            }
        }
    }
    
    func loadExcelSheet(idx:Int?)
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if appd.imported_xlsx_file_path == "" {
            self.isExcel = false
        }
        
        if appd.imported_xlsx_file_path != "" {
            print("yourExcelfile",appd.imported_xlsx_file_path)
            let ehp = ExcelHelper()
            ehp.readExcel2(path: appd.imported_xlsx_file_path, wsIndex: idx!)
            // Do any additional setup after loading the view.
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            //let url = serviceInstance.testSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
            let notUsed = serviceInstance.testReadXMLSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
            
            self.isExcel = true
        }
        
        //checkSheet
        isExcelSheetData(sheetIdx: idx!)
        initSheetData()
        otherclass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        initExcelLocation()
        
        
        localFileNames = appd.sheetNames //sheet1,sheet2
        FileCollectionView.reloadData()
        
        
        
        
        
        for idx in 0..<COLUMNSIZE {
            let letters = getExcelColumnName(columnNumber: idx)
            columnNames.append(letters)
        }
        
        //Finally calculate
        calculatormode_update_main()
    }
    
//    xlsx numFmtId
//    numFmtId    Format Code    Description
//    0    General    General format
//    1    0    Decimal
//    2    0.00    Decimal with two places
//    3    #,##0    Thousands separator
//    4    #,##0.00    Thousands separator with two places
//    9    0%    Percentage
//    10    0.00%    Percentage with two places
//    11    0.00E+00    Scientific notation
//    12    # ?/?    Fraction (1/4)
//    13    # ??/??    Fraction (1/16)
//    14    mm-dd-yy    Date
//    15    d-mmm-yy    Date
//    16    d-mmm    Date
//    17    mmm-yy    Date
//    18    h:mm AM/PM    Time
//    19    h:mm:ss AM/PM    Time
//    20    h:mm    Time
//    21    h:mm:ss    Time
//    22    m/d/yy h:mm    Date and time
//    37    #,##0_);(#,##0)    Accounting
//    38    #,##0_);[Red](#,##0)    Accounting (with red negative numbers)
//    39    #,##0.00_);(#,##0.00)    Accounting with two decimal places
//    40    #,##0.00_);[Red](#,##0.00)    Accounting with red negative numbers
//    45    mm:ss    Elapsed time
//    46    [h]:mm:ss    Elapsed time with hours
//    47    mmss.0    Elapsed time with decimal seconds
//    48    ##0.0E+0    Scientific with one place
//    49    @    Text
//
    
    
    //http://stackoverflow.com/questions/27674317/changing-cell-background-color-in-uicollectionview-in-swift
    //data input
    func opendatainputview(){
        //don't forget first call
        if datainputview != nil{
            datainputview.removeFromSuperview()
        }
        
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                // It's an iPhone
                if Double(SCREENSIZE) != nil && Double(KEYBOARDLOCATION) != nil &&  SCREENSIZE > 0 &&  KEYBOARDLOCATION > 0 && Int(SCREENSIZE - KEYBOARDLOCATION - 60.0) > 0 {
                    // The result is an integer and greater than 0
                    datainputview = Datainputview(frame: CGRect(x:0,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 320,height: 60))
                    
                } else {
                    datainputview = Datainputview(frame: CGRect(x:0,y:200, width: 320,height: 60))
                }

                
                
                datainputview.downArrow.addTarget(self, action: #selector(imoveDown), for: UIControl.Event.touchUpInside)
                datainputview.rightArrow.addTarget(self, action: #selector(imoveRight), for: UIControl.Event.touchUpInside)
                
                break
            case .pad:
                
                // It's an iPad
                datainputview = Datainputview(frame: CGRect(x:Int(60),y:Int(SCREENSIZE - KEYBOARDLOCATION - 160.0), width: 642,height: 160))
                datainputview.downArrow.addTarget(self, action: #selector(moveDown), for: UIControl.Event.touchUpInside)
                datainputview.rightArrow.addTarget(self, action: #selector(moveRight), for: UIControl.Event.touchUpInside)
                
                
                
                //formula buttons
                datainputview.sinButton.addTarget(self, action: #selector(sinAction), for: UIControl.Event.touchUpInside)
                datainputview.asinButton.addTarget(self, action: #selector(asinAction), for: UIControl.Event.touchUpInside)
                datainputview.cosButton.addTarget(self, action: #selector(cosAction), for: UIControl.Event.touchUpInside)
                datainputview.acosButton.addTarget(self, action: #selector(acosAction), for: UIControl.Event.touchUpInside)
                datainputview.tanButton.addTarget(self, action: #selector(tanAction), for: UIControl.Event.touchUpInside)
                datainputview.atanButton.addTarget(self, action: #selector(atanAction), for: UIControl.Event.touchUpInside)
                datainputview.logdButton.addTarget(self, action: #selector(logdAction), for: UIControl.Event.touchUpInside)
                datainputview.lnButton.addTarget(self, action: #selector(lnAction), for: UIControl.Event.touchUpInside)
                datainputview.expButton.addTarget(self, action: #selector(expAction), for: UIControl.Event.touchUpInside)
                datainputview.powButton.addTarget(self, action: #selector(powAction), for: UIControl.Event.touchUpInside)
                datainputview.sqrtButton.addTarget(self, action: #selector(sqrtAction), for: UIControl.Event.touchUpInside)
                datainputview.complexButton.addTarget(self, action: #selector(complexAction), for: UIControl.Event.touchUpInside)
                datainputview.piButton.addTarget(self, action: #selector(piAction), for: UIControl.Event.touchUpInside)
                datainputview.imsumButton.addTarget(self, action: #selector(imsumAction), for: UIControl.Event.touchUpInside)
                datainputview.imsubButton.addTarget(self, action: #selector(imsubAction), for: UIControl.Event.touchUpInside)
                datainputview.improButton.addTarget(self, action: #selector(improAction), for: UIControl.Event.touchUpInside)
                datainputview.imargButton.addTarget(self, action: #selector(imargAction), for: UIControl.Event.touchUpInside)
                datainputview.imdivButton.addTarget(self, action: #selector(imdivAction), for: UIControl.Event.touchUpInside)
                datainputview.imabsButton.addTarget(self, action: #selector(imabsAction), for: UIControl.Event.touchUpInside)
                datainputview.imrectButton.addTarget(self, action: #selector(imrectAction), for: UIControl.Event.touchUpInside)
                datainputview.plusButton.addTarget(self, action: #selector(plusmarkAction), for: UIControl.Event.touchUpInside)
                datainputview.crossButton.addTarget(self, action: #selector(crossAction), for: UIControl.Event.touchUpInside)
                datainputview.openBraceButton.addTarget(self, action: #selector(openBraceAction), for: UIControl.Event.touchUpInside)
                datainputview.closeBraceButton.addTarget(self, action: #selector(closeBraceAction), for: UIControl.Event.touchUpInside)
                datainputview.commaButton.addTarget(self, action: #selector(commaAction), for: UIControl.Event.touchUpInside)
                datainputview.colonButton.addTarget(self, action: #selector(colonAction), for: UIControl.Event.touchUpInside)
                
                
                break
            case .unspecified:
                // Uh, oh! What could it be?
                if Double(SCREENSIZE) != nil && Double(KEYBOARDLOCATION) != nil &&  SCREENSIZE > 0 &&  KEYBOARDLOCATION > 0 && Int(SCREENSIZE - KEYBOARDLOCATION - 60.0) > 0 {
                    // The result is an integer and greater than 0
                    datainputview = Datainputview(frame: CGRect(x:0,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 320,height: 60))
                    
                } else {
                    datainputview = Datainputview(frame: CGRect(x:0,y:200, width: 320,height: 60))
                }
                
                break
            default:
                break
            }
        
        
        up_bool = false
        down_bool = false
        right_bool = false
        left_bool = false
        
        
        datainputview.stringbox.delegate = self
        datainputview.stringbox.layer.borderWidth = 1
        datainputview.stringbox.layer.borderColor = UIColor.gray.cgColor
        
        datainputview.okbutton.addTarget(self, action: #selector(ViewController.terminate), for: UIControl.Event.touchUpInside)
        
        datainputview.returnbutton.addTarget(self, action: #selector(ViewController.restore), for: UIControl.Event.touchUpInside)
        
//        datainputview.copyButton.addTarget(self, action: #selector(ViewController.copyText), for: UIControl.Event.touchUpInside)
        
//        datainputview.fontbutton.addTarget(self, action: #selector(endterDelete), for: UIControl.Event.touchUpInside)
        
        //give user a hint
        datainputview.getValuesButton.addTarget(self, action: #selector(showHint), for: UIControl.Event.touchUpInside)
        
//        datainputview.getRefButton.addTarget(self, action: #selector(getRef), for: UIControl.Event.touchUpInside)
        
        datainputview.stringbox.becomeFirstResponder()
        
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
//        if locationstr.contains("ja"){
//            datainputview.fontbutton.setTitle("消去", for: .normal)
//        }else if locationstr.contains("fr"){
//            datainputview.fontbutton.setTitle("supprimer", for: .normal)
//        }else if locationstr.contains("zh"){
//            datainputview.fontbutton.setTitle("删除", for: .normal)
//        }else if locationstr.contains("de"){
//            datainputview.fontbutton.setTitle("Löschen", for: .normal)
//        }else if locationstr.contains("it"){
//            datainputview.fontbutton.setTitle("Cancellare", for: .normal)
//        }else if locationstr.contains("ru"){
//            datainputview.fontbutton.setTitle("удалить", for: .normal)
//        }else if locationstr.contains("es"){
//            datainputview.fontbutton.setTitle("borrar", for: .normal)
//        }else if locationstr == "sv"{
//            datainputview.fontbutton.setTitle("radera", for: .normal)
//        }else{
//            datainputview.fontbutton.setTitle("Delete", for: .normal)
//        }
        
        
        if sum_str.count > 0 {
            datainputview.stringbox.text = sum_str
            sum_str = ""
        }
        
        self.view.addSubview(datainputview)
        
        
        //http://studyswift.blogspot.jp/2015/01/showhide-keyboard-while-using.html
        //https://stackoverflow.com/questions/46375700/programmatically-create-touchupinside-event-for-uitextfield
        
        
        
    }
    
    //https://stackoverflow.com/questions/30937342/check-if-a-subview-is-in-a-view-using-swift
    @objc func showHint(){
        if Hintview != nil{
            if self.view.subviews.contains(Hintview){
                Hintview.removeFromSuperview()
            }else{
                Hintview = Hint(frame: CGRect(x:Int(5),y:Int(10), width: 300,height: 330))
                Hintview.hintCloseButton.addTarget(self, action: #selector(ViewController.closeHview), for: UIControl.Event.touchUpInside)
                
                self.view.addSubview(Hintview)
            }
        }else{
            Hintview = Hint(frame: CGRect(x:Int(5),y:Int(10), width: 300,height: 330))
            Hintview.hintCloseButton.addTarget(self, action: #selector(ViewController.closeHview), for: UIControl.Event.touchUpInside)
            
            self.view.addSubview(Hintview)
        }
    }
    
    @objc func getRef(){
        if getRefmode == false{
                getRefmode = true
                datainputview.getRefButton.setTitleColor(UIColor.yellow, for: .normal)
            }else if getRefmode == true{
                getRefmode = false
                datainputview.getRefButton.setTitleColor(UIColor.white, for: .normal)
            }
    }
    
    
    @objc func endterDelete(){
        
        if pastemode == false {
            pastemode = true
            
            datainputview.fontbutton.setTitleColor(UIColor.red, for: .normal)
        }else if pastemode == true {
            pastemode = false
            
            datainputview.fontbutton.setTitleColor(UIColor.white, for: .normal)
        }
        
        
    }
    
    @objc func csvexport(result:[String])
    {
        
        if customview2 != nil{
            self.customview2.removeFromSuperview()
        }
        //http://stackoverflow.com/questions/32593516/how-do-i-exactly-export-a-csv-file-from-ios-written-in-swift
        let mailString = NSMutableString()
        
        for i in (1..<ROWSIZE)
        {
            for j in (1..<COLUMNSIZE)
            {
                let PATH :String =  String(j) + "," + String(i)//String(i) + "," + String(j)
                
                if location.contains(PATH){
                    let k = location.index(of: PATH)
                    
                    
                    if result[k!].contains(","){
                        mailString.append(result[k!].replacingOccurrences(of: ",", with: "#comma#"))
                    }else if result[k!].contains("\n"){
                        
                    }else{
                        
                        mailString.append(result[k!])
                        
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
        
        byproduct = mailString
        data = mailString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
        
        //save on a temo folder
        saveAsCSV(mailString: byproduct! as String, fileName: "tempCSV")
        
    }
    
    func saveAsCSV(mailString: String, fileName: String) {
        // Convert the string to data
        guard let data = mailString.data(using: .utf8) else {
            print("Failed to convert string to data.")
            return
        }
        
        let fileManager = FileManager.default
            
        // Get the path to save the file
        let pathDirectory = getRootDocumentsDirectory()
        let folderPath = pathDirectory.appendingPathComponent("importedCSV")
        let filePath = pathDirectory.appendingPathComponent("importedCSV").appendingPathComponent("\(fileName).csv")
        
        //is the folder created already?
        if !fileManager.fileExists(atPath: folderPath.path) {
            do {
                try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
                print("Folder created successfully at \(folderPath.path)")
            } catch {
                print("An error occurred while creating the folder: \(error.localizedDescription)")
                return
            }
        }
        
        
        
        
        do {
            if fileManager.fileExists(atPath:filePath.path) {
                try fileManager.removeItem(at: filePath)
            }
            
            // Write the data to the file
            try data.write(to: filePath, options: .atomic)
            print("CSV file saved successfully at \(filePath.path)")
        } catch {
            print("An error occurred while saving the CSV file: \(error.localizedDescription)")
        }
    }
    
    
    @objc func back2(_ sender:UIButton)
    {
        selection_bool = false
        myCollectionView.reloadData()
        self.customview2.removeFromSuperview()
    }
    
    
    
    @objc func loadCreditview(_ sender:UIButton)
    {
        //       postAction()
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "creditView" )
        targetViewController.modalPresentationStyle = .fullScreen
        self.present( targetViewController, animated: true, completion: nil)
        
        self.customview2.removeFromSuperview()
    }
    
    
    
    @objc func localload(_ sender:UIButton)
    {
        
        location.removeAll()
        content.removeAll()
        
        //Font location
        //        bglocation.removeAll()
        //        tlocation.removeAll()
        //        sizelocation.removeAll()
        
        
        tcolor.removeAll()
        textsize.removeAll()
        bgcolor.removeAll()
        
        
        self.customview2.removeFromSuperview()
        
        performSegue(withIdentifier: "previousData", sender: nil)
        
    }
    
    
    @objc func icloudview(_ sender:UIButton){
        
        var message = "Current data will be lost. Is that ok?"
        var yes = "OK"
        var no = "No"
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if locationstr.contains( "ja")
        {
            message = "現在のデータは失われます。それは大丈夫ですか？"
            yes = "はい"
            no = "いいえ"
        }else if locationstr.contains( "fr")
        {
            message = "Les données actuelles seront perdues. Est-ce que ça va?"
            yes = "oui"
            no = "non"
        }else if locationstr.contains( "zh"){
            
            message = "当前数据将丢失。这可以吗？"
            yes = "是"
            no = "否"
        }else if locationstr.contains( "de")
        {
            
            message = "Aktuelle Daten gehen verloren. Ist das in Ordnung?"
            yes = "ja"
            no = "nein"
        }else if locationstr.contains( "it")
        {
            
            message = "I dati attuali andranno persi. È ok?"
            yes = "si"
            no = "no"
        }else if locationstr.contains( "ru")
        {
            
            message = "Текущие данные будут потеряны. Это нормально?"
            yes = "да"
            no = "нет"
        }else if locationstr.contains("sv")
        {
            message = "Nuvarande data kommer att gå förlorade. Är det okej?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("da")
        {
            message = "Aktuelle data vil gå tabt. Er det i orden?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("ar")
        {
            message = "ستفقد البيانات الحالية. هل هذا جيد؟"
            yes = "نعم"
            no = "لا"
            
        }else if locationstr.contains("es")
        {
            message = "Los datos actuales se perderán. ¿Eso esta bien?"
            yes = "si"
            no = "no"
        }else{
            
        }
        
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: yes, style: .default, handler: { action in
            //reset all
            self.location.removeAll()
            self.content.removeAll()
            self.bgcolor.removeAll()
            self.cursor = String()
            self.tcolor.removeAll()
            self.textsize.removeAll()
            
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            
            //Delete all xml files
            let fileList = appd.sheetNameIds.map { "sheet\($0)" }
            
            for i in 0..<fileList.count{
                let name = fileList[i]
                
                self.deleteLocalJson(filename:name)
                
                self.localFileNames.removeAll()
                
                self.FileCollectionView.reloadData()
                
                self.customview2.removeFromSuperview()
                
                self.fileTitle.text = ""
                
            }
            
            //delete local excel
            let pathDirectory = self.getRootDocumentsDirectory()
            let filePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent("initialXLSX.xlsx")
            let fileManager = FileManager.default
            do {
                if fileManager.fileExists(atPath: filePath.path) {
                    try fileManager.removeItem(at: filePath)
                    print("File deleted successfully.")
                } else {
                    print("File does not exist.")
                }
            } catch {
                print("An error occurred while deleting the file: \(error.localizedDescription)")
            }
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "iCloud" )//Landscape
            targetViewController.modalPresentationStyle = .fullScreen
            self.present( targetViewController, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
        
        self.present(alert, animated: true)
        
        
        
        self.customview2.removeFromSuperview()
        
    }
    
    
    @objc func resetSheet(_ sender:UIButton){
        
        var message = "Any unsaved data will be lost. Be sure to export is before resetting."
        var yes = "OK"
        var no = "No"
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if locationstr.contains( "ja")
        {
            message = "現在のデータは失われます。それは大丈夫ですか？"
            yes = "はい"
            no = "いいえ"
        }else if locationstr.contains( "fr")
        {
            message = "Les données actuelles seront perdues. Est-ce que ça va?"
            yes = "oui"
            no = "non"
        }else if locationstr.contains( "zh"){
            
            message = "当前数据将丢失。这可以吗？"
            yes = "是"
            no = "否"
        }else if locationstr.contains( "de")
        {
            
            message = "Aktuelle Daten gehen verloren. Ist das in Ordnung?"
            yes = "ja"
            no = "nein"
        }else if locationstr.contains( "it")
        {
            
            message = "I dati attuali andranno persi. È ok?"
            yes = "si"
            no = "no"
        }else if locationstr.contains( "ru")
        {
            
            message = "Текущие данные будут потеряны. Это нормально?"
            yes = "да"
            no = "нет"
        }else if locationstr.contains("sv")
        {
            message = "Nuvarande data kommer att gå förlorade. Är det okej?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("da")
        {
            message = "Aktuelle data vil gå tabt. Er det i orden?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("ar")
        {
            message = "ستفقد البيانات الحالية. هل هذا جيد؟"
            yes = "نعم"
            no = "لا"
            
        }else if locationstr.contains("es")
        {
            message = "Los datos actuales se perderán. ¿Eso esta bien?"
            yes = "si"
            no = "no"
        }else{
            
        }
        
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: yes, style: .default, handler: { action in
            //reset all
            self.location.removeAll()
            self.content.removeAll()
            self.bgcolor.removeAll()
            self.cursor = String()
            self.tcolor.removeAll()
            self.textsize.removeAll()
            
            
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.cswLocation.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.customSizedHeight.removeAll()
            appd.cswLocation_temp.removeAll()
            appd.cshLocation_temp.removeAll()
            appd.customSizedWidth_temp.removeAll()
            appd.customSizedHeight_temp.removeAll()
            appd.diff_end_index.removeAll()
            appd.diff_start_index.removeAll()
            appd.CELL_HEIGHT_EXCEL_GSHEET = -1.0
            appd.CELL_WIDTH_EXCEL_GSHEET = -1.0
            appd.sheetNames = [String]()
            appd.sheetNameIds = [String]()
            appd.imported_xlsx_file_path = ""
            appd.imported_xlsx_file_path = ""
            appd.isAppStarted = false
        
            let sheet1Json = ReadWriteJSON()
            sheet1Json.deleteJsonFile(title: "csv_sheet1")
            
            //delete local excel
            let pathDirectory = self.getRootDocumentsDirectory()
            let filePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent("initialXLSX.xlsx")
            let fileManager = FileManager.default
            do {
                if fileManager.fileExists(atPath: filePath.path) {
                    try fileManager.removeItem(at: filePath)
                    print("File deleted successfully.")
                } else {
                    print("File does not exist.")
                }
            } catch {
                print("An error occurred while deleting the file: \(error.localizedDescription)")
            }
            
            self.customview2.removeFromSuperview()
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "LoadingViewController" )//Landscape
            targetViewController.modalPresentationStyle = .fullScreen
            self.present( targetViewController, animated: true, completion: nil)
            
        }))
        alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
        
        self.present(alert, animated: true)
        self.customview2.removeFromSuperview()
        
    }
    
    @objc func goSettings(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "Settings" ) as! SettingsViewController
        if isExcel{
            targetViewController.idx = Int(appd.sheetNameIds[selectedSheet])
        }
        targetViewController.modalPresentationStyle = .fullScreen
        print("go to setting view")
      
        self.saveAsLocalJson(filename: "csv_sheet1")
        // Present the target view controller after LoadingFileController's view has appeared
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        
    }
    
    @objc func resetStyle(_ sender:UIButton){
        
        var message = "Current cell styles will be lost. Is that alright?"
        var yes = "OK"
        var no = "No"
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if locationstr.contains( "ja")
        {
            message = "現在のセルスタイルは失われます。それは大丈夫ですか？"
            yes = "はい"
            no = "いいえ"
        }else if locationstr.contains( "fr")
        {
            message = "Les styles de cellule actuels seront perdus. C'est bien?"
            yes = "oui"
            no = "non"
        }else if locationstr.contains( "zh"){
            
            message = "当前的单元格样式将丢失。这样好吗？"
            yes = "是"
            no = "否"
        }else if locationstr.contains( "de")
        {
            
            message = "Aktuelle Zellstile gehen verloren. Ist das richtig?"
            yes = "ja"
            no = "nein"
        }else if locationstr.contains( "it")
        {
            
            message = "Gli stili di cella correnti andranno persi. Va bene?"
            yes = "si"
            no = "no"
        }else if locationstr.contains( "ru")
        {
            
            message = "Текущие стили ячеек будут потеряны. Все в порядке?"
            yes = "да"
            no = "нет"
        }else if locationstr.contains("sv")
        {
            message = "Nuvarande cellstilar kommer att gå förlorade. Är det okej?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("da")
        {
            message = "Nuværende celleformater vil gå tabt. Er det okay?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("ar")
        {
            message = "ستفقد أنماط الخلية الحالية. هل هذا جيد؟"
            yes = "نعم"
            no = "لا"
            
        }else if locationstr.contains("es")
        {
            message = "Se perderán los estilos de celda actuales. ¿Está eso bien?"
            yes = "si"
            no = "no"
        }else{
            
        }
        
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: yes, style: .default, handler: { action in
            //reset all
            
            self.bgcolor.removeAll()
            self.cursor = String()
            self.tcolor.removeAll()
            self.textsize.removeAll()
            
            
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                for _ in 0..<self.content.count{
                    self.textsize.append(String(self.selectingSize))
                    self.bgcolor.append(self.selectingBgColor)
                    self.tcolor.append(self.selectingColor)
                }
                break
                
            default:
                for _ in 0..<self.content.count{
                    self.textsize.append(String(self.selectingSize))
                    self.bgcolor.append(self.selectingBgColor)
                    self.tcolor.append(self.selectingColor)
                }
                break
            }
            
            
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.cswLocation.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.customSizedHeight.removeAll()
            
            let r2 = UserDefaults.standard
            r2.set(appd.customSizedWidth, forKey: "NEW_CELL_WIDTH")
            r2.synchronize()
            
            let r3 = UserDefaults.standard
            r3.set(appd.cswLocation, forKey: "NEW_CELL_WIDTH_LOCATION")
            r3.synchronize()
            
            let r1 = UserDefaults.standard
            r1.set(appd.customSizedHeight, forKey: "NEW_CELL_HEIGHT")
            r1.synchronize()
            
            let r4 = UserDefaults.standard
            r4.set(appd.cshLocation, forKey: "NEW_CELL_HEIGHT_LOCATION")
            r4.synchronize()
            
            //if self.selectedSheet >= 0{
                self.saveAsLocalJson(filename: "csv_sheet1")
            //}
            
            DispatchQueue.main.async() {
                appd.collectionViewCellSizeChanged = 1
                self.myCollectionView.collectionViewLayout.invalidateLayout()
                self.myCollectionView.reloadData()
                appd.collectionViewCellSizeChanged = 0
            }

            self.customview2.removeFromSuperview()

        }))
        alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
        
        self.present(alert, animated: true)
        
        
        
        self.customview2.removeFromSuperview()
        
    }
    
    
    override func viewDidLoad() {
        hiddenTextField.becomeFirstResponder()
        menuButton.layer.borderWidth = 1.0
        myCollectionView.layer.borderWidth = 1.0
        myCollectionView.layer.borderColor = UIColor.gray.cgColor
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        fileTitle.text = ""
        super.viewDidLoad()

        columninNumber.removeAll()
        columninNumber.append("null")
        rowinNumber.removeAll()
        rowinNumber.append("null")
        
        //http://qiita.com/xa_un/items/814a5cd4472674640f58
        tag_int = appd.tag_int
        myCollectionView.delegate = self
        orientaion = "P"
        
        if appd.imported_xlsx_file_path == "" && isCSV == false{
            let pathDirectory = getRootDocumentsDirectory()
            let filePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent("initialXLSX.xlsx")
            let fileExists = FileManager.default.fileExists(atPath: filePath.path)
            isExcel = true
            if fileExists{
                appd.imported_xlsx_file_path=filePath.path
                //appd.sheetNames
                let icc = iCloudViewController()
                icc.readExcel(path: filePath.path)
                //let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
                //let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                //let url = serviceInstance.testSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
                //createxlsxSheet()
                
            }
            if !fileExists {
                print("File doesn't exist at path: \(filePath.path)")
                //loadinitialXLSX
                if let filePath2 = Bundle.main.path(forResource: "initialXLSX", ofType: "xlsx"){
                    do {
                        let icc = iCloudViewController()
                        icc.loadInitialXLSX(url: URL(fileURLWithPath: filePath2))
                        //                    appd.imported_xlsx_file_path=filePath.path
                        //                    icc.readExcel(path: filePath.path)
                    } catch {
                        print("Error reading file: \(error)")
                    }
                }
            }
        }
        
        //checkSheet
        let initialIdx = appd.sheetNameIds.first ?? "-1"
        isExcelSheetData(sheetIdx: Int(initialIdx)!)
        initSheetData()
        otherclass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        initExcelLocation()
        
        //https://stackoverflow.com/questions/31774006/how-to-get-height-of-keyboard
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
        
       
//        bannerview.isHidden = true
//        bannerview.delegate = self
//        bannerview.adUnitID = "ca-app-pub-5284441033171047/5452654189"
//        bannerview.rootViewController = self
//        bannerview.load(GADRequest())
        
        Thread.sleep(forTimeInterval: 0.5)
        let pointA = CGPoint.init(x: 600, y: 600)
        myCollectionView.setContentOffset(pointA, animated: true)
        myCollectionView.scrollToNextItem()
        
        localFileNames = appd.sheetNames //sheet1,sheet2
        FileCollectionView.reloadData()
        
        
        
        
        
        for idx in 0..<COLUMNSIZE {
            let letters = getExcelColumnName(columnNumber: idx)
            columnNames.append(letters)
        }
        
        //Finally calculate
        calculatormode_update_main()
        
        DispatchQueue.main.async() {
            appd.collectionViewCellSizeChanged = 1
            self.myCollectionView.collectionViewLayout.invalidateLayout()
            self.myCollectionView.reloadData()
        }
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        myCollectionView.addGestureRecognizer(doubleTapGesture)
    }
    
    @objc private func localSave(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let pathDirectory = getRootDocumentsDirectory()
        let overWrittenfilePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent("initialXLSX.xlsx")
        
        let overWritingfilePath = appd.imported_xlsx_file_path
        do {
            let fileManager = FileManager.default
            try fileManager.replaceItemAt(overWrittenfilePath, withItemAt: URL(fileURLWithPath:overWritingfilePath))
            print("File replaced successfully at path: \(overWrittenfilePath.path)")
            appd.imported_xlsx_file_path = overWrittenfilePath.path
        } catch {
            print("Error replacing file: \(error.localizedDescription)")
        }

    }
    
    //
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: myCollectionView)
        
        if let indexPath = myCollectionView.indexPathForItem(at: location) {
            print("Double-tapped cell at \(indexPath)")
            // Perform your double-tap action here
        }
        
        selection_bool = !selection_bool
        myCollectionView.reloadData()
    }
    
    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: myCollectionView)
        
        if let indexPath = myCollectionView.indexPathForItem(at: location) {
            print("Single-tapped cell at \(indexPath)")
            // Perform your single-tap action here
        }
    }
    
    func extractExcelCellReferences(from expression: String) -> [String] {
        // Define a regular expression for Excel cell references
        let regexPattern = "[A-Za-z]+\\d+"
        
        // Compile the regex pattern
        let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
        
        // Extract matches from the input expression
        let matches = regex.matches(in: expression, options: [], range: NSRange(location: 0, length: expression.utf16.count))
        
        // Convert matches into strings
        return matches.compactMap { match in
            if let range = Range(match.range, in: expression) {
                return String(expression[range])
            }
            return nil
        }
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let cell = gesture.view as? CustomCollectionViewCell,
                //touched cell index not selected index
                let indexPath = myCollectionView.indexPath(for: cell)
        else { return }
        let startRow = indexPath.section
        let startCol = indexPath.item
        let lIndex = locationInExcel.firstIndex(of: label.text ?? "") ?? -1
        
       
        //existing content and it starts with "=" TODO
//        if lIndex != -1 && content[lIndex].hasPrefix("="){
//            let startContent = content[lIndex]
//            var extractedReferences = extractExcelCellReferences(from: startContent)
//            
//            switch gesture.state {
//            case .began:
//                print("start")
//                // Change background color to indicate dragging started
//                cell.label2.backgroundColor = UIColor.systemBlue // Change the color dynamically
//                break
//                
//            case .changed:
//                let locationCG = gesture.location(in: myCollectionView)
//                if let newIndexPath = myCollectionView.indexPathForItem(at: locationCG) {
//                    if let cell2 = myCollectionView.cellForItem(at: newIndexPath) as? CustomCollectionViewCell {
//                        cell2.label2.backgroundColor = UIColor.systemBlue
//                    }
//                }
//                break
//                
//            case .ended, .cancelled:
//                let locationCG = gesture.location(in: myCollectionView)
//                if let newIndexPath = myCollectionView.indexPathForItem(at: locationCG) {
//                    if let cell2 = myCollectionView.cellForItem(at: newIndexPath) as? CustomCollectionViewCell {
//                        cell2.label2.backgroundColor = UIColor.green
//                    }
//                    let newRow = newIndexPath.section
//                    let newCol = newIndexPath.item
//                    //horizontal scroll
//                    let colHeader = 1
//                    if newRow == startRow && (newCol > startCol){
//                        for i in 1...newCol-startCol {
//                            var incrementedRowCells = incrementCells(in: extractedReferences, isIncrementRow: false, incrementVolume: i)
//                            
//                            incrementedRowCells = incrementedRowCells.map { cell in
//                                let midpoint = cell.index(cell.startIndex, offsetBy: cell.count / 2)
//                                return cell[..<midpoint] + "_" + cell[midpoint...]
//                            }
//                            print(extractedReferences)
//                            print(incrementedRowCells)
//                            
//                            let targetlocation = String(startCol+i) + "," + String(startRow)
//                            var newcontent = startContent
//                            for (j,each) in extractedReferences.enumerated() {
//                                newcontent = newcontent.replacingOccurrences(of: each, with: incrementedRowCells[j])
//                            }
//                            
//                            newcontent = newcontent.replacingOccurrences(of: "_", with: "")
//                            //input(defaultstr: targetlocation, defaultelement: newcontent)
//                            
//                            //save
//                            saveuserF()
//                            saveuserD()
//                        
//                            selection_bool = false
//                        }
//                        break
//                    }
//                    
//                    
//                    //vertical scroll
//                    if newCol == startCol && (newRow > startRow){
//                        for i in 1...newRow-startRow {
//                            var incrementedRowCells = incrementCells(in: extractedReferences, isIncrementRow: true, incrementVolume: i)
//                            
//                            incrementedRowCells = incrementedRowCells.map { cell in
//                                let midpoint = cell.index(cell.startIndex, offsetBy: cell.count / 2)
//                                return cell[..<midpoint] + "_" + cell[midpoint...]
//                            }
//                            print(extractedReferences)
//                            print(incrementedRowCells)
//                            
//                            let targetlocation = String(startCol) + "," + String(startRow+i)
//                            var newcontent = startContent
//                            for (j,each) in extractedReferences.enumerated() {
//                                newcontent = newcontent.replacingOccurrences(of: each, with: incrementedRowCells[j])
//                            }
//                            
//                            newcontent = newcontent.replacingOccurrences(of: "_", with: "")
//                            //input(defaultstr: targetlocation, defaultelement: newcontent)
//                            
//                            //save
//                            saveuserF()
//                            saveuserD()
//                           
//                            selection_bool = false
//                        }
//                        break
//                    }
//                }
//                // Restore the original background color
//                print("ended")
//                myCollectionView.reloadData()
//                break
//                
//                // Optionally handle reordering logic here (see earlier example)
//                
//            default:
//                break
//            }
//            return
//        }
        
        switch gesture.state {
        case .began:
            print("start")
            tempRangeSelected = []
            tempRangeSelected.append(indexPath)
            // Change background color to indicate dragging started
            cell.label2.backgroundColor = UIColor.systemBlue // Change the color dynamically
            let locationCG = gesture.location(in: myCollectionView)
            if let newIndexPath = myCollectionView.indexPathForItem(at: locationCG) {
                if let cell2 = myCollectionView.cellForItem(at: newIndexPath) as? CustomCollectionViewCell {
                    //cell2.label2.layer.borderWidth = 1.0
                    cell2.label2.backgroundColor = UIColor.systemBlue
                    if (tempRangeSelected.firstIndex(of: newIndexPath) == nil){
                        tempRangeSelected.append(newIndexPath)
                    }
                }
            }
            break
            
        case .changed:
            let locationCG = gesture.location(in: myCollectionView)
            if let newIndexPath = myCollectionView.indexPathForItem(at: locationCG) {
                if let cell2 = myCollectionView.cellForItem(at: newIndexPath) as? CustomCollectionViewCell {
                    //cell2.label2.layer.borderWidth = 1.0
                    cell2.label2.backgroundColor = UIColor.systemBlue
                    if (tempRangeSelected.firstIndex(of: newIndexPath) == nil){
                        tempRangeSelected.append(newIndexPath)
                    }
                }
            }
            break
            
        case .ended, .cancelled:
            let locationCG = gesture.location(in: myCollectionView)
            if let newIndexPath = myCollectionView.indexPathForItem(at: locationCG) {
                tempRangeSelected.append(newIndexPath)
            }
            print("selected",tempRangeSelected)
            // Restore the original background color
            print("ended")
            panGestureShow2()
            
            //myCollectionView.reloadData()
            break
            
            // Optionally handle reordering logic here (see earlier example)
            
        default:
            break
        }
        
//        }
    }
    
    func panGestureShow2() {
        
        if customview2 != nil{
            
            customview2.removeFromSuperview()
        }
        
        switch tag_int {
        case 0:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 180,height: 370))
            break
        case 1:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 180,height: 370))
            break
        case 2:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 180,height: 370))
            break
        case 3:
            customview2 = Customview2(frame: CGRect(x:5,y:10, width: 180,height: 370))
            break
        case 4:
            customview2 = Customview2(frame: CGRect(x:5,y:200, width: 180,height: 370))
            break
        case 5:
            customview2 = Customview2(frame: CGRect(x:5,y:190, width: 180,height: 370))
            break
            
            
            
            
            
        default:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 180,height: 370))
            break
            
        }
        
        
        
        
        customview2.layer.borderWidth = 1
        
        customview2.layer.cornerRadius = 8;
        
        
        customview2.layer.borderColor = UIColor.black.cgColor
        
        
        customview2.export.isHidden = true
        
        customview2.calcAll.isHidden = true
        customview2.back.addTarget(self, action: #selector(ViewController.back2(_:)), for: UIControl.Event.touchUpInside)
        
        customview2.localLoad.isHidden = true
        customview2.localSave.isHidden = true
        customview2.reset.isHidden = true
        //copy file to local
        customview2.deleteSheet.isHidden = true
//        customview2.deletebutton.isHidden = true
        customview2.addNewSheet.isHidden = true
        customview2.resetStyling.isHidden = true
        //customview2.deletebutton.isHidden = true
        //customview2.deletebutton.addTarget(self, action: #selector(clearSelectedCellContent), for: UIControl.Event.touchUpInside)
        
        customview2.emailButton.isHidden = true
//        customview2.columnButton.isHidden = true
        
        customview2.deletebutton.addTarget(self, action: #selector(clearSelectedCellContent), for: UIControl.Event.touchUpInside)
        
        customview2.rowButton.addTarget(self, action: #selector(rowDeleteOperation), for: UIControl.Event.touchUpInside)
        
        customview2.insertRow.addTarget(self, action: #selector(rowInsertOperation), for: UIControl.Event.touchUpInside)
        
        customview2.columnButton.addTarget(self, action: #selector(columnInsertOperation), for: UIControl.Event.touchUpInside)
        
        customview2.deleteColumn.addTarget(self, action: #selector(columnDeleteOperation), for: UIControl.Event.touchUpInside)
        
        
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        customview2.xlsxSheetExportOniCloudDrive.titleLabel?.numberOfLines = 0
        customview2.xlsxSheetExportOniCloudDrive.titleLabel?.lineBreakMode = .byWordWrapping
        
        customview2.xlsxSheetExportOniCloudDrive.titleLabel?.textAlignment = .center
        if locationstr.contains( "ja")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("iCloudに保存", for: .normal)
            
        }else if locationstr.contains( "fr")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Exporter \nvers iCloud", for: .normal)
            
            customview2.deletebutton.setTitle("Sauvegarder \nlocalement", for: .normal)
            customview2.deletebutton.setTitle("Supprimer", for: .normal)
            
        }else if locationstr.contains( "zh"){
            customview2.xlsxSheetExportOniCloudDrive.setTitle("导出到iCloud", for: .normal)
            
        }else if locationstr.contains( "de")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("In iCloud \nexportieren", for: .normal)
            customview2.deletebutton.setTitle("Lokal speichern", for: .normal)
            customview2.deletebutton.setTitle("Löschen", for: .normal)
            
        }else if locationstr.contains( "it")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Esporta \nsu iCloud", for: .normal)
            
        }else if locationstr.contains( "ru")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Экспорт \nв iCloud", for: .normal)
            
            
        }else if locationstr.contains("sv")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Exportera \ntill iCloud", for: .normal)
            
        }else if locationstr.contains("da")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Eksporter \ntil iCloud", for: .normal)
            
        }else if locationstr.contains("ar")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("تصدير إلى iCloud", for: .normal)
            
        }else if locationstr.contains("es")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Exportar \na iCloud", for: .normal)
            
        }
        customview2.xlsxSheetExportOniCloudDrive.isHidden = true
        
        self.view.addSubview(customview2)
    }
    
    @objc func rowDeleteOperation(){
        //print(tempRangeSelected)
        var rowItems = [Int]()
        var old = [String]()
        var new = [String]()
        for (i,each) in tempRangeSelected.enumerated(){
            let colInt = each.item
            let rowInt = each.section
            if !rowItems.contains(rowInt){
                rowItems.append(rowInt)
            }
        }
        print("rowIntNew",rowItems)
        excelRowsDelete(rowRange: rowItems)
        tempRangeSelected = []
    }
    
    @objc func rowInsertOperation(){
        var rowItems = [Int]()
        var old = [String]()
        var new = [String]()
        for (i,each) in tempRangeSelected.enumerated(){
            let colInt = each.item
            let rowInt = each.section
            if !rowItems.contains(rowInt){
                rowItems.append(rowInt)
            }
        }
        print("rowIntNew",rowItems)
        excelRowsAdd(rowRange: rowItems)
        tempRangeSelected = []
    }

    
    @objc func columnInsertOperation(){
        var colItems = [Int]()
        var new = [String]()
        for (i,each) in tempRangeSelected.enumerated(){
            let colInt = each.item
            let rowInt = each.section
            if !colItems.contains(colInt){
                colItems.append(colInt)
            }
        }
        print("colIntNew",colItems)
        excelColsAdd(colRange:colItems)
        tempRangeSelected = []
    }
    
    @objc func columnDeleteOperation(){
        var colItems = [Int]()
        var new = [String]()
        for (i,each) in tempRangeSelected.enumerated(){
            let colInt = each.item
            let rowInt = each.section
            if !colItems.contains(colInt){
                colItems.append(colInt)
            }
        }
        print("colIntNew",colItems)
        excelColsDelete(colRange:colItems)
        tempRangeSelected = []
    }
    
    @objc func clearSelectedCellContent(){
        var excelIndice = [String]()
        for (i,each) in tempRangeSelected.enumerated() {
            let column = each.item
            let row = each.section
            let j = location.firstIndex(of: String(column)+","+String(row))
            if !isExcel{
                print("saved")
                saveAsLocalJson(filename: "csv_sheet1")
            }
            
            //excel
            changeaffected.removeAll()
            
            //data input
            if j != nil{
                excelIndice.append(locationInExcel[j!])
            }
            
            if j != nil && location.count > j!{
                location.remove(at:j!)
                locationInExcel.remove(at:j!)
                content.remove(at:j!)
                tcolor.remove(at:j!)
                textsize.remove(at:j!)
                bgcolor.remove(at:j!)
            }
            
            let k = f_location.firstIndex(of: String(column)+","+String(row))
            if k != nil && f_calculated.count > k!{
                f_calculated.remove(at:k!)
                f_location_alphabet.remove(at:k!)
                f_location.remove(at:k!)
            }
        }
           
//        inputBalk(src: " ", idx: String(column)+","+String(row), excelIdx: locationInExcel[j!])
        if excelIndice.count > 0{
            excelEntryBulk(srcString: " ", cellId: excelIndice[0], bka:excelIndice)
        }
     
        calculatormode_update_main()
        myCollectionView.reloadData()
    }
    
    // Function to increment the row of an Excel-style cell reference by a given volume
    func incrementRow(for cell: String, incrementVolume: Int) -> String {
        let parsedCol = ExcelHelper().alphabetOnlyString(text:cell)
        let rowNumber = ExcelHelper().numberOnlyString(text: cell)
        return parsedCol + String((Int(rowNumber) ?? 0)+incrementVolume)
    }

    // Function to increment the column of an Excel-style cell reference by a given volume
    func incrementColumn(for cell: String, incrementVolume: Int) -> String {
        let parsedCol = ExcelHelper().alphabetOnlyString(text:cell)
        let rowNumber = ExcelHelper().numberOnlyString(text: cell)
        // Convert the column letters to an integer, increment, and convert back to letters
        let incrementedColumn = incrementColumnLetters(parsedCol, incrementVolume: incrementVolume)
        return incrementedColumn + rowNumber
    }

    // Function to handle column incrementation by a given volume (e.g., "A" -> "B", "Z" -> "AA", etc.)
    func incrementColumnLetters(_ column: String, incrementVolume: Int) -> String {
        let parsedIntCol = ExcelHelper().columnToInt(ExcelHelper().alphabetOnlyString(text:column)) ?? 0
        let letters = GetExcelColumnName(columnNumber: parsedIntCol+incrementVolume)
        let number = ExcelHelper().numberOnlyString(text: column)
        return letters+number
    }

    // Function to increment an array of cell references by a given volume, either in rows or columns
    func incrementCells(in cells: [String], isIncrementRow: Bool, incrementVolume: Int) -> [String] {
        return cells.map { cell in
            if isIncrementRow {
                return incrementRow(for: cell, incrementVolume: incrementVolume)
            } else {
                return incrementColumn(for: cell, incrementVolume: incrementVolume)
            }
        }
    }


    
    //the end of viewdidload
//    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
//        bannerview.isHidden = false
//      print("bannerViewDidReceiveAd")
//    }
//
//    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
//        bannerview.isHidden = true
//      print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
//    }
    
    func getRootDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func initExcelLocation(){
        //updating locationInExcel(is content already loaded at here?)
        locationInExcel.removeAll()
        for i in 0..<location.count{
            let colStr = location[i].components(separatedBy:",").first
            if let colInt = Int(colStr ?? ""), let rowStr = location[i].components(separatedBy:",").last{
                let column = getExcelColumnName(columnNumber: colInt)
                locationInExcel.append(column + rowStr)
            }
        }
    }
    
    
    func initString() {
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        COLUMNSIZE = appd.DEFAULT_COLUMN_NUMBER
        ROWSIZE = appd.DEFAULT_ROW_NUMBER
        
        
        let appheight = UserDefaults.standard
        appheight.set(COLUMNSIZE, forKey: "NEWCsize")
        appheight.synchronize()
        
        let appheight2 = UserDefaults.standard
        appheight2.set(ROWSIZE, forKey: "NEWRsize")
        appheight2.synchronize()
        
    }
    
    
    
    @objc func restore()
    {
        //It's now restoreing.
        (content,location,COLUMNSIZE,ROWSIZE) = otherclass.outValues()
        myCollectionView.reloadData()
        
    }
    
    
    
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        print("return")
        textField.resignFirstResponder()
        return true
    }
    
    
    //http://stackoverflow.com/questions/35782218/swift-how-to-make-mfmailcomposeviewcontroller-disappear
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    
    //http://stackoverflow.com/questions/32851720/how-to-remove-special-characters-from-string-in-swift-2
    func removeSpecialCharsFromString(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("1234567890-.")
        return String(text.filter {okayChars.contains($0) })
    }
    
    func removeSpecialCharsFromStringOprators(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("MaximnSuAvg%^×÷")
        return String(text.filter {okayChars.contains($0) })
    }
    
    
    @objc func movetosearchreplace(_ sender:UIButton){
        show3()
    }
    
    
    //http://code-examples-ja.hateblo.jp/entry/2016/09/21/Swift3
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
    
    
    @IBAction func show2(_ sender: AnyObject) {
        
        if customview2 != nil{
            
            customview2.removeFromSuperview()
        }
        
        switch tag_int {
        case 0:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 285,height: 288))
            break
        case 1:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 285,height: 288))
            break
        case 2:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 285,height: 288))
            break
        case 3:
            customview2 = Customview2(frame: CGRect(x:5,y:10, width: 285,height: 288))
            break
        case 4:
            customview2 = Customview2(frame: CGRect(x:5,y:200, width: 285,height: 288))
            break
        case 5:
            customview2 = Customview2(frame: CGRect(x:5,y:190, width: 285,height: 288))
            break
            
            
            
            
            
        default:
            customview2 = Customview2(frame: CGRect(x:5,y:150, width: 285,height: 288))
            break
            
        }
        
        
        
        
        customview2.layer.borderWidth = 1
        
        customview2.layer.cornerRadius = 8;
        
        
        customview2.layer.borderColor = UIColor.black.cgColor
        
        
        customview2.export.addTarget(self, action: #selector(ViewController.movetosearchreplace(_:)), for: UIControl.Event.touchUpInside)
        
        customview2.calcAll.addTarget(self, action: #selector(fontediting), for: UIControl.Event.touchUpInside)
        
        customview2.back.addTarget(self, action: #selector(ViewController.back2(_:)), for: UIControl.Event.touchUpInside)
        
        customview2.localLoad.addTarget(self, action: #selector(ViewController.icloudview(_:)), for: UIControl.Event.touchUpInside)
        
        customview2.reset.addTarget(self, action: #selector(ViewController.resetSheet(_:)), for: UIControl.Event.touchUpInside)
        
        customview2.resetStyling.addTarget(self, action: #selector(ViewController.goSettings), for: UIControl.Event.touchUpInside)
        
        customview2.emailButton.addTarget(self, action: #selector(ViewController.excelEmail), for: UIControl.Event.touchUpInside)
        
        customview2.localSave.addTarget(self, action: #selector(ViewController.loadCreditview), for: UIControl.Event.touchUpInside)
        
        customview2.deleteSheet.addTarget(self, action: #selector(ViewController.deletexlsxSheet), for: UIControl.Event.touchUpInside)
        
        customview2.deletebutton.isHidden = true
        customview2.columnButton.isHidden = true
        customview2.rowButton.isHidden = true
        customview2.insertRow.isHidden = true
        customview2.deleteColumn.isHidden = true
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        customview2.xlsxSheetExportOniCloudDrive.titleLabel?.numberOfLines = 0
        customview2.xlsxSheetExportOniCloudDrive.titleLabel?.lineBreakMode = .byWordWrapping
        
        customview2.xlsxSheetExportOniCloudDrive.titleLabel?.textAlignment = .center
        if locationstr.contains( "ja")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("iCloudに保存", for: .normal)
            
        }else if locationstr.contains( "fr"){
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Exporter \nvers iCloud", for: .normal)
            
        }else if locationstr.contains( "zh"){
            customview2.xlsxSheetExportOniCloudDrive.setTitle("导出到iCloud", for: .normal)
            
        }else if locationstr.contains( "de"){
            customview2.xlsxSheetExportOniCloudDrive.setTitle("In iCloud \nexportieren", for: .normal)
            
        }else if locationstr.contains( "it")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Esporta \nsu iCloud", for: .normal)
            
        }else if locationstr.contains( "ru")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Экспорт \nв iCloud", for: .normal)
            
            
        }else if locationstr.contains("sv")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Exportera \ntill iCloud", for: .normal)
            
        }else if locationstr.contains("da")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Eksporter \ntil iCloud", for: .normal)
            
        }else if locationstr.contains("ar")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("تصدير إلى iCloud", for: .normal)
            
        }else if locationstr.contains("es")
        {
            customview2.xlsxSheetExportOniCloudDrive.setTitle("Exportar \na iCloud", for: .normal)
            
        }
        customview2.xlsxSheetExportOniCloudDrive.addTarget(self, action: #selector(ViewController.saveOniCloudAction), for: UIControl.Event.touchUpInside)
        customview2.addNewSheet.addTarget(self, action: #selector(createxlsxSheet), for: UIControl.Event.touchUpInside)
        
        self.view.addSubview(customview2)
    }
    
    @objc func saveOniCloudAction(){
        
        var message = "Do you save this file on iCloud?"
        var yes = "OK"
        var no = "No"
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if locationstr.contains( "ja")
        {
            message = "このファイルをiCloudに保存しますか？"
            yes = "はい"
            no = "いいえ"
        }else if locationstr.contains( "fr")
        {
            message = "Enregistrez-vous ce fichier sur iCloud ?"
            yes = "oui"
            no = "non"
        }else if locationstr.contains( "zh"){
            
            message = "您是否将此文件保存在 iCloud 上？"
            yes = "是"
            no = "否"
        }else if locationstr.contains( "de")
        {
            
            message = "Speichern Sie diese Datei in iCloud?"
            yes = "ja"
            no = "nein"
        }else if locationstr.contains( "it")
        {
            
            message = "Salvi questo file su iCloud?"
            yes = "si"
            no = "no"
        }else if locationstr.contains( "ru")
        {
            
            message = "Вы сохраняете этот файл в iCloud?"
            yes = "да"
            no = "нет"
        }else if locationstr.contains("da")
        {
            message = "Gemmer du denne fil på iCloud?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("es")
        {
            message = "¿Guardas este archivo en iCloud?"
            yes = "si"
            no = "no"
        }else{
            
        }
        
        
        let alert = UIAlertController(title: "FILE NAME", message: message, preferredStyle: .alert)
        alert.addTextField()
        
        if isExcel{
            //
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let url = serviceInstance.writeXlsxEmail(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
            
            alert.textFields?[0].text = (url?.pathExtension == "xlsx") ? url?.lastPathComponent : "can't find an xlsx file"
            
            let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
                let name = alert.textFields![0].text
                if name!.count > 0 {
                    if let url2 = url{
                        self.uploadFileToICloud(url: url2,filename: name!)
                    }
                }
            })
            
            alert.addAction(confirmAction)
            alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
            
            self.present(alert, animated: true)
            self.customview2.removeFromSuperview()
        }
        
        if isCSV{
            //
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let url = serviceInstance.writeXlsxEmail(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
            //csv
            //save temp content
            var result = content
            for idx in 0..<f_calculated.count{
                if let l_idx = location.index(of: f_location[idx]){
                    result[l_idx] = f_calculated[idx]
                }
            }
            csvexport(result: result)
            
            alert.textFields?[0].text = "tempCSV.csv"
            
            let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
                let name = alert.textFields![0].text
                if name!.count > 0 {
                    self.uploadFileToICloudCSV(filename: name!)
                }
            })
            
            alert.addAction(confirmAction)
            alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
            
            self.present(alert, animated: true)
            self.customview2.removeFromSuperview()
        }
    }
    
    //create excel todo
    @objc func createxlsxSheet(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        excelAddSheet()
        if customview2 != nil{
            customview2.removeFromSuperview()
        }
    }
    
    @objc func deletexlsxSheet(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        excelDeleteSheet()
        if customview2 != nil{
            customview2.removeFromSuperview()
        }
    }
    
    @objc func filterEmptyContent(){
        var filterContent = [String]()
        var filterLocation = [String]()
        var filterFontSize = [String]()
        var filterFontColor = [String]()
        var filterBgColor = [String]()
        for i in 0..<content.count {
            let check = content[i].replacingOccurrences(of: " ", with: "")
            if check.count != 0{
                filterContent.append(content[i])
                filterLocation.append(location[i])
                
                filterFontSize.append(textsize[i])
                
                
                
                filterFontColor.append(tcolor[i])
                filterBgColor.append(bgcolor[i])
            }
            
        }
        
        content = filterContent
        location = filterLocation
        textsize = filterFontSize
        tcolor = filterFontColor
        bgcolor = filterBgColor
    }
    @objc func saveAsLocalJson(filename:String) {
        filterEmptyContent()
        
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let today: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        let date = dateFormatter.string(from: today)
        
        
        let dict : [String:Any] = ["filename": filename,
                                   "date": date,
                                   "content": content,
                                   "location": location,
                                   "fontsize": textsize,
                                   "fontcolor": tcolor,
                                   "bgcolor": bgcolor,
                                   "rowsize": ROWSIZE,
                                   "columnsize": COLUMNSIZE,
                                   "customcellWidth":appDelegate.customSizedWidth,
                                   "customcellHeight": appDelegate.customSizedHeight,
                                   "ccwLocation": appDelegate.cswLocation,
                                   "cchLocation": appDelegate.cshLocation,
                                   "formulaResult":f_calculated,
                                   "inputOrder":input_order]
        
        
        let test = ReadWriteJSON()
        test.saveJsonFile(source: dict, title: filename)
        
        
        
    }
    
    @objc func deleteLocalJson(filename:String) {
        
        let test = ReadWriteJSON()
        test.deleteJsonFile(title: filename)
    }
    
    @objc func saveJSONAction(_ sender:UIButton){
        
        var message = "Do you save this file?"
        var yes = "OK"
        var no = "No"
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if locationstr.contains( "ja")
        {
            message = "このファイルを保存しますか？"
            yes = "はい"
            no = "いいえ"
        }else if locationstr.contains( "fr")
        {
            message = "Enregistrez-vous ce fichier?"
            yes = "oui"
            no = "non"
        }else if locationstr.contains( "zh"){
            
            message = "您保存此文件吗？"
            yes = "是"
            no = "否"
        }else if locationstr.contains( "de")
        {
            
            message = "Speichern Sie diese Datei?"
            yes = "ja"
            no = "nein"
        }else if locationstr.contains( "it")
        {
            
            message = "Salvi questo file?"
            yes = "si"
            no = "no"
        }else if locationstr.contains( "ru")
        {
            
            message = "Вы сохраняете этот файл?"
            yes = "да"
            no = "нет"
        }else if locationstr.contains("sv")
        {
            message = "Sparar du den här filen?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("da")
        {
            message = "Gemmer du denne fil?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("ar")
        {
            message = "هل تحفظ هذا الملف؟"
            yes = "نعم"
            no = "لا"
            
        }else if locationstr.contains("es")
        {
            message = "¿Guarda este archivo?"
            yes = "si"
            no = "no"
        }else{
            
        }
        
        
        let alert = UIAlertController(title: "FILE NAME", message: message, preferredStyle: .alert)
        alert.addTextField()
        
        if selectedSheet >= localFileName.startIndex && selectedSheet < localFileName.endIndex{
            alert.textFields![0].text = localFileName[selectedSheet]
        }
        
        let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
            let name = alert.textFields![0].text
            
            if name!.count > 0 {
                self.saveAsLocalJson(filename:name!.replacingOccurrences(of: " ", with: "_"))
            }
            
            let test = ReadWriteJSON()
            let temp = test.titleJsonFile()
            
            self.localFileName = temp.reversed()
            
            self.FileCollectionView.reloadData()
            
            self.customview2.removeFromSuperview()
            
            self.fileTitle.text = name!.replacingOccurrences(of: " ", with: "_")
            
        })
        
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
        
        self.present(alert, animated: true)
        
        
        
        self.customview2.removeFromSuperview()
        
    }
    
    @objc func deleteJSONAction(_ sender:UIButton){
        
        var message = "Do you delete this file?"
        var yes = "OK"
        var no = "No"
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if locationstr.contains( "ja")
        {
            message = "このファイルを削除しますか？"
            yes = "はい"
            no = "いいえ"
        }else if locationstr.contains( "fr")
        {
            message = "Supprimez-vous ce fichier?"
            yes = "oui"
            no = "non"
        }else if locationstr.contains( "zh"){
            
            message = "是否删除此文件？"
            yes = "是"
            no = "否"
        }else if locationstr.contains( "de")
        {
            
            message = "Löschen Sie diese Datei?"
            yes = "ja"
            no = "nein"
        }else if locationstr.contains( "it")
        {
            
            message = "Elimina questo file?"
            yes = "si"
            no = "no"
        }else if locationstr.contains( "ru")
        {
            
            message = "Вы удаляете этот файл?"
            yes = "да"
            no = "нет"
        }else if locationstr.contains("sv")
        {
            message = "Tar du bort den här filen?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("da")
        {
            message = "Slet du denne fil?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("ar")
        {
            message = "هل تحذف هذا الملف؟"
            yes = "نعم"
            no = "لا"
            
        }else if locationstr.contains("es")
        {
            message = "¿Eliminas este archivo?"
            yes = "si"
            no = "no"
        }else{
            
        }
        
        
        let alert = UIAlertController(title: "FILE NAME", message: message, preferredStyle: .alert)
        alert.addTextField()
        
        
//        if  selectedSheet >= 0 && localFileName.count > 0 {
        if selectedSheet >= localFileName.startIndex && selectedSheet < localFileName.endIndex{
            alert.textFields![0].text = localFileName[selectedSheet]
        }
        
        let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
            let name = alert.textFields![0].text
            
            self.deleteLocalJson(filename:name!)
            
            let test = ReadWriteJSON()
            let temp = test.titleJsonFile()
            
            self.localFileName = temp.reversed()
            
            self.FileCollectionView.reloadData()
            
            self.customview2.removeFromSuperview()
            
            self.fileTitle.text = ""
            
        })
        
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
        
        self.present(alert, animated: true)
        
        
        
        self.customview2.removeFromSuperview()
        
    }
    
    @objc func fontediting() {
        
        if Fview != nil {
            Fview.removeFromSuperview()
        }
        
        if customview2 != nil{
            
            customview2.removeFromSuperview()
        }
        
        
        Fview = formatview(frame: CGRect(x:10,y:30, width: 300,height: 150))
        
        
        
        Fview .layer.borderWidth = 1
        
        Fview .layer.cornerRadius = 8;
        
        Fview .layer.borderColor = UIColor.black.cgColor
        
        Fview .color5.layer.borderWidth = 1
        
        Fview .color5.layer.borderColor = UIColor.black.cgColor
        
        Fview.formatBackButton.addTarget(self, action: #selector(ViewController.formatbackaction(_:)), for: UIControl.Event.touchUpInside)
        
        Fview.color1.addTarget(self, action: #selector(ViewController.c1(_:)), for: UIControl.Event.touchUpInside)
        Fview.color2.addTarget(self, action: #selector(ViewController.c2(_:)), for: UIControl.Event.touchUpInside)
        
        Fview.color5.addTarget(self, action: #selector(ViewController.c5(_:)), for: UIControl.Event.touchUpInside)
        Fview.color6.addTarget(self, action: #selector(ViewController.c6(_:)), for: UIControl.Event.touchUpInside)
        Fview.color7.addTarget(self, action: #selector(ViewController.c7(_:)), for: UIControl.Event.touchUpInside)
        Fview.color8.addTarget(self, action: #selector(ViewController.c8(_:)), for: UIControl.Event.touchUpInside)
        Fview.color9.addTarget(self, action: #selector(ViewController.c9(_:)), for: UIControl.Event.touchUpInside)
        Fview.color10.addTarget(self, action: #selector(ViewController.c10(_:)), for: UIControl.Event.touchUpInside)
        Fview.color11.addTarget(self, action: #selector(ViewController.c11(_:)), for: UIControl.Event.touchUpInside)
        Fview.color12.addTarget(self, action: #selector(ViewController.c12(_:)), for: UIControl.Event.touchUpInside)
        Fview.color13.addTarget(self, action: #selector(ViewController.c13(_:)), for: UIControl.Event.touchUpInside)
        Fview.color14.addTarget(self, action: #selector(ViewController.c14(_:)), for: UIControl.Event.touchUpInside)
        Fview.color15.addTarget(self, action: #selector(ViewController.c15(_:)), for: UIControl.Event.touchUpInside)
        Fview.sizeslider.addTarget(self, action: #selector(ViewController.sliderValueChanged(_:)), for: UIControl.Event.valueChanged)
        
        self.view.addSubview(Fview)
        
        
        
    }
    
    @objc func sliderValueChanged(_ sender:Any){
        let rounded = Int(floor(Fview.sizeslider.value))
        Fview.sizelabel.text = String(rounded)
        
        let IP :String = currentindexstr
        
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            if location.index(of: IP) == nil{
                content.append("")
                location.append(IP)
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
            }
            break
            
        default:
            if location.index(of: IP) == nil{
                content.append("")
                location.append(IP)
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
            }
            break
        }
        
        
        
        let i = location.index(of: IP)
        textsize[i!] = String(rounded)
        selectingSize = rounded
        
        myCollectionView.reloadData()
        
        saveuserF()
        saveuserD()
        
    }
    
    func numberviewopen() {
        
        if numberview != nil {
            numberview.removeFromSuperview()
        }
        
        
        //if UIDevice.current.orientation.isLandscape{
        var width = "width"
        var height = "height"
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if locationstr.contains( "ja")
        {
            width = "横幅"
            height = "縦幅"
        }else if locationstr.contains( "fr")
        {
            width = "largeur"
            height = "la taille"
        }else if locationstr.contains( "zh"){
            width = "宽度"
            height = "高度"
        }else if locationstr.contains( "de")
        {
            width = "Breite"
            height = "Höhe"
        }else if locationstr.contains( "it")
        {
            
            width = "altezza"
            height = "larghezza"
        }else if locationstr.contains( "ru")
        {
            width = "ширина"
            height = "высота"
        }
        
        numberview = numberkey(frame: CGRect(x:40,y:100, width: 210,height: 145))
        
        numberview.layer.borderWidth = 1
        
        numberview.layer.cornerRadius = 8;
        
        numberview.layer.borderColor = UIColor.black.cgColor
        
        numberview.inputfield.delegate = self
        
        //
        numberview.back.addTarget(self, action: #selector(ViewController.backactionnum(_:)), for: UIControl.Event.touchUpInside)
        
        numberview.plusOne.addTarget(self, action: #selector(ViewController.plusAction(_:)), for: UIControl.Event.touchUpInside)
        
        
        numberview.minusOne.addTarget(self, action: #selector(ViewController.minusAction(_:)), for: UIControl.Event.touchUpInside)
        
        numberview.width_height_selector.setTitle(width, forSegmentAt: 0)
        numberview.width_height_selector.setTitle(height, forSegmentAt: 1)
        
        
        self.view.addSubview(numberview)
    }
    
    
    
    
    //*********************//
    
    
    @objc func formatbackaction(_ sender:UIButton)
    {
        
        
        
        //
        
        //if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex {
            saveAsLocalJson(filename: "csv_sheet1")
        //}
        
        Fview.removeFromSuperview()
    }
    
    @objc func c1(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=water"
            selectingColor="water"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=water"
            selectingBgColor="water"
        }
        
        fonteditmode()
        
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c2(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=brown"
            selectingColor="brown"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=brown"
            selectingBgColor="brown"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c5(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=white"
            selectingColor="white"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=white"
            selectingBgColor="white"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c6(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=blue"
            selectingColor="blue"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=blue"
            selectingBgColor="blue"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c7(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=magenta"
            selectingColor="magenta"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=magenta"
            selectingBgColor="magenta"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c8(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=red"
            selectingColor="red"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=red"
            selectingBgColor="red"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c9(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=orange"
            selectingColor="orange"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=orange"
            selectingBgColor="orange"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c10(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=black"
            selectingColor="black"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=black"
            selectingBgColor="black"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c11(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=green"
            selectingColor="green"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=green"
            selectingBgColor="green"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c12(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=gray"
            selectingColor="gray"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=gray"
            selectingBgColor="gray"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c13(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=purple"
            selectingColor="purple"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=purple"
            selectingBgColor="purple"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c14(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=yellow"
            selectingColor="yellow"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=yellow"
            selectingBgColor="yellow"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c15(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=lightGray"
            selectingColor="lightGray"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=lightGray"
            selectingBgColor="lightGray"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    
    
    //**********************BUTTONS*************************************************//
    
    @objc func backactionnum(_ sender:UIButton)
    {
        let indexItem = Int(currentindex.item)
        let indexSection = Int(currentindex.section)
        let temp_value = numberview.inputfield.text!
        let value = temp_value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.collectionViewCellSizeChanged = 1
        
        if Double(value) != nil{
            
            
            if numberview.width_height_selector.selectedSegmentIndex == 0{
                
                if Double(value)! < 20.0{
                    
                }else{
                    if appd.cswLocation_temp.contains(indexItem){
                        let idx = appd.cswLocation_temp.firstIndex(of: indexItem)
                        appd.customSizedWidth_temp[idx!] = Double(value)!
                    }
                    appd.customSizedWidth_temp.append(Double(value)!)
                    appd.cswLocation_temp.append(indexItem)
                    
                }
                
            }else if numberview.width_height_selector.selectedSegmentIndex == 1{
                
                
                if Double(value)! < 20.0{
                    
                }else {
                    if appd.cshLocation_temp.contains(indexSection){
                        let idx = appd.cshLocation_temp.firstIndex(of: indexSection)
                        appd.customSizedHeight_temp[idx!] = Double(value)!
                    }
                    appd.customSizedHeight_temp.append(Double(value)!)
                    appd.cshLocation_temp.append(indexSection)
                                    
                    
                }
                
                
                
                
            }
            
        }
        
        
        
        numberview.removeFromSuperview()
        
        
        print("go to file view")
        //print("selectedSheet",Int(appd.sheetNameIds[selectedSheet]))
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "LoadingFileController" ) as! LoadingFileController //Landscape
        if isExcel{
            targetViewController.idx = Int(appd.sheetNameIds[selectedSheet])
        }
        targetViewController.modalPresentationStyle = .fullScreen
        // Present the target view controller after LoadingFileController's view has appeared
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        
    }
    
    
    
    @objc func resetAll (){
        //reset all
        self.location.removeAll()
        self.content.removeAll()
        self.bgcolor.removeAll()
        self.cursor = String()
        self.tcolor.removeAll()
        self.textsize.removeAll()
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.cswLocation.removeAll()
        appd.cshLocation.removeAll()
        appd.customSizedWidth.removeAll()
        appd.customSizedHeight.removeAll()
        appd.sheetNames = [String]()
        saveuserD()
        saveuserF()
        
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "LoadingViewController" )//Landscape
        targetViewController.modalPresentationStyle = .fullScreen
        self.present( targetViewController, animated: true, completion: nil)
        
    }
    
    @objc func plusAction(_ sender:UIButton)
    {
        let indexItem = Int(currentindex.item)
        let indexSection = Int(currentindex.section)
        var plus = 0
        let horrible = UserDefaults.standard
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if indexSection == 0{
            
            (location,content) = otherclass.horribleMethod4Col(tempArray: location,tempArrayContent: content, colInt: indexItem)
            
            
            plus = COLUMNSIZE+1
            
            horrible.set(plus, forKey: "NEWCsize")
            horrible.synchronize()
            
            
            
        }else if indexItem == 0{
            
            (location,content) = otherclass.horribleMethod4Row(tempArray: location,tempArrayContent: content, rowInt: indexSection)
            
            
            plus = ROWSIZE+1
            
            
            horrible.set(plus, forKey: "NEWRsize")
            horrible.synchronize()
            
            
        }
        
        
        
        
        
        horrible.set(location, forKey: "NEWTMLOCATION")
        horrible.synchronize()
        
        
        horrible.set(content, forKey: "NEWTMCONTENT")
        horrible.synchronize()
        
//        if selectedSheet >= 0{
        //if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex{
            saveAsLocalJson(filename: "csv_sheet1")
        //}
        
        
        DispatchQueue.main.async() {
            appd.collectionViewCellSizeChanged = 1
            self.myCollectionView.collectionViewLayout.invalidateLayout()
            self.myCollectionView.reloadData()
        }
        
        
        
    }
    
    @objc func minusAction(_ sender:UIButton)
    {
        let indexItem = Int(currentindex.item)
        let indexSection = Int(currentindex.section)
        var minus = 0
        let horrible = UserDefaults.standard
        
        if indexSection == 0{
            
            (location,content) = otherclass.horribleMethod4ColMinus(tempArray: location,tempArrayContent:content , colInt: indexItem)
            
            
            minus = COLUMNSIZE-1
            horrible.set(minus, forKey: "NEWCsize")
            horrible.synchronize()
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.cswLocation.contains(indexItem){
                let idx = appd.cswLocation.index(of: indexItem)
                appd.cswLocation.remove(at: idx!)
                appd.customSizedWidth.remove(at: idx!)
            }
            
            //
            
            let r2 = UserDefaults.standard
            r2.set(appd.customSizedWidth, forKey: "NEW_CELL_WIDTH")
            r2.synchronize()
            
            let r3 = UserDefaults.standard
            r3.set(appd.cswLocation, forKey: "NEW_CELL_WIDTH_LOCATION")
            r3.synchronize()
            
            
            
            
        }else if indexItem == 0{
            
            (location,content) = otherclass.horribleMethod4RowMinus(tempArray: location,tempArrayContent: content, rowInt: indexSection)
            
            
            minus = ROWSIZE-1
            
            horrible.set(minus, forKey: "NEWRsize")
            horrible.synchronize()
            
            
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.cshLocation.contains(indexSection){
                let idx = appd.cshLocation.index(of: indexSection)
                appd.cshLocation.remove(at: idx!)
                appd.customSizedHeight.remove(at: idx!)
            }
            
            //
            let r2 = UserDefaults.standard
            r2.set(appd.customSizedHeight, forKey: "NEW_CELL_HEIGHT")
            r2.synchronize()
            
            let r3 = UserDefaults.standard
            r3.set(appd.cshLocation, forKey: "NEW_CELL_HEIGHT_LOCATION")
            r3.synchronize()
            
            
            
        }
        
        
        
        horrible.set(location, forKey: "NEWTMLOCATION")
        horrible.synchronize()
        
        
        horrible.set(content, forKey: "NEWTMCONTENT")
        horrible.synchronize()
        
        
//        if selectedSheet >= 0{
        //if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex{
            saveAsLocalJson(filename: "csv_sheet1")
        //}
        
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        DispatchQueue.main.async() {
            appd.collectionViewCellSizeChanged = 1
            self.myCollectionView.collectionViewLayout.invalidateLayout()
            self.myCollectionView.reloadData()
        }
        
        
    }
    
    @objc func autoComplete(src:String)->String{
        let dotdot = src.replacingOccurrences(of: "↓", with: "").replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "...", with: "…")
        
        let ary = dotdot.components(separatedBy: "…")
        if ary.count > 1{
            if Int(ary[0]) != nil && Int(ary[1]) != nil{
                if (Int(ary[0]) != nil) && Int(ary[1])! > 0{
                    var product = ""
                    var cnt = Int(ary[0])!
                    for i in 0 ..< Int(ary[1])!{
                        product = product + String(cnt) + ":"
                        cnt += 1
                    }
                    
                    if down_bool == true {
                        product = product + "↓"
                    }else if right_bool == true {
                        product = product + "→"
                    }else{
                        product = product + "↓"
                    }
                    return product
                }else{
                    return ""
                }
            }else{
                return ""
            }
        }else{
            return ""
        }
    }
    
    //copy
    @objc func copyText(){
        
//        currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
//        if location.contains(currentindexstr){
//            let i = location.index(of: currentindexstr)
//
//            datainputview.stringbox.text = datainputview.stringbox.text  + content[i!]
//
//            //new functionality
//            let ary = datainputview.stringbox.text.components(separatedBy: "+")
//            for i in 0..<COLUMNSIZE {
//                for j in 0..<ary.count {
//                    if ary[j].contains(getExcelColumnName(columnNumber:COLUMNSIZE-i)){
//                        let item = ary[j].replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
//                        let row = numberOnlyString(text: item)
//
//                        if row.count > 0{
//                            let original = getExcelColumnName(columnNumber:COLUMNSIZE-i)
//                            let change = item.replacingOccurrences(of: original, with: String(COLUMNSIZE-i) + ",")
//                            changeaffected.append(change)
//                        }
//                    }
//                }
//            }
//        }
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.collectionViewCellSizeChanged = 0
        let pasteboard = UIPasteboard.general
        pasteboard.string = ""
        
        
        
        otherclass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        
        
        var element :String = datainputview.stringbox.text!
        datainputview.stringbox.text = ""
        
        //add more complicated functionality
        if autoComplete(src: element).count > 1 {
            element = autoComplete(src: element)
        }
        
        
        let IP :String = currentindexstr   //String(currentindex!.item) + String(currentindex!.section)
        let t_item = IP.components(separatedBy: ",")[0]
        let t_section = IP.components(separatedBy: ",")[1]
        
        let IP_i = Int(t_item)!
        var IP_s = Int(t_section)!
        var checkInt = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "")
        
        var collocation = -1
        if element.contains("→"){
            let checkAlpha = alphabetOnlyString(text: element)
            if columnNames.index(of: checkAlpha) != nil {
                collocation = columnNames.index(of: checkAlpha)!
                checkInt = checkInt.replacingOccurrences(of: checkAlpha, with: String(collocation))
            }
        }
        
        if element.contains(" ") && down_bool == true || element.contains(" ") && left_bool == true || element.contains(" ") && up_bool == true || element.contains(" ") && right_bool == true{
            
            element = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "").replacingOccurrences(of: "↑", with: "").replacingOccurrences(of: "←", with: "")
            //20200502
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                //storeInput(IPd: IP, elementd: element) implement this function in iphone too? i dont know it is a good idea
                var padAry = element.components(separatedBy: " ")
                
                if down_bool {
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i) + "," + String(IP_s+idx)
                        if IP_s+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                        }
                    }
                }
                else if right_bool{
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i+idx) + "," + String(IP_s)
                        if IP_i+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i+idx)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                        }
                    }
                }
                
                break
                
            case .pad:
                
                var padAry = element.components(separatedBy: " ")
                
                if down_bool {
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i) + "," + String(IP_s+idx)
                        if IP_s+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                        }
                    }
                }
                else if up_bool {
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i) + "," + String(IP_s-idx)
                        if IP_s-idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            
                        }
                    }
                }
                else if left_bool{
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i-idx) + "," + String(IP_s)
                        if IP_i-idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            
                        }
                    }
                }
                else if right_bool{
                    var modulo = 0
                    for idx in 0..<padAry.count{
                        modulo = idx % 8
                        if modulo == 0 {
                            IP_s += 1
                        }
                        let IPl = String(IP_i+modulo + 1) + "," + String(IP_s)
                     
                        if IP_i+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i+idx)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                        }
                    }
                }
                
                break
                
            default:
                storeInput(IPd: IP, elementd: element)
                break
            }
            pasteboard.string = clipboard
        }
        
        stringboxText = ""
        myCollectionView.reloadData()
        
    }
    
    @objc func terminate(){
        if pastemode == false && getRefmode == false {
            datainputview.stringbox.resignFirstResponder()
            for subview in self.view.subviews.filter({ $0 is Datainputview }){
                subview.removeFromSuperview()
            }
            datainputview = nil
        }
    }
    
    @objc func closeHview(){
        if Hintview != nil{
            Hintview.removeFromSuperview()
        }
    }
    
    
    
    func noInternet(sheetIdx:Int){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let sheet1Json = ReadWriteJSON()
        let temp = sheet1Json.titleJsonFile()
        old_localFileNames = temp.reversed()
        
        if old_localFileNames.count > 0{
            sheet1Json.readJsonFIle(title: old_localFileNames[sheetIdx])
            content = sheet1Json.content
            location = sheet1Json.location
            textsize = sheet1Json.fontsize
            bgcolor = sheet1Json.bgcolor
            tcolor = sheet1Json.fontcolor
            COLUMNSIZE = sheet1Json.columnsize
            ROWSIZE = sheet1Json.rowsize
            appd.customSizedWidth = sheet1Json.customcellWidth
            appd.customSizedHeight = sheet1Json.customcellHeight
            appd.cswLocation = sheet1Json.ccwLocation
            appd.cshLocation = sheet1Json.cchLocation
            
        }
        
        //EXCEL FORMULA TRANSFORMATION STARTS
        //PI(),EXP(1)
        content = excel_fomula_transformation(src:content)
        
        //Taking out Empty Cells
        filterEmptyContent()
        
        //SOME THING WENT WRONG RESET PROCESS STARTS
        if location.count != content.count {
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            location.removeAll()
            content.removeAll()
            
            bgcolor.removeAll()
            cursor = String()
            tcolor.removeAll()
            textsize.removeAll()
            
            initString()
        }
        
        if location.count != bgcolor.count || location.count != tcolor.count || location.count != textsize.count{
            bgcolor.removeAll()
            textsize.removeAll()
            tcolor.removeAll()
            
            
            
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                for _ in 0..<location.count{
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                }
                break
                
            default:
                for _ in 0..<location.count{
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                }
                break
            }
        }
        
        //FOR COLLECTIONVIEW
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") != nil) {
            appd.customSizedWidth = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") != nil) {
            appd.customSizedHeight = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") != nil) {
            appd.cswLocation = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") != nil) {
            appd.cshLocation = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            COLUMNSIZE = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
        }
        
        if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
            ROWSIZE = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
        }
    }
    
    @objc func input(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.collectionViewCellSizeChanged = 0
        let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
        appd.wsSheetIndex = sheetIdx!
        print("wsSheetIndex",appd.wsSheetIndex)
        
        let pasteboard = UIPasteboard.general
        pasteboard.string = ""
        
        otherclass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        
        var element :String = datainputview.stringbox.text!
        let original_element = element
        datainputview.stringbox.text = ""
        
        //add more complicated functionality
        if autoComplete(src: element).count > 1 {
            element = autoComplete(src: element)
        }
        
        
        let IP :String = currentindexstr   //String(currentindex!.item) + String(currentindex!.section)
        let t_item = IP.components(separatedBy: ",")[0]
        let t_section = IP.components(separatedBy: ",")[1]
        
        let IP_i = Int(t_item)!
        let IP_s = Int(t_section)!
        var checkInput = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "")
        
        var collocation = -1
        if element.contains("→"){
            let checkAlpha = alphabetOnlyString(text: element)
            if columnNames.index(of: checkAlpha) != nil {
                collocation = columnNames.index(of: checkAlpha)!
                checkInput = checkInput.replacingOccurrences(of: checkAlpha, with: String(collocation))
            }
        }
        
        if element.contains(":") && down_bool == true || element.contains(":") && left_bool == true || element.contains(":") && up_bool == true || element.contains(":") && right_bool == true{
            
            element = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "").replacingOccurrences(of: "↑", with: "").replacingOccurrences(of: "←", with: "")
            //20200502
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                //storeInput(IPd: IP, elementd: element) implement this function in iphone too? i dont know it is a good idea
                let padAry = element.components(separatedBy: ":")
                
                if down_bool {
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i) + "," + String(IP_s+idx)
                        if IP_s+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s+idx))
                        }
                    }
                    datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
                    down_bool = false
                }
                
                if right_bool{
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i+idx) + "," + String(IP_s)
                        if IP_i+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i+idx)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s))
                        }
                    }
                    datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
                    right_bool = false
                }
                break
                
                
            case .pad:
                let padAry = element.components(separatedBy: ":")
                
                if down_bool {
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i) + "," + String(IP_s+idx)
                        if IP_s+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s+idx))
                        }
                    }
                    datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
                    down_bool = false
                }
                
                
                
                if right_bool{
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i+idx) + "," + String(IP_s)
                        if IP_i+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i+idx)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s))
                        }
                    }
                    datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
                    right_bool = false
                }
                
                break
                
            default:
                storeInput(IPd: IP, elementd: element)
                let alphabet = getExcelColumnName(columnNumber: IP_i)
                excelEntry(srcString: element, cellId: alphabet + String(IP_s))
                break
            }
            pasteboard.string = clipboard
            //It makes better UX
            changeaffected.removeAll()
            let currentUpdate = String(currentindex.item) + "," + String(currentindex.section)
            changeaffected.append(currentUpdate)
            
            stringboxText = element
            return
        }
        
        
        //it take care of empty string
        storeInput(IPd: IP, elementd: element)
        
        //if element.hasPrefix("="){
        f_content.removeAll()
        f_calculated.removeAll()
        f_location_alphabet.removeAll()
        f_location.removeAll()
        calculatormode_update_main()

        
        //always excel, no such thing as csv case
        if element == ""{
            //TODO want to modify xml
            element = " "
        }
        excelEntry(srcString: element,cellId: getIndexlabel())
        
        //It makes better UX
        changeaffected.removeAll()
        let currentUpdate = String(currentindex.item) + "," + String(currentindex.section)
        changeaffected.append(currentUpdate)
        stringboxText = element
        return
    }
    
    func excelEntry(srcString:String,cellId:String)
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        var element = srcString
        if isExcel && srcString.count > 0{
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            //excel work
            var numFmt = 0
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //https://p-space.jp/index.php/development/open-xml-sdk/84-openxmlsdk8
            //TODO save as a formula
            //if !element.hasPrefix("="){//mathematical expression doesnt support in Excel
                //update sheet1,or2,or3 or xml each data entry
                //date object
                //hh:mm case MAX 24*60*60[s]
                let hhmm = element.components(separatedBy: ":")
                if hhmm.count == 2, let hh = Decimal(string: hhmm[0]), let mm = Decimal(string: hhmm[1]) {
                    // Ensure hhmm array has two elements and both are successfully converted to Decimal
                    
                    // Calculate total number of seconds in a day
                    let max = Decimal(24) * Decimal(60) * Decimal(60)
                    
                    // Calculate total number of seconds from HH:MM format
                    let divid = hh * Decimal(60) * Decimal(60) + mm * Decimal(60)
                    
                    // Calculate the fraction representing the time
                    element = String(describing: divid / max)
                    numFmt = 20
                }
                
                //date conversion
                let dateString = element
                // Create a DateFormatter to parse the date string
                let dateFormatter = DateFormatter()
                
                // Create a DateFormatter to parse the date string
                let dateFormatter2 = DateFormatter()
                dateFormatter2.dateFormat = "MM/dd/yyyy"
                
                // Parse the date string
                if let date = dateFormatter2.date(from: dateString) {
                    // Define the Excel base date (January 1, 1900)
                    let excelBaseDate = DateComponents(year: 1899, month: 12, day: 30)
                    let calendar = Calendar(identifier: .gregorian)
                    let excelBaseDateTimeInterval = calendar.date(from: excelBaseDate)!.timeIntervalSinceReferenceDate
                    
                    // Calculate the time interval between the given date and the Excel base date
                    let dateTimeInterval = date.timeIntervalSinceReferenceDate
                    let excelDateTimeInterval = dateTimeInterval - excelBaseDateTimeInterval
                    
                    // Calculate the corresponding serial number
                    let serialNumber = Int(excelDateTimeInterval / (24 * 60 * 60))
                    
                    print("Excel serial number:", serialNumber) // Output: 39448
                    element = String(serialNumber)
                    numFmt = 14
                    
                }
                
            if element == " "{
                element = ""
            }
            let f_idx = f_location_alphabet.firstIndex(of: getIndexlabelForExcel())
            var calculated = ""
            if (f_idx != nil){
                calculated = f_calculated[f_idx!]
            }
            _ = serviceInstance.testUpdateStringBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, input: element, cellIdxString: cellId,numFmt:numFmt,calculated: calculated)
            
            if (f_idx != nil), element.hasPrefix("=") && f_calculated.count>f_idx! && f_content.count > f_idx! && f_calculated[f_idx!] != "error"{
                _ = serviceInstance.testUpdateStringBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, input: f_calculated[f_idx!], cellIdxString: cellId,numFmt:numFmt, fString: element.replacingOccurrences(of: "=", with: ""))
            }
        }
        
    }
    
    func excelEntryBulk(srcString:String,cellId:String,bka:[String] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        var element = srcString
        if isExcel && srcString.count > 0{
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            //excel work
            var numFmt = 0
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //https://p-space.jp/index.php/development/open-xml-sdk/84-openxmlsdk8
            //TODO save as a formula
            //if !element.hasPrefix("="){//mathematical expression doesnt support in Excel
                //update sheet1,or2,or3 or xml each data entry
                //date object
                //hh:mm case MAX 24*60*60[s]
                let hhmm = element.components(separatedBy: ":")
                if hhmm.count == 2, let hh = Decimal(string: hhmm[0]), let mm = Decimal(string: hhmm[1]) {
                    // Ensure hhmm array has two elements and both are successfully converted to Decimal
                    
                    // Calculate total number of seconds in a day
                    let max = Decimal(24) * Decimal(60) * Decimal(60)
                    
                    // Calculate total number of seconds from HH:MM format
                    let divid = hh * Decimal(60) * Decimal(60) + mm * Decimal(60)
                    
                    // Calculate the fraction representing the time
                    element = String(describing: divid / max)
                    numFmt = 20
                }
                
                //date conversion
                let dateString = element
                // Create a DateFormatter to parse the date string
                let dateFormatter = DateFormatter()
                
                // Create a DateFormatter to parse the date string
                let dateFormatter2 = DateFormatter()
                dateFormatter2.dateFormat = "MM/dd/yyyy"
                
                // Parse the date string
                if let date = dateFormatter2.date(from: dateString) {
                    // Define the Excel base date (January 1, 1900)
                    let excelBaseDate = DateComponents(year: 1899, month: 12, day: 30)
                    let calendar = Calendar(identifier: .gregorian)
                    let excelBaseDateTimeInterval = calendar.date(from: excelBaseDate)!.timeIntervalSinceReferenceDate
                    
                    // Calculate the time interval between the given date and the Excel base date
                    let dateTimeInterval = date.timeIntervalSinceReferenceDate
                    let excelDateTimeInterval = dateTimeInterval - excelBaseDateTimeInterval
                    
                    // Calculate the corresponding serial number
                    let serialNumber = Int(excelDateTimeInterval / (24 * 60 * 60))
                    
                    print("Excel serial number:", serialNumber) // Output: 39448
                    element = String(serialNumber)
                    numFmt = 14
                    
                }
                
            if element == " "{
                element = ""
            }
            _ = serviceInstance.testUpdateStringBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, input: element, cellIdxString: cellId,numFmt:numFmt,bulkAry: bka)
            
            if let f_idx = f_location_alphabet.firstIndex(of: cellId), element.hasPrefix("=") && f_calculated.count>f_idx && f_content.count > f_idx && f_calculated[f_idx] != "error"{
                _ = serviceInstance.testUpdateStringBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, input: f_calculated[f_idx], cellIdxString: cellId,numFmt:numFmt, fString: element.replacingOccurrences(of: "=", with: ""))
            }
        }
    }
    
    //rowDeleteOperation
    func excelRowsDelete(rowRange:[Int] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
            _ = serviceInstance.testRowsDeleteBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, rowRange: rowRange, locationInExcel: locationInExcel)
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
        
            print("go to file view")
           
           
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
//                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex)
                // Assuming `collectionView` is your UICollectionView instance
                if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                    customLayout.resetCellAttrsDictionaryItemZindex()
                    customLayout.prepare()
                    customLayout.invalidateLayout() // Call the method on the instance
                    self.myCollectionView.reloadData()
                } else {
                    print("CustomCollectionViewLayout is not set as the current layout")
                }
                
            }
        }
    }
    
    //excelRowsAdd
    func excelRowsAdd(rowRange:[Int] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
            _ = serviceInstance.testRowsAddBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, rowRange: rowRange, locationInExcel: locationInExcel)
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
        
            print("go to file view")
           
           
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
                self.loadExcelSheet(idx: appd.wsSheetIndex)
                // Assuming `collectionView` is your UICollectionView instance
                if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                    customLayout.resetCellAttrsDictionaryItemZindex()
                    customLayout.prepare()
                    customLayout.invalidateLayout() // Call the method on the instance
                    self.myCollectionView.reloadData()
                } else {
                    print("CustomCollectionViewLayout is not set as the current layout")
                }
                
            }
        }
    }
    
    //excelRowsAdd
    func excelColsAdd(colRange:[Int] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
            _ = serviceInstance.testColsAddBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, colRange: colRange, locationInExcel: locationInExcel)
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
        
            print("go to file view")
           
           
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
//                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex)
                // Assuming `collectionView` is your UICollectionView instance
                if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                    customLayout.resetCellAttrsDictionaryItemZindex()
                    customLayout.prepare()
                    customLayout.invalidateLayout() // Call the method on the instance
                    self.myCollectionView.reloadData()
                } else {
                    print("CustomCollectionViewLayout is not set as the current layout")
                }
                
            }
        }
    }
    
    func excelColsDelete(colRange:[Int] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
            _ = serviceInstance.testColsDeleteBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, colRange: colRange, locationInExcel: locationInExcel)
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
        
            print("go to file view")
           
           
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
//                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex)
                // Assuming `collectionView` is your UICollectionView instance
                if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                    customLayout.resetCellAttrsDictionaryItemZindex()
                    customLayout.prepare()
                    customLayout.invalidateLayout() // Call the method on the instance
                    self.myCollectionView.reloadData()
                } else {
                    print("CustomCollectionViewLayout is not set as the current layout")
                }
            }
        }
    }
    
    func excelAddSheet(filename:String = "")
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            var message = "Set a sheet name."
            var yes = "OK"
            var no = "No"
            let locationstr = (NSLocale.preferredLanguages[0] as String?)!
            
            
            let alert = UIAlertController(title: "SHEET NAME", message: message, preferredStyle: .alert)
            alert.addTextField()
            
            
            let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
                var name = alert.textFields?[0].text
                
                let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
                
                //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
                let today: Date = Date()
                let dateFormatter: DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
                if name == "" || (self.localFileNames.firstIndex(of: name!) != nil){
                    name = dateFormatter.string(from: today)
                }
                _ = serviceInstance.testAddSheetBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path,filename: name!)
                
                //sheet cell get touched
                appd.collectionViewCellSizeChanged = 1
                appd.cswLocation.removeAll()
                appd.customSizedWidth.removeAll()
                appd.cshLocation.removeAll()
                appd.customSizedHeight.removeAll()
                
                
                self.f_calculated.removeAll()
                self.f_content.removeAll()
                self.content.removeAll()
                self.location.removeAll()
                self.f_location_alphabet.removeAll()
                
                //print("sheet changed",indexPath.item)
                self.stringboxText = ""
            
                print("go to file view")
               
               
                
                // Present the target view controller after LoadingFileController's view has appeared
                DispatchQueue.main.async {
    //                self.present(targetViewController, animated: true, completion: nil)
                    self.loadExcelSheet(idx: appd.wsSheetIndex)
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                        self.FileCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                    
                }
                
               
                self.customview2.removeFromSuperview()
                
            })
            
            alert.addAction(confirmAction)
            alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func excelDeleteSheet(filename:String = "")
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            var message = "Set a sheet name."
            var yes = "OK"
            var no = "No"
            let locationstr = (NSLocale.preferredLanguages[0] as String?)!
            
            
            let alert = UIAlertController(title: "SHEET NAME", message: message, preferredStyle: .alert)
            alert.addTextField()
            
            alert.textFields?[0].text = localFileNames[currentFileNameCollectionViewIdx.item]
            
            let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
                
                var name = alert.textFields?[0].text
                
                let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
                
                //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
                let today: Date = Date()
                let dateFormatter: DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
                if name == ""{
                    name = dateFormatter.string(from: today)
                }
                print("before",appd.sheetNameIds)
                print("before",appd.sheetNames)
                _ = serviceInstance.testDeleteSheetBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path,sheetname: name!)
                
                //sheet cell get touched
                appd.collectionViewCellSizeChanged = 1
                appd.cswLocation.removeAll()
                appd.customSizedWidth.removeAll()
                appd.cshLocation.removeAll()
                appd.customSizedHeight.removeAll()
                
                self.f_calculated.removeAll()
                self.f_content.removeAll()
                self.content.removeAll()
                self.location.removeAll()
                self.f_location_alphabet.removeAll()
                
                //print("sheet changed",indexPath.item)
                self.stringboxText = ""
            
                print("go to file view")
                
                DispatchQueue.main.async {
                    appd.sheetNameIds.remove(at: Int(self.currentFileNameCollectionViewIdx.item))
                    appd.sheetNames.remove(at: Int(self.currentFileNameCollectionViewIdx.item))
                    appd.wsSheetIndex = Int(appd.sheetNameIds.first!)!
                    self.loadExcelSheet(idx: Int(appd.sheetNameIds.first!))
                    self.currentFileNameCollectionViewIdx = IndexPath(item: 0, section: 0)
                    self.FileCollectionView.reloadData()
                    self.myCollectionView.reloadData()
                    // Assuming `collectionView` is your UICollectionView instance
                }
               
                // Present the target view controller after LoadingFileController's view has appeared
                //self.customview2.removeFromSuperview()
                
            })
            
            alert.addAction(confirmAction)
            alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func storeInput(IPd:String, elementd:String)
    {
        if elementd.replacingOccurrences(of: " ", with: "").count > 0{
            if location.contains(IPd){
                let i = location.index(of: IPd)
                
                content[i!] = elementd
                location[i!] = IPd
                
                
            }else{
                content.append(elementd)
                location.append(IPd)
                
                switch UIDevice.current.userInterfaceIdiom {
                case .pad:
                    //updated
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                    break
                    
                default:
                    //updated
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                    break
                }
                
            }
        }else{
            if location.contains(IPd){
                if let i = location.index(of: IPd){
                    content.remove(at: i)
                    location.remove(at: i)
                    textsize.remove(at: i)
                    bgcolor.remove(at: i)
                    tcolor.remove(at: i)
                }
                
            }
        }
        
        //updating locationInExcel
        initExcelLocation()
    }
    
    func saveuserD() {
        
        let location1 = UserDefaults.standard
        location1.set(location, forKey: "NEWTMLOCATION")
        location1.synchronize()
        
        let content1 = UserDefaults.standard
        content1.set(content, forKey: "NEWTMCONTENT")
        content1.synchronize()
        
        let appheight = UserDefaults.standard
        appheight.set(COLUMNSIZE, forKey: "NEWCsize")
        appheight.synchronize()
        
        let appheight2 = UserDefaults.standard
        appheight2.set(ROWSIZE, forKey: "NEWRsize")
        appheight2.synchronize()
        
    }
    
    func alphabetOnlyString(text: String) -> String {
        let okayChars = Set("ABCDEFGHIJKLKMNOPQRSTUVWXYZ")
        return text.filter {okayChars.contains($0) }
    }
    
    func saveuserF(){
        
        
        
        let content2 = UserDefaults.standard
        content2.set(bgcolor, forKey: "NEWTMBGCOLOR")
        content2.synchronize()
        
        
        
        let content3 = UserDefaults.standard
        content3.set(tcolor, forKey: "NEWTMTCOLOR")
        content3.synchronize()
        
        let content4 = UserDefaults.standard
        content4.set(textsize, forKey: "NEWTMSIZE")
        content4.synchronize()
        
        
        
    }
    
    
    func show3() {
        
        if customview3 != nil{
            
            customview3.removeFromSuperview()
        }
        
        switch tag_int {
        case 0:
            customview3 = Customview3(frame: CGRect(x:5,y:50, width: 250,height: 155))
            break
        case 1:
            customview3 = Customview3(frame: CGRect(x:5,y:50, width: 250,height: 155))
            break
        case 2:
            customview3 = Customview3(frame: CGRect(x:5,y:50, width: 250,height: 155))
            break
        case 3:
            customview3 = Customview3(frame: CGRect(x:5,y:10, width: 250,height: 155))
            break
        case 4:
            customview3 = Customview3(frame: CGRect(x:5,y:200, width: 250,height: 155))
            break
        case 5:
            customview3 = Customview3(frame: CGRect(x:5,y:190, width: 250,height: 155))
            break
            
            
            
            
            
        default:
            customview3 = Customview3(frame: CGRect(x:5,y:150, width: 235,height: 155))
            break
            
        }
        
        
        
        
        customview3.layer.borderWidth = 1
        
        customview3.layer.cornerRadius = 8;
        
        
        customview3.layer.borderColor = UIColor.black.cgColor
        
        customview3.closebutton.addTarget(self, action: #selector(close), for: UIControl.Event.touchUpInside)
        
        
        //customview3.backbutton.addTarget(self, action: #selector(back2(_:)), for: UIControl.Event.touchUpInside)
        
        customview3.mcselector.addTarget(self, action: #selector(sliderValueChangedsearch), for: UIControl.Event.valueChanged)
        
        
        customview3.searchkbutton.addTarget(self, action: #selector(search), for: UIControl.Event.touchUpInside)
        
        customview3.replaceokbutton.addTarget(self, action: #selector(replace), for: UIControl.Event.touchUpInside)
        
        
        self.view.addSubview(customview3)
    }
    
    @objc func sliderValueChangedsearch(_ sender:Any){
        
        csview = !csview
    }
    
    @objc func search(){
        changeaffected.removeAll()
        search_text = customview3.searchfield.text!
        if customview3.mcselector.selectedSegmentIndex == 0 {
            for i in 0..<content.count {
                if content[i] == search_text{
                    changeaffected.append(location[i])
                }
            }
        }else {
            for i in 0..<content.count {
                if content[i].contains(search_text){
                    changeaffected.append(location[i])
                }
            }
        }
        saveuserD()
        myCollectionView.reloadData()
    }
    
    @objc func replace(){
        changeaffected.removeAll()
        search_text = customview3.searchfield.text!
        //complete
        if customview3.mcselector.selectedSegmentIndex == 0 {
            for i in 0..<content.count {
                if content[i] == search_text{
                    content[i] = customview3.replacefield.text!
                    changeaffected.append(location[i])
                    //TODO update sharedstring
                }
            }
        //partly
        }else {
            for i in 0..<content.count {
                if content[i].contains(search_text){
                    content[i] = content[i].replacingOccurrences(of: search_text, with: customview3.replacefield.text!)
                    changeaffected.append(location[i])
                    //TODO update sharedstring
                }
            }
        }
        
        myCollectionView.reloadData()
    }
    
    @objc func excel_sum_each(fidx:Int,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        if fc[fidx].hasPrefix("=SUM("){
            return ExcelHelper().excel_sum(src: fc[fidx], cursor:fl[fidx],fc: fc,fl: fl,fle: fle,fr: fr,lc: lc,ll:ll,lle: lle,lr: lr)
        }
        return "calculation error"
    }
    
    @objc func excel_average_each(fidx:Int,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        if fc[fidx].hasPrefix("=AVERAGE("){
            return ExcelHelper().excel_average(src: fc[fidx], cursor:fl[fidx],fc: fc,fl: fl,fle: fle,fr: fr,lc: lc,ll:ll,lle: lle,lr: lr)
        }
        return "calculation error"
    }
    
    @objc func excel_min_each(fidx:Int,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        if fc[fidx].hasPrefix("=MIN("){
            return ExcelHelper().excel_min(src: fc[fidx], cursor:fl[fidx],fc: fc,fl: fl,fle: fle,fr: fr,lc: lc,ll:ll,lle: lle,lr: lr)
        }
        return "calculation error"
    }
    
    @objc func excel_max_each(fidx:Int,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        if fc[fidx].hasPrefix("=MAX("){
            return ExcelHelper().excel_max(src: fc[fidx], cursor:fl[fidx],fc: fc,fl: fl,fle: fle,fr: fr,lc: lc,ll:ll,lle: lle,lr: lr)
        }
        return "calculation error"
    }
    
    @objc func calculatormode_update_main(){
        f_calculated.removeAll()
        f_location.removeAll()
        f_location_alphabet.removeAll()
      
        // these are all made of formula records
        var filteredContent: [String] = []
        var filteredLocation: [String] = []
        var filteredLocationInExcel: [String] = []
        var filteredResult: [String] = []
        //oter
        var literalContent: [String] = []
        var literalLocation: [String] = []
        var literalLocationInExcel: [String] = []
        var literalResult: [String] = []

        // Loop through the content array and extract items with "=" prefix
        for (index, item) in content.enumerated() {
            if item.hasPrefix("=") {
                filteredContent.append(item.replacingOccurrences(of: " ", with: ""))
                filteredLocation.append(location[index])
                filteredLocationInExcel.append(locationInExcel[index])
                filteredResult.append("")
            }
            if !item.hasPrefix("=") {
                literalContent.append(item)
                literalLocation.append(location[index])
                literalLocationInExcel.append(locationInExcel[index])
                if Double(item) != nil{
                    literalResult.append(item)
                }else{
                    literalResult.append("")
                }
            }
        }
        
        //Delete excel format PI()->pi EXP->e^
        //bug_check
        
        //topology sorting
        //content = ["=B1","10","=SUM(A1:B2)","Jack","=C3"],location["1,1","2,1","3,3","3,1",""]
    
        content = elsvFormulaExpression(src:content)
        
        
        var tempStr = "sin(PI/4)^2"//"3*(3^-1)"//"sin(PI/3+PI/6)"//"((sin3)^2+(cos3)^2)"//"1/((1-0)/(2-0))"//"((30+3)*23-3)/5-1"//30 3 + 23 3 - *  count the number of
        
        
        // Define the sorting criteria
        let indices = filteredContent.indices.sorted { lhs, rhs in
            func isExcelFunction(_ str: String) -> Bool {
                let keywords = ["=SUM(", "=AVERAGE(", "=MIN(", "=MAX("]
                return keywords.contains { str.contains($0) }
            }

            let lhsIsExcel = isExcelFunction(filteredContent[lhs])
            let rhsIsExcel = isExcelFunction(filteredContent[rhs])

            if lhsIsExcel != rhsIsExcel {
                return !lhsIsExcel
            }
            return filteredContent[lhs] < filteredContent[rhs]
        }
        
        // Reorder all arrays based on sorted indices
        filteredContent = indices.map { filteredContent[$0] }
        filteredLocation = indices.map { filteredLocation[$0] }
        filteredLocationInExcel = indices.map { filteredLocationInExcel[$0] }
        filteredResult = indices.map { filteredResult[$0] }
        
        //replaceing excelIndex with value if the value alredy exists
        for i in 0..<filteredContent.count {
            if !filteredContent[i].hasPrefix("=SUM(") && !filteredContent[i].hasPrefix("=AVERAGE(") && !filteredContent[i].hasPrefix("=MIN(") && !filteredContent[i].hasPrefix("=MAX("){
                for j in 0..<literalContent.count {
                    filteredContent[i] = filteredContent[i].replacingOccurrences(of: literalLocationInExcel[j], with: literalContent[j])
                }
            }
        }
        
        //home work topological sorting
        for k in 0..<filteredContent.count {
            for i in 0..<filteredContent.count {//final calculation loop is needed
                if  Double(filteredResult[i]) == nil{
                    
                    //1st ref
                    for j in 0..<filteredResult.count {
                        //update references in formulacontent
                        if !filteredContent[i].hasPrefix("=SUM(") && !filteredContent[i].hasPrefix("=AVERAGE(") &&
                            !filteredContent[i].hasPrefix("=MIN(") && !filteredContent[i].hasPrefix("=MAX(") {
                            if Double(filteredResult[j]) != nil{
                                //replace refrences
                                filteredContent[i] = filteredContent[i].replacingOccurrences(of: filteredLocationInExcel[j], with: filteredResult[j])
                            }
                        }
                    }
                    
                    tempStr = filteredContent[i].replacingOccurrences(of: "=", with: "")
                    let cs = CalculationService()
                    let result = cs.execute(expression:tempStr) ?? ""
                    if Double(result) != nil{
                        //http://swift-salaryman.com/round.php
                        let numberOfPlaces = 10.0
                        let multiplier = pow(10.0, numberOfPlaces)
                        var calculated = Double(result)! * multiplier
                        calculated = round(calculated) / multiplier
                        //print(calculated, "final answer")
                        filteredResult[i] = String(calculated)
                    }else{
                        filteredResult[i] = "calculation error"
                        switch filteredContent[i] {
                        case let content where content.contains("=SUM("):
                            let rltstr = excel_sum_each(fidx: i, fc: filteredContent, fl: filteredLocation, fle: filteredLocationInExcel, fr: filteredResult, lc: literalContent, ll: literalLocation, lle: literalLocationInExcel, lr: literalResult)
                            filteredResult[i] = rltstr

                        case let content where content.contains("=AVERAGE("):
                            let rltstr = excel_average_each(fidx: i, fc: filteredContent, fl: filteredLocation, fle: filteredLocationInExcel, fr: filteredResult, lc: literalContent, ll: literalLocation, lle: literalLocationInExcel, lr: literalResult)
                            filteredResult[i] = rltstr

                        case let content where content.contains("=MIN("):
                            let rltstr = excel_min_each(fidx: i, fc: filteredContent, fl: filteredLocation, fle: filteredLocationInExcel, fr: filteredResult, lc: literalContent, ll: literalLocation, lle: literalLocationInExcel, lr: literalResult)
                            filteredResult[i] = rltstr

                        case let content where content.contains("=MAX("):
                            let rltstr = excel_max_each(fidx: i, fc: filteredContent, fl: filteredLocation, fle: filteredLocationInExcel, fr: filteredResult, lc: literalContent, ll: literalLocation, lle: literalLocationInExcel, lr: literalResult)
                            filteredResult[i] = rltstr

                        default:
                            // If no condition is matched, you can handle it here if needed
                            break
                        }
                    }
                    
                    //2nd refs update
                    for j in 0..<filteredResult.count {
                        //update references in formulacontent
                        if !filteredContent[i].hasPrefix("=SUM(") && !filteredContent[i].hasPrefix("=AVERAGE(") &&
                            !filteredContent[i].hasPrefix("=MIN(") && !filteredContent[i].hasPrefix("=MAX(") {
                            if Double(filteredResult[j]) != nil{
                                //replace refrences
                                filteredContent[i] = filteredContent[i].replacingOccurrences(of: filteredLocationInExcel[j], with: filteredResult[j])
                            }
                        }
                    }
                }
                
                if filteredResult.allSatisfy({ Double($0) != nil }) {
                    print("All items are valid doubles.")
                    break
                }
                
            }//forloopend
        }//outerloopend
        
        //update
        f_calculated = filteredResult
        f_location = filteredLocation
        f_location_alphabet = filteredLocationInExcel
    }
    
    
    func extractCellIndices(from formula: String) -> [String] {
        // Define the regular expression pattern for cell references
        let pattern = "[A-Z]+[0-9]+"
        
        // Create a regular expression object
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        // Find matches in the input formula
        let matches = regex.matches(in: formula, options: [], range: NSRange(location: 0, length: formula.count))
        
        // Extract the matched strings
        let cellIndices = matches.map { match in
            (formula as NSString).substring(with: match.range)
        }
        
        return cellIndices
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
    
    func fonteditmode(){
        
        //let IP = IndexPath(row: currentindex.section, section: currentindex.section)
        let IP :String = currentindexstr
        
        if location.index(of: IP) != nil{
            
        }else{
            
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                content.append("")
                location.append(IP)
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
                break
                
            default:
                content.append("")
                location.append(IP)
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
                break
            }
            
        }
        
        let i = location.index(of: IP)
        
        if FONTEDIT.hasPrefix("bg="){
            
            let value = FONTEDIT.replacingOccurrences(of: "bg=", with: "").replacingOccurrences(of: " ", with: "")
            //            bgcolor.append(value.replacingOccurrences(of: " ", with: ""))
            
            bgcolor[i!] = value
            //print("bg",bgcolor[i!])
            
            
        }else if FONTEDIT.hasPrefix("color="){
            
            
            let value2 = FONTEDIT.replacingOccurrences(of: "color=", with: "").replacingOccurrences(of: " ", with: "")
            //            tcolor.append(value2.replacingOccurrences(of: " ", with: ""))
            tcolor[i!] = value2
            //print("font",tcolor[i!])
        }
        
        
        myCollectionView.reloadData()
        
        
    }
    
    
    func deleteall(){
        
        datainputview.stringbox.text=""
    }
    
    
    
    
    
    //https://stackoverflow.com/questions/38894031/swift-how-to-detect-orientation-changes
    
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape {
            
            orientaion = "L"
            SCREENSIZE = size.height
            SCREENSIZE_w = size.width
        } else {
            
            orientaion = "P"
            SCREENSIZE = size.height
            SCREENSIZE_w = size.width
        }
    }
    
    
    
    //https://stackoverflow.com/questions/44160111/what-is-the-equivalent-of-string-encoding-utf8-rawvalue-in-objective-c
    func swiftDataToString(someData:Data) -> String? {
        return String(data: someData, encoding: .utf8)
    }
    
    func swiftStringToData(someStr:String) ->Data? {
        return someStr.data(using: .utf8)
    }
    
    
    
    
    
    
    func getNumbers(array : [Double]) -> String {
        let stringArray = array.map{ String($0) }
        return stringArray.joined(separator: " ")
        
    }
    
    
    func cleanArray(InputArray:[String]) -> [String]{
        
        
        
        for i in 0..<InputArray.count {
            
            let tempStr = InputArray[i]
            
            if tempStr.count == 0{
                
                location[i] = "null"
                content[i] = "null"
                
            }
            
            
            
        }
        
        
        
        return InputArray
    }
    
    func cleanArray2(InputArray:[String]) -> [String]{
        
        for i in 0..<InputArray.count {
            
            let tempStr = InputArray[i]
            
            
        }
        
        return InputArray
    }
    
    func getIndexlabel() -> String{
        
        let column = getExcelColumnName(columnNumber: currentindex.item)
        let row = currentindex.section
        
        label.text = String(column)+String(row)
        
        if currentindex.item == 0{
            label.text = String(row)
        }
        
        if currentindex.section == 0{
            label.text = column
        }
        
        return String(column)+String(row)
    }
    
    func getIndexlabelForExcel(mode:Int=0) -> String{
        let column = getExcelColumnName(columnNumber: currentindex.item)
        let row = currentindex.section
        switch mode {
        case 0:
            return String(column)+String(row)
        case 1:
            return String(column)
        case 2:
            return String(row)
        default:
            return String(column)+String(row)
        }
    }
    
    
    
    //removeSpecialCharsFrom FinalProduct
    @objc func removeSpecialCharsFromFpString(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("1234567890-,.")
        return String(text.filter {okayChars.contains($0) })
    }
    
    
    //TextFormatting currency
    @objc func currencyFormat(tempStr:String)->String{
        
        var fp = ""
        var tempD = 0.0
        
        if let calculated = Double(tempStr){
            
            let formatter = NumberFormatter()
            formatter.locale = Locale.current // Change this to another locale if you want to force a specific locale, otherwise this is redundant as the current locale is the default already
            formatter.numberStyle = .currency
            tempD = Double(tempStr)!
            //tipAmountLabel.text = "Tip Amount: \(formattedTipAmount)"
            fp = formatter.string(from: tempD as NSNumber)!
            //removeCrrencySign
            fp = removeSpecialCharsFromFpString(fp)
            return fp
        }
        //https://stackoverflow.com/questions/41558832/how-to-format-a-double-into-currency-swift-3
        return tempStr
    }
    
    
    //FBAction
    func up2dateAction(){
        
        //Font location
        tcolor.removeAll()
        //        tlocation.removeAll()
        textsize.removeAll()
        //        sizelocation.removeAll()
        bgcolor.removeAll()
        //        bglocation.removeAll()
        
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            UIView.animate(withDuration: 0.9) {
                if self.KEYBOARDLOCATION < 1.0{
                    self.KEYBOARDLOCATION = keyboardHeight
                }
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if datainputview != nil{
            if pastemode == false && getRefmode == false{
                terminate()
            }
         
        }
        settingCellSelected = false
    }
    
    @objc func moveUp(){
        
        up_bool = !up_bool
        down_bool = false
        right_bool = false
        left_bool = false
        datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        datainputview.leftArrow.setImage(UIImage(named: "leftArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        if up_bool{
            datainputview.upArrow.setImage(UIImage(named: "upArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }else if !up_bool{
            datainputview.upArrow.setImage(UIImage(named: "upArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }
    
    @objc func moveDown(){
        down_bool = !down_bool
        up_bool = false
        right_bool = false
        left_bool = false
        datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        if down_bool {
            datainputview.downArrow.setImage(UIImage(named: "downArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "←", with: "").replacingOccurrences(of: "↑", with: "") + "↓"
        }else if !down_bool{
            datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "↓", with: "")
        }
        
    }
    @objc func imoveDown(){
        down_bool = !down_bool
        up_bool = false
        right_bool = false
        left_bool = false
        datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        if down_bool {
            datainputview.downArrow.setImage(UIImage(named: "downArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "←", with: "").replacingOccurrences(of: "↑", with: "") + "↓"
        }else if !down_bool{
            datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "↓", with: "")
        }
        
    }
    @objc func moveRight(){
        right_bool = !right_bool
        down_bool = false
        up_bool = false
        left_bool = false
        datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        if right_bool {
            datainputview.rightArrow.setImage(UIImage(named: "rightArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "↓", with: "").replacingOccurrences(of: "←", with: "").replacingOccurrences(of: "↑", with: "") + "→"
        }else if !right_bool{
            datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "→", with: "")
        }
        
    }
    @objc func imoveRight(){
        right_bool = !right_bool
        down_bool = false
        up_bool = false
        left_bool = false
        datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        if right_bool {
            datainputview.rightArrow.setImage(UIImage(named: "rightArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "↓", with: "").replacingOccurrences(of: "←", with: "").replacingOccurrences(of: "↑", with: "") + "→"
        }else if !right_bool{
            datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "→", with: "")
        }
        
    }
    @objc func moveLeft(){
        left_bool = !left_bool
        down_bool = false
        right_bool = false
        up_bool = false
        datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        datainputview.upArrow.setImage(UIImage(named: "upArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        if left_bool {
            datainputview.leftArrow.setImage(UIImage(named: "leftArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }else if !left_bool{
            datainputview.leftArrow.setImage(UIImage(named: "leftArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
    }
    
    func isExcelSheetData(sheetIdx:Int)->Bool{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        //localFileNames = ["sheet1"]
        
        //excel senario
        if isExcel && sheetIdx != -1{
            let sheet1Json = ReadWriteJSON()
            localFileNames = appd.sheetNameIds.map { "sheet\($0)" }
            print("sheetIdx",sheetIdx)
            if localFileNames.count > 0 {
                sheet1Json.readJsonFile(title:"sheet" + String(sheetIdx) + ".xml" )
                content = sheet1Json.content
                location = sheet1Json.location
                textsize = sheet1Json.fontsize
                bgcolor = sheet1Json.bgcolor
                tcolor = sheet1Json.fontcolor
                COLUMNSIZE = sheet1Json.columnsize
                ROWSIZE = sheet1Json.rowsize
                appd.customSizedWidth = sheet1Json.customcellWidth
                appd.customSizedHeight = sheet1Json.customcellHeight
                appd.cswLocation = sheet1Json.ccwLocation
                appd.cshLocation = sheet1Json.cchLocation
                return true
            }
            
            //the workbook is corrupted?
//            if localFileNames.count > 0 && sheet1Json.readJsonFile(title: "sheet" + String(appd.wsIndex)){
//                content = sheet1Json.content
//                location = sheet1Json.location
//                textsize = sheet1Json.fontsize
//                bgcolor = sheet1Json.bgcolor
//                tcolor = sheet1Json.fontcolor
//                COLUMNSIZE = sheet1Json.columnsize
//                ROWSIZE = sheet1Json.rowsize
//                appd.customSizedWidth = sheet1Json.customcellWidth
//                appd.customSizedHeight = sheet1Json.customcellHeight
//                appd.cswLocation = sheet1Json.ccwLocation
//                appd.cshLocation = sheet1Json.cchLocation
//                return true
//            }
//            
//            //
//            if localFileNames.count > 0 && !sheet1Json.readJsonFile(title: "sheet" + String(appd.wsIndex)){
//                print("something went wrong. maybe corrupt file.")
//            }
        }else{
            isExcel = false
            let sheet1Json = ReadWriteJSON()
            if sheet1Json.readJsonFile(title: "csv_sheet1"){
                content = sheet1Json.content
                location = sheet1Json.location
                textsize = sheet1Json.fontsize
                bgcolor = sheet1Json.bgcolor
                tcolor = sheet1Json.fontcolor
                COLUMNSIZE = sheet1Json.columnsize
                ROWSIZE = sheet1Json.rowsize
                appd.customSizedWidth = sheet1Json.customcellWidth
                appd.customSizedHeight = sheet1Json.customcellHeight
                appd.cswLocation = sheet1Json.ccwLocation
                appd.cshLocation = sheet1Json.cchLocation
                return false
            }
        }
        return false
    }
    
    func initSheetData(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //EXCEL FORMULA TRANSFORMATION STARTS
        //PI(),EXP(1)
        content = excel_fomula_transformation(src:content)
        
        //Taking out Empty Cells
        filterEmptyContent()
        
        //SOME THING WENT WRONG RESET PROCESS STARTS
        if location.count != content.count {
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            location.removeAll()
            content.removeAll()
            
            bgcolor.removeAll()
            cursor = String()
            tcolor.removeAll()
            textsize.removeAll()
            
            initString()
        }
        
        if location.count != bgcolor.count || location.count != tcolor.count || location.count != textsize.count{
            bgcolor.removeAll()
            textsize.removeAll()
            tcolor.removeAll()
            
            
            
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                for _ in 0..<location.count{
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                }
                break
                
            default:
                for _ in 0..<location.count{
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                }
                break
            }
        }
        
        //FOR COLLECTIONVIEW
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") != nil) {
            appd.customSizedWidth = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") != nil) {
            appd.customSizedHeight = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") != nil) {
            appd.cswLocation = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") != nil) {
            appd.cshLocation = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            COLUMNSIZE = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
        }
        
        if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
            ROWSIZE = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
        }
        
        
        
        
        if localFileNames.count == 0 {
            let newfile = "csv_sheet1"
            saveAsLocalJson(filename: newfile)
        }
        
    }
    
    //=EXP(A1) -> e^(A1), COMPLEX(x,y)
    //https://stackoverflow.com/questions/43012632/how-to-succinctly-get-the-first-5-characters-of-a-string-in-swift
    func excel_fomula_transformation(src:[String])->[String]{
        var ary = src
        for i in 0..<ary.count {
            if ary[i].contains("EXP"){
                ary[i] = ary[i].replacingOccurrences(of: "EXP", with: "e^")
            }
            if ary[i].contains("PI()"){
                ary[i] = ary[i].replacingOccurrences(of: "PI()", with: "pi")
            }
        }
        
        return ary
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
    
    @objc func close(){
        changeaffected.removeAll()
//        if selectedSheet >= 0{
        if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex{
            saveAsLocalJson(filename: "csv_sheet1")//localFileNames[selectedSheet])
        }
        self.customview3.removeFromSuperview()
    }
    
    //sendEmail
    @objc func excelEmail() {
        isMail = true
        let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //let url = serviceInstance.testSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
        let url = serviceInstance.writeXlsxEmail(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
        //createxlsxSheet()
        //save temp content
        var result = content
        for idx in 0..<f_calculated.count{
            if let l_idx = location.index(of: f_location[idx]){
                result[l_idx] = f_calculated[idx]
            }
        }
        csvexport(result: result)
        if MFMailComposeViewController.canSendMail() {
            let today: Date = Date()
            let dateFormatter: DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            var date = dateFormatter.string(from: today)

            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self

            mail.setSubject("from ios")


            //print("ViewController" ,filePath)
            if isExcel, let url2 = url, let fileData = NSData(contentsOfFile: url2.path) {
                mail.addAttachmentData(fileData as Data, mimeType: " application/vnd.openxmlformats-officedocument.spreadsheet", fileName: url!.lastPathComponent)
            }else{
                print("noContent")
            }

            //csv
            mail.addAttachmentData(data!, mimeType: "text/csv", fileName: date + ".csv")

            present(mail, animated: true, completion: nil)
            
            isMail = false
        } else {
            // show failure alert
        }
    }
    
    func uploadFileToICloud(url: URL,filename: String) {
        let fileManager = FileManager.default
        
        if let containerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            if !FileManager.default.fileExists(atPath: containerUrl.path, isDirectory: nil) {
                do {
                    //create directory
                    try FileManager.default.createDirectory(at: containerUrl, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print(error.localizedDescription)
                }
            }
            
            let fileUrl = containerUrl.appendingPathComponent(filename.replacingOccurrences(of: ".xlsx", with: "") + ".xlsx")
            do {
                // Check if the file already exists in iCloud and remove it if it does
                if fileManager.fileExists(atPath: fileUrl.path) {
                    try fileManager.removeItem(at: fileUrl)
                }
                
                // Copy the file to iCloud Drive
                try fileManager.copyItem(at: url, to: fileUrl)
                
                // Verify the file was successfully copied
                if fileManager.fileExists(atPath: fileUrl.path) {
                    print("File verified to exist in iCloud Drive at: \(fileUrl.path)")
                } else {
                    print("File could not be verified in iCloud Drive")
                }
            } catch {
                print("Error uploading file to iCloud Drive: \(error.localizedDescription)")
            }
           
        }
    }
    
    func uploadFileToICloudCSV(filename: String) {
        let fileManager = FileManager.default
        
        // Get the path to the local file
        let pathDirectory = getRootDocumentsDirectory()
        let filePath = pathDirectory.appendingPathComponent("importedCSV").appendingPathComponent("tempCSV.csv")
        
        guard fileManager.fileExists(atPath: filePath.path) else {
            print("Local file does not exist at: \(filePath.path)")
            return
        }
        
        guard let containerUrl = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            print("iCloud container URL is not available.")
            return
        }
        
        let fileUrl = containerUrl.appendingPathComponent(filename.replacingOccurrences(of: ".csv", with: "") + ".csv")
        
        do {
            // Remove the file in iCloud if it already exists
            if fileManager.fileExists(atPath: fileUrl.path) {
                try fileManager.removeItem(at: fileUrl)
                print("Existing file in iCloud removed at: \(fileUrl.path)")
            }
            
            // Copy the file to iCloud Drive
            try fileManager.copyItem(at: filePath, to: fileUrl)
            print("File successfully uploaded to iCloud Drive at: \(fileUrl.path)")
            
        } catch {
            print("Error during file upload to iCloud: \(error.localizedDescription)")
        }
    }
    
    
    @IBAction func elsxExportAction(_ sender: Any) {
        readAllJsonFiles()
        createxlsxSheet()
        sleep(4)
        excelEmail()
        
    }
    
    func readAllJsonFiles(){
        
        for i in 0..<localFileNames.count {
            
            //FileNameCollectionview Change Page
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            selectedSheet = i
            stringboxText = ""
            
            
            initSheetData()
            //
            FileCollectionView.reloadData()
            fileTitle.text = localFileNames[selectedSheet]
            //
            
            calcPrep()
            calculatormode_update_main()
            
            DispatchQueue.main.async() {
                appd.collectionViewCellSizeChanged = 1
                self.myCollectionView.collectionViewLayout.invalidateLayout()
                self.myCollectionView.reloadData()
            }
        }
    }
    
    
    func rejectCapitalLetters(chaos:String) -> String{
        let capitalLetterRegEx = "[A-Z]"
        let exist = NSPredicate(format: "SELF MATCHES %@", capitalLetterRegEx).evaluate(with: chaos)
        if exist {
            return ""
        }else{
            return chaos
        }
    }
    
    func calcPrep(){
        
        
        for idx in 0..<content.count {
            let checkit = content[idx].replacingOccurrences(of: "¥", with: "").replacingOccurrences(of: "$", with: "").replacingOccurrences(of: "€", with: "")
            if Double(checkit) != nil{
                
                
                let number = location[idx].components(separatedBy: ",")[0]
                let number2 = location[idx].components(separatedBy: ",")[1]
                let intnumber = Int(number)
                let alphabets = getExcelColumnName(columnNumber: intnumber!)
                let each = String(alphabets + number2)//no need ","
                
            }
        }
    }
    
    func numberOnlyString(text: String) -> String {
        let okayChars = Set("1234567890")
        return text.filter {okayChars.contains($0) }
    }
    
    
    func excelFormulaExpression(src:String)->String{
        var formatted = src
        formatted = formatted.replacingOccurrences(of: "sqrt", with: "SQRT")
        formatted = formatted.replacingOccurrences(of: "logd", with: "LOG10")
        formatted = formatted.replacingOccurrences(of: "log", with: "LOG")
        formatted = formatted.replacingOccurrences(of: "pi", with: "PI()")
        formatted = formatted.replacingOccurrences(of: "e^", with: "EXP")
        return formatted
    }
    
    func elsvFormulaExpression(src:[String])->[String]{
        var formatted = src
        for i in 0..<formatted.count{
            formatted[i] = formatted[i].replacingOccurrences(of: "SQRT", with: "sqrt")
            formatted[i] = formatted[i].replacingOccurrences(of: "LOG10", with: "logd")
            formatted[i] = formatted[i].replacingOccurrences(of: "LOG", with: "log")
            formatted[i] = formatted[i].replacingOccurrences(of: "PI()", with: "pi")
            formatted[i] = formatted[i].replacingOccurrences(of: "EXP", with: "exp^")
        }
        
        return formatted
    }
    
    @objc func sinAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=sin("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "sin("
        }
    }
    
    @objc func asinAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=asin("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "asin("
        }
    }
    
    @objc func cosAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=cos("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "cos("
        }
    }
    
    @objc func acosAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=acos("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "acos("
        }
    }
    
    @objc func tanAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=tan("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "tan("
        }
    }
    
    @objc func atanAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=atan("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "atan("
        }
    }
    
    @objc func logdAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=logd("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "logd("
        }
    }
    
    @objc func lnAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=log("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "log("
        }
    }
    
    @objc func expAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=e"
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "e"
        }
    }
    
    @objc func powAction(){
        
        datainputview.stringbox.text = datainputview.stringbox.text + "^"
        
    }
    
    @objc func sqrtAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=sqrt("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "sqrt("
        }
    }
    
    @objc func complexAction(){
        
        datainputview.stringbox.text = "=COMPLEX("
        
    }
    
    @objc func piAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=pi"
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "pi"
        }
    }
    
    @objc func imsumAction(){
        
        datainputview.stringbox.text = "=IMSUM("
        
    }
    
    @objc func imsubAction(){
        datainputview.stringbox.text = "=IMSUB("
    }
    
    @objc func improAction(){
        datainputview.stringbox.text = "=IMPRODUCT("
    }
    
    @objc func imargAction(){
        datainputview.stringbox.text = "=IMARGUMENT("
    }
    
    @objc func imdivAction(){
        datainputview.stringbox.text = "=IMDIV("
    }
    
    @objc func imabsAction(){
        datainputview.stringbox.text = "=IMABS("
    }
    
    @objc func imrectAction(){
        datainputview.stringbox.text = "=IMRECTANGULAR("
    }
    
    @objc func plusmarkAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "+"
        }
    }
    
    @objc func crossAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "*"
        }
    }
    
    @objc func openBraceAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "("
        }
    }
    
    @objc func closeBraceAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + ")"
        }
    }
    
    @objc func commaAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + ","
        }
    }
    
    @objc func colonAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + ":"
        }
    }
    
    func isNumeric(_ str: String) -> Bool {
        // Check if the string is empty
        guard !str.isEmpty else {
            return false
        }
        
        // Define a character set containing decimal digits and the decimal point
        var decimalDigits = CharacterSet.decimalDigits
        decimalDigits.insert(".")
        
        // Check if the string contains only characters from the decimalDigits set
        return str.rangeOfCharacter(from: decimalDigits.inverted) == nil
    }

}

extension FileManager {
    
    open func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }
    
}

extension UIApplication {
    
    func getKeyWindow() -> UIWindow? {
        if #available(iOS 13, *) {
            return windows.first { $0.isKeyWindow }
        } else {
            return keyWindow
        }
    }
    
    func makeSnapshot() -> UIImage? { return getKeyWindow()?.layer.makeSnapshot() }
}


extension CALayer {
    func makeSnapshot() -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(frame.size, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        render(in: context)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        return screenshot
    }
}

extension UIView {
    func makeSnapshot() -> UIImage? {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(size: frame.size)
            return renderer.image { _ in drawHierarchy(in: bounds, afterScreenUpdates: true) }
        } else {
            return layer.makeSnapshot()
        }
    }
}

extension UIImage {
    convenience init?(snapshotOf view: UIView) {
        guard let image = view.makeSnapshot(), let cgImage = image.cgImage else { return nil }
        self.init(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

extension UICollectionView {
    
    func scrollToNextItem() {
        let scrollOffset = CGFloat(floor(self.contentOffset.x + self.bounds.size.width))
        self.scrollToFrame(scrollOffset: scrollOffset)
    }
    
    func scrollToPreviousItem() {
        let scrollOffset = CGFloat(floor(self.contentOffset.x - self.bounds.size.width))
        self.scrollToFrame(scrollOffset: scrollOffset)
    }
    
    func scrollToFrame(scrollOffset : CGFloat) {
        guard scrollOffset <= self.contentSize.width - self.bounds.size.width else { return }
        guard scrollOffset >= 0 else { return }
        self.setContentOffset(CGPoint(x: scrollOffset, y: self.contentOffset.y), animated: true)
    }
    
}




@IBDesignable class UIMarginLabel: UILabel {
    
    @IBInspectable var topInset:       CGFloat = 0
    @IBInspectable var rightInset:     CGFloat = 0
    @IBInspectable var bottomInset:    CGFloat = 0
    @IBInspectable var leftInset:      CGFloat = 0
    
    
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: self.topInset, left: self.leftInset, bottom: self.bottomInset, right: self.rightInset)
        self.setNeedsLayout()
        return super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}
extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
}
extension UIView {
    func setBorder(width: CGFloat, color: UIColor, sides: UIRectEdge) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
        
        // Clear existing borders
        layer.maskedCorners = []
        
        // Apply borders to specified sides
        if sides.contains(.top) {
            layer.maskedCorners.insert(.layerMinXMinYCorner)
            layer.maskedCorners.insert(.layerMaxXMinYCorner)
        }
        if sides.contains(.bottom) {
            layer.maskedCorners.insert(.layerMinXMaxYCorner)
            layer.maskedCorners.insert(.layerMaxXMaxYCorner)
        }
        if sides.contains(.left) {
            layer.maskedCorners.insert(.layerMinXMinYCorner)
            layer.maskedCorners.insert(.layerMinXMaxYCorner)
        }
        if sides.contains(.right) {
            layer.maskedCorners.insert(.layerMaxXMinYCorner)
            layer.maskedCorners.insert(.layerMaxXMaxYCorner)
        }
    }
}

