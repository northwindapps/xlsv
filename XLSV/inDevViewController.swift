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
import GoogleMobileAds
import CoreData
import Zip
import SSZipArchive


let reuseIdentifier = "customCell"
let SCREENSIZE_w = ScreenSize.SCREEN_WIDTH
let SCREENSIZE = ScreenSize.SCREEN_HEIGHT

var otherclass = colorclass()

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate,UITextViewDelegate,MFMailComposeViewControllerDelegate,UICollectionViewDelegateFlowLayout,UIDocumentPickerDelegate,UIGestureRecognizerDelegate,GADBannerViewDelegate{
    
    @IBOutlet weak var bannerview: GADBannerView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var enterButton: UIButton!
    @IBOutlet weak var pageButton: UIButton!
    @IBOutlet weak var fileTitle: UILabel!
    
    
    var KEYBOARDLOCATION = CGFloat()
    @objc var List: Array<AnyObject> = []
    
    var location = [String]()
    var content = [String]()
    
    var math_locations = [String]()
    var math_content = [String]()
    
    var math_locations2 = [String]()
    var math_content2 = [String]()
    
    //mergedcells
    var nousecells = [[Int]]()
    
    
    
    //Font location
    var bglocation = [String]()
    var tlocation = [String]()
    var sizelocation = [String]()
    var cursor = String()
    
    
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
    
    var tag_int :Int!
    
    var current_range : NSRange!
    
    
    var stringboxText = ""
    var pastemode : Bool = false
    
    
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
    
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    
    
    @IBOutlet weak var pastemode_state: UIButton!
    
    var customview2 :Customview2!
    var Fview :formatview!
    var datainputview :Datainputview!
    
    //forexport
    var data: Data? = nil
    var byproduct: NSMutableString? = nil
    var currentindex : IndexPath!
    var currentindexstr : String!
    
    
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
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        //#warning Incomplete method implementation -- Return the number of sections
        var rowsize = 60
        
        if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
            
            rowsize = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
        }
        
        if appd.JSON.count > 0{
            let index = appd.index
            rowsize = appd.JSON[index]["rSize"] as! Int
            
//            let t = UserDefaults.standard
//            t.set(rowsize, forKey: "NEWRsize")
//            t.synchronize()
        }
        
        
        if rowsize < 1{
            rowsize = 1
        }
        
        
        
        ROWSIZE = rowsize
        
        
        appd.numberofRow = rowsize
        return rowsize
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        var columnsize = 30 //27
        
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            columnsize = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
        }
        
        if appd.JSON.count > 0{
            let index = appd.index
            columnsize = appd.JSON[index]["cSize"] as! Int
            
//            let t = UserDefaults.standard
//            t.set(columnsize, forKey: "NEWCsize")
//            t.synchronize()
        }
        
        if columnsize < 1{
            columnsize = 1
        }
        
        COLUMNSIZE = columnsize
        
        appd.numberofColumn = columnsize
        
        return columnsize
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CustomCollectionViewCell
        
    
        cell.label.lineBreakMode = .byWordWrapping // or NSLineBreakMode.ByWordWrapping
        cell.label.numberOfLines = 0
        
        //content
        if location.contains(String(indexPath.item)+","+String(indexPath.section)){
            
            let i = location.index(of: String(indexPath.item)+","+String(indexPath.section))
            
            cell.label.text = content[i!].replacingOccurrences(of: "\"\"", with: "\n")
            
            if math_locations.contains(String(indexPath.item)+","+String(indexPath.section)){
                
                let i = math_locations.index(of: String(indexPath.item)+","+String(indexPath.section))
                
                cell.label.text = math_content[i!].replacingOccurrences(of: "\"\"", with: "\n")
                
                
            }
            
        }else
        {
            cell.label.text = ""
        }
        
        
        //Textsize
        if sizelocation.contains(String(indexPath.item)+","+String(indexPath.section)){
            
            let i = sizelocation.index(of:String(indexPath.item)+","+String(indexPath.section))
            
            //http://stackoverflow.com/questions/27595799/convert-string-to-cgfloat-in-swift
            //http://stackoverflow.com/questions/24356888/how-do-i-change-the-font-size-of-a-uilabel-in-swift
            let fl: CGFloat = CGFloat((textsize[i!] as NSString).doubleValue)
            
            //cell.label.font = cell.label.font.withSize(fl)
            cell.label.font = UIFont.systemFont(ofSize: fl)
            
        }else{
            
            let fl: CGFloat = CGFloat(("13" as NSString).doubleValue)
            
            cell.label.font = UIFont.systemFont(ofSize: fl)
        }
        
        
        
        //Border
        if cursor == (String(indexPath.item)+","+String(indexPath.section)){
            //cell.label.backgroundColor = UIColor.whitecyan
            cell.label.layer.borderColor = UIColor.red.cgColor
            cell.label.layer.borderWidth = 4.0
        }else{
            cell.label.layer.borderColor = UIColor.orange.cgColor
            cell.label.layer.borderWidth = 0.5
        }
        
        
        //BG
        if  bglocation.index(of: String(indexPath.item)+","+String(indexPath.section)) != nil || tlocation.index(of: String(indexPath.item)+","+String(indexPath.section)) != nil{
            
            if bglocation.index(of: String(indexPath.item)+","+String(indexPath.section)) != nil{
                let i = bglocation.index(of: String(indexPath.item)+","+String(indexPath.section))
                
                if bgcolor[i!] == "green"{
                    
                    cell.label.backgroundColor = UIColor(red: 152/255, green: 255/255, blue: 153/255, alpha: 1)
                    
                }
                else if bgcolor[i!] == "cyan"{
                    
                    cell.label.backgroundColor = UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1)
                    
                }else if bgcolor[i!] == "yellow"{
                    
                    cell.label.backgroundColor =  UIColor(red: 255/255, green: 255/255, blue: 51/255, alpha: 1)
                    
                }else if bgcolor[i!] == "orange"{
                    
                    cell.label.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 51/255, alpha: 1)
                    
                }else if bgcolor[i!] == "lightgray"{
                    
                    cell.label.backgroundColor = UIColor.lightGray
                    
                }else if bgcolor[i!] == "magenta"{
                    
                    cell.label.backgroundColor = UIColor(red: 255/255, green: 64/255, blue: 255/255, alpha: 1)
                    
                }else if bgcolor[i!] == "blue"{
                    
                    cell.label.backgroundColor = UIColor(red: 9/255, green: 85/255, blue: 242/255, alpha: 1)
                    
                }else if bgcolor[i!] == "red"{
                    
                    cell.label.backgroundColor = UIColor(red: 255/255, green: 38/255, blue: 0/255, alpha: 1)
                    
                }else if bgcolor[i!] == "brown"{
                    
                    cell.label.backgroundColor = UIColor(red: 204/255, green: 152/255, blue: 102/255, alpha: 1)
                    
                }else if bgcolor[i!] == "purple"{
                    
                    cell.label.backgroundColor = UIColor(red: 167/255, green: 147/255, blue: 237/255, alpha: 1)
                    
                }else if bgcolor[i!] == "darkgray"{
                    
                    cell.label.backgroundColor = UIColor.darkGray
                    
                }else if bgcolor[i!] == "white"{
                    
                    cell.label.backgroundColor = UIColor.white
                    
                }else if bgcolor[i!] == "black"{
                    
                    cell.label.backgroundColor = UIColor.black
                }else{
                    cell.label.backgroundColor = UIColor.white
                }
            }
            
            //textcolor
            if tlocation.index(of: String(indexPath.item)+","+String(indexPath.section)) != nil{
                
                let j = tlocation.index(of: String(indexPath.item)+","+String(indexPath.section))
                
                if tcolor[j!] == "green"{
                    
                    cell.label.textColor = UIColor(red: 152/255, green: 255/255, blue: 153/255, alpha: 1)
                }
                else if tcolor[j!] == "cyan"{
                    
                    cell.label.textColor = UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1)
                    
                }else if tcolor[j!] == "yellow"{
                    
                    cell.label.textColor =  UIColor(red: 255/255, green: 255/255, blue: 51/255, alpha: 1)
                    
                }else if tcolor[j!] == "orange"{
                    
                    cell.label.textColor = UIColor(red: 255/255, green: 204/255, blue: 51/255, alpha: 1)
                    
                }else if tcolor[j!] == "lightgray"{
                    
                    cell.label.textColor = UIColor.lightGray
                    
                }else if tcolor[j!] == "magenta"{
                    
                    cell.label.textColor = UIColor(red: 255/255, green: 64/255, blue: 255/255, alpha: 1)
                    
                }else if tcolor[j!] == "blue"{
                    
                    cell.label.textColor = UIColor(red: 9/255, green: 85/255, blue: 242/255, alpha: 1)
                    
                }else if tcolor[j!] == "red"{
                    
                    cell.label.textColor = UIColor(red: 255/255, green: 38/255, blue: 0/255, alpha: 1)
                    
                }else if tcolor[j!] == "brown"{
                    
                    cell.label.textColor = UIColor(red: 204/255, green: 152/255, blue: 102/255, alpha: 1)
                    
                }else if tcolor[j!] == "purple"{
                    
                    cell.label.textColor = UIColor(red: 167/255, green: 147/255, blue: 237/255, alpha: 1)
                    
                }else if tcolor[j!] == "darkgray"{
                    
                    cell.label.textColor = UIColor.darkGray
                    
                }else if tcolor[j!] == "white"{
                    
                    cell.label.textColor = UIColor.white
                    
                }else if tcolor[j!] == "black"{
                    
                    cell.label.textColor = UIColor.black
                }else{
                    cell.label.textColor = UIColor.white
                }
                
                if bglocation.index(of: String(indexPath.item)+","+String(indexPath.section)) == nil{
                    cell.label.backgroundColor = UIColor.white
                }
            }
            
        }else{
            cell.label.backgroundColor = UIColor.white
            cell.label.textColor = UIColor.black
            
            if indexPath.item == 0{
                
                if indexPath.section > 0{
                    cell.label.text = String(indexPath.section)
                    rowinNumber.append("r" + cell.label.text!)
                }
                
                cell.label.backgroundColor = UIColor(red: 33/255, green: 107/255, blue: 255/255, alpha: 1)
                cell.label.textColor = UIColor.white
            }else if indexPath.section == 0{
                
                if indexPath.item > 0{//0,0 == greyzone
                    cell.label.text = GetExcelColumnName(columnNumber: indexPath.item)//ABCDE...
                    columninNumber.append(cell.label.text!)
                }
                
                
                cell.label.backgroundColor = UIColor(red: 33/255, green: 107/255, blue: 255/255, alpha:1)
                cell.label.textColor = UIColor.white
            }
        }
        
        
        
        
        
        
        //http://stackoverflow.com/questions/29381994/swift-check-string-for-nil-empty
        //http://qiita.com/satomyumi/items/b0d071cc906574086ac4
        
        
        return cell
        
        
    }
    
    
    
    //Hiding Keyboard
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            input()
            
            saveuserD()
            saveuserF()
            return false
        }
        
        return true
    }
    
    
    //Touching one of cells
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch pastemode {
        case true:
            
            otherclass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
            
            currentindex = indexPath
            currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
            //
            indexlabel()
            cursor = currentindexstr
            if location.contains(currentindexstr){
                
                let i = location.index(of: currentindexstr)
                content[i!] = stringboxText
                
            }else{
                location.append(currentindexstr)
                content.append(stringboxText)
            }
            
            
            
            
            break
            
        case false:
            
            if datainputview != nil{
                datainputview.stringbox.text = ""
                datainputview.removeFromSuperview()
                
            }
            
            currentindex = indexPath
            currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
            
            //
            indexlabel()
            
            cursor = currentindexstr
            
            
            
            
            
            //sizing column width and height
            if indexPath.item == 0{
                
                numberviewopen()
                
                
            }else if indexPath.section == 0{
                
                numberviewopen()
                
            }else{
                
                if orientaion == "P"{
                    
                    switch UIDevice.current.userInterfaceIdiom {
                    case .phone:
                        // It's an iPhone
                        
//                        datainputview = Datainputview(frame: CGRect(x:20,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 280,height: 60))
                        datainputview = Datainputview(frame: CGRect(x:0,y:5, width: 280,height: 60))
                        
                        break
                    case .pad:
                        // It's an iPad
                        datainputview = Datainputview(frame: CGRect(x:Int(SCREENSIZE_w*0.5-210),y:Int(SCREENSIZE - KEYBOARDLOCATION - 85.0), width: 420,height: 85))
                        datainputview.upArrow.addTarget(self, action: #selector(moveUp), for: UIControlEvents.touchUpInside)
                        datainputview.downArrow.addTarget(self, action: #selector(moveDown), for: UIControlEvents.touchUpInside)
                        datainputview.leftArrow.addTarget(self, action: #selector(moveLeft), for: UIControlEvents.touchUpInside)
                        datainputview.rightArrow.addTarget(self, action: #selector(moveRight), for: UIControlEvents.touchUpInside)
                        break
                    case .unspecified:
                        // Uh, oh! What could it be?
                        datainputview = Datainputview(frame: CGRect(x:20,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 280,height: 60))
                        
                        break
                    default:
                        break
                    }
                    
                }else if orientaion == "L"{
                    
                    switch UIDevice.current.userInterfaceIdiom {
                    case .phone:
                        // It's an iPhone
                        
                      
                        datainputview = Datainputview(frame: CGRect(x:0,y:5, width: 280,height: 60))
                        
                        break
                    case .pad:
                        // It's an iPad
                        datainputview = Datainputview(frame: CGRect(x:Int(SCREENSIZE_w*0.5-210),y:Int(SCREENSIZE - KEYBOARDLOCATION - 85.0), width: 420,height: 85))
                        datainputview.upArrow.addTarget(self, action: #selector(ViewController.moveUp), for: UIControlEvents.touchUpInside)
                        datainputview.downArrow.addTarget(self, action: #selector(ViewController.moveDown), for: UIControlEvents.touchUpInside)
                        datainputview.leftArrow.addTarget(self, action: #selector(ViewController.moveLeft), for: UIControlEvents.touchUpInside)
                        datainputview.rightArrow.addTarget(self, action: #selector(ViewController.moveRight), for: UIControlEvents.touchUpInside)
                        break
                    case .unspecified:
                        // Uh, oh! What could it be?
                        datainputview = Datainputview(frame: CGRect(x:20,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 385,height: 85))
                        
                        break
                    default:
                        break
                    }
                    
                }
                
                
                
                
                datainputview.stringbox.delegate = self
                datainputview.stringbox.layer.borderWidth = 1
                datainputview.stringbox.layer.borderColor = UIColor.gray.cgColor
                
                datainputview.okbutton.addTarget(self, action: #selector(ViewController.terminate), for: UIControlEvents.touchUpInside)
                
                datainputview.returnbutton.addTarget(self, action: #selector(ViewController.restore), for: UIControlEvents.touchUpInside)
                
                datainputview.copyButton.addTarget(self, action: #selector(ViewController.copyText), for: UIControlEvents.touchUpInside)
                
                datainputview.fontbutton.addTarget(self, action: #selector(ViewController.fontediting), for: UIControlEvents.touchUpInside)
                datainputview.stringbox.becomeFirstResponder()
                
                self.view.addSubview(datainputview)
                
                
                //http://studyswift.blogspot.jp/2015/01/showhide-keyboard-while-using.html
                
                
                
                //https://stackoverflow.com/questions/46375700/programmatically-create-touchupinside-event-for-uitextfield
                
                
                //datainputview.stringbox.text = stringboxText
                
                
            }
            break
        }
        
        myCollectionView.reloadData()
        
    }
    
    
    
    //http://stackoverflow.com/questions/27674317/changing-cell-background-color-in-uicollectionview-in-swift
    
    
    @objc func csvexport()
    {
        calculatormode()
        
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
                
                if math_locations.contains(PATH){
                    let k = math_locations.index(of: PATH)
                    
                    if math_content[k!].contains(","){
                        mailString.append(math_content[k!].replacingOccurrences(of: ",", with: ""))
                    }else if math_content[k!].contains("\n"){
                        
                    }else{
                        mailString.append(math_content[k!])
                    }
                }
                else if location.contains(PATH){
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
        
        byproduct = mailString
        data = mailString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
        
    }
    
    
    
    
    @objc func back2(_ sender:UIButton)
    {
        self.customview2.removeFromSuperview()
    }
    
    
    
    @objc func localsave(_ sender:UIButton)
    {
        //       postAction()
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "creditView" )
        self.present( targetViewController, animated: true, completion: nil)
        
        self.customview2.removeFromSuperview()
    }
    
    @objc func reset(_ sender:UIButton)
    {
        
        location.removeAll()
        content.removeAll()
        
        math_locations.removeAll()
        math_content.removeAll()
        
        math_locations2.removeAll()
        math_content2.removeAll()
        
        bglocation.removeAll()
        bgcolor.removeAll()
        
        
        tlocation.removeAll()
        sizelocation.removeAll()
        cursor = String()
        tcolor.removeAll()
        textsize.removeAll()
        
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.JSON.removeAll()
        appd.currentDir.removeAll()
        appd.mergedCellListJSON.removeAll()
        appd.nousecells.removeAll()
        
        
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "SettingsViewController" )
        self.present( targetViewController, animated: true, completion: nil)
        
        self.customview2.removeFromSuperview()
    }
    
    
    @objc func localload(_ sender:UIButton)
    {
        
        location.removeAll()
        content.removeAll()
        
        //Font location
        bglocation.removeAll()
        tlocation.removeAll()
        sizelocation.removeAll()
        
        
        tcolor.removeAll()
        textsize.removeAll()
        bgcolor.removeAll()
        
        
        self.customview2.removeFromSuperview()
        
        performSegue(withIdentifier: "previousData", sender: nil)
        
        //let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "localsaveandload" )
        //self.present( targetViewController, animated: true, completion: nil)
        
        
    }
    
    
    @objc func icloudview(_ sender:UIButton){
        
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "iCloud" )//Landscape
        self.present( targetViewController, animated: true, completion: nil)
        
        self.customview2.removeFromSuperview()
        
    }
    
    
    
    
    override func viewDidLoad() {
        
        menuButton.layer.borderWidth = 1.0
//        enterButton.layer.borderWidth = 1.0
        pageButton.layer.cornerRadius = 8.0
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let locationstr = Locale.current.languageCode!
        
        if locationstr == "ja"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "ページ", for: .normal)
        }else if locationstr == "fr"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "pages", for: .normal)
        }else if locationstr == "zh"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "页数", for: .normal)
        }else if locationstr == "de"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "Seiten", for: .normal)
        }else if locationstr == "it"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "pagine", for: .normal)
        }else if locationstr == "da"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "sider", for: .normal)
        }else if locationstr == "ru"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "страницы", for: .normal)
        }else if locationstr == "es"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "paginas", for: .normal)
        }else if locationstr == "sv"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "sidor", for: .normal)
        }else{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "pages", for: .normal)
        }
       
        if appd.JSON.count < 1{
            pageButton.isHidden = true
        }else{
            pageButton.isHidden = false
        }
        
        if appd.currentDir.count > 0{
            fileTitle.text = appd.currentDir
        }else{
            fileTitle.text = ""
        }

        super.viewDidLoad()
        
        columninNumber.removeAll()
        columninNumber.append("null")
        rowinNumber.removeAll()
        rowinNumber.append("null")
        
        
        
        //http://qiita.com/xa_un/items/814a5cd4472674640f58
        
        
        
        
        
        
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        tag_int = appDelegate.tag_int
        
        myCollectionView.delegate = self
        
        
        orientaion = "P"
      
        
        //Get sheet data
        noInternet()
       
        
        if appd.JSON.count > 0{
            let index = appd.index
            COLUMNSIZE = appd.JSON[index]["cSize"] as! Int
            ROWSIZE = appd.JSON[index]["rSize"] as! Int
            location = appd.JSON[index]["location"] as! [String]
            content = appd.JSON[index]["contents"] as! [String]
        }
        
        otherclass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        
        
        
        
        
        //https://stackoverflow.com/questions/31774006/how-to-get-height-of-keyboard
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        
        bannerview.isHidden = true
        bannerview.delegate = self
        bannerview.adUnitID = "ca-app-pub-5284441033171047/6150797968"
        //        bannerview.adUnitID = "ca-app-pub-3940256099942544/2934735716" test
        bannerview.rootViewController = self
//        bannerview.load(GADRequest())
        
        zipping()
        
    }
    //the end of viewdidload
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerview.isHidden = false
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        bannerview.isHidden = true
    }
    
    func initString() {
        
        COLUMNSIZE = 27
        ROWSIZE = 50
        
        
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
        //textField.resignFirstResponder()
        
        
        
        
        return true
    }
    
    
    //http://stackoverflow.com/questions/35782218/swift-how-to-make-mfmailcomposeviewcontroller-disappear
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    
    @objc func sendEmail(_ sender:UIButton) {
        
        csvexport()
        if MFMailComposeViewController.canSendMail() {
            let today: Date = Date()
            let dateFormatter: DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            let date = dateFormatter.string(from: today)
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            
            let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            
            let url1 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let filePath0 = URL(fileURLWithPath: url1).appendingPathComponent("archived.xlsx").path
            
        
            
            let filePath = URL(fileURLWithPath: filePath0)
            print("filePath",filePath)
            if let fileData = NSData(contentsOfFile: filePath0) {
                mail.addAttachmentData(fileData as Data, mimeType: " application/vnd.openxmlformats-officedocument.spreadsheet", fileName: "test.xlsx")
            }
//            mail.addAttachmentData(data!, mimeType: "text/csv", fileName: date + ".csv")
            
            present(mail, animated: true)
        } else {
            // show failure alert
        }
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
    
    
    func movetosearchreplace(_ sender:UIButton){
        
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "searchreplace" )
        self.present( targetViewController, animated: true, completion: nil)
        
    }
    
    
    //http://code-examples-ja.hateblo.jp/entry/2016/09/21/Swift3
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
    @IBAction func pagingAction(_ sender: Any) {
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "paging" )//Landscape
        self.present( targetViewController, animated: true, completion: nil)
    }
    
    
    @IBAction func show2(_ sender: AnyObject) {
        
        if customview2 != nil{
            
            customview2.removeFromSuperview()
        }
        
        switch tag_int {
        case 0:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 235,height: 130))
            break
        case 1:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 235,height: 130))
            break
        case 2:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 235,height: 130))
            break
        case 3:
            customview2 = Customview2(frame: CGRect(x:5,y:10, width: 235,height: 130))
            break
        case 4:
            customview2 = Customview2(frame: CGRect(x:5,y:200, width: 235,height: 130))
            break
        case 5:
            customview2 = Customview2(frame: CGRect(x:5,y:190, width: 235,height: 130))
            break
            
            
            
            
            
        default:
            customview2 = Customview2(frame: CGRect(x:5,y:150, width: 235,height: 130))
            break
            
        }
        
        
        
        
        customview2.layer.borderWidth = 1
        
        customview2.layer.cornerRadius = 8;
        
        
        customview2.layer.borderColor = UIColor.black.cgColor
        
        
        customview2.export.addTarget(self, action: #selector(ViewController.sendEmail(_:)), for: UIControlEvents.touchUpInside)
        
        customview2.calcAll.addTarget(self, action: #selector(calculatormode), for: UIControlEvents.touchUpInside)
        
        
        customview2.back.addTarget(self, action: #selector(ViewController.back2(_:)), for: UIControlEvents.touchUpInside)
        
        customview2.localLoad.addTarget(self, action: #selector(ViewController.icloudview(_:)), for: UIControlEvents.touchUpInside)
        
        customview2.localSave.addTarget(self, action: #selector(ViewController.localsave(_:)), for: UIControlEvents.touchUpInside)
        
        customview2.reset.addTarget(self, action: #selector(ViewController.reset(_:)), for: UIControlEvents.touchUpInside)
        
        //this will be available in pay version
        //customview2.icloud.addTarget(self,action: #selector(ViewController.icloudview(_:)),for:UIControlEvents.touchUpInside)
        
        self.view.addSubview(customview2)
    }
    
    
    @objc func fontediting() {
        
        if Fview != nil {
            Fview.removeFromSuperview()
        }
        
        
        Fview = formatview(frame: CGRect(x:10,y:30, width: 300,height: 120))
        
        
        
        Fview .layer.borderWidth = 1
        
        Fview .layer.cornerRadius = 8;
        
        Fview .layer.borderColor = UIColor.black.cgColor
        
        Fview .color5.layer.borderWidth = 1
        
        Fview .color5.layer.borderColor = UIColor.black.cgColor
        
        Fview.backaction.addTarget(self, action: #selector(ViewController.formatbackaction(_:)), for: UIControlEvents.touchUpInside)
        
        Fview.color1.addTarget(self, action: #selector(ViewController.c1(_:)), for: UIControlEvents.touchUpInside)
        Fview.color2.addTarget(self, action: #selector(ViewController.c2(_:)), for: UIControlEvents.touchUpInside)
        
        Fview.color5.addTarget(self, action: #selector(ViewController.c5(_:)), for: UIControlEvents.touchUpInside)
        Fview.color6.addTarget(self, action: #selector(ViewController.c6(_:)), for: UIControlEvents.touchUpInside)
        Fview.color7.addTarget(self, action: #selector(ViewController.c7(_:)), for: UIControlEvents.touchUpInside)
        Fview.color8.addTarget(self, action: #selector(ViewController.c8(_:)), for: UIControlEvents.touchUpInside)
        Fview.color9.addTarget(self, action: #selector(ViewController.c9(_:)), for: UIControlEvents.touchUpInside)
        Fview.color10.addTarget(self, action: #selector(ViewController.c10(_:)), for: UIControlEvents.touchUpInside)
        Fview.color11.addTarget(self, action: #selector(ViewController.c11(_:)), for: UIControlEvents.touchUpInside)
        Fview.color12.addTarget(self, action: #selector(ViewController.c12(_:)), for: UIControlEvents.touchUpInside)
        Fview.color13.addTarget(self, action: #selector(ViewController.c13(_:)), for: UIControlEvents.touchUpInside)
        Fview.color14.addTarget(self, action: #selector(ViewController.c14(_:)), for: UIControlEvents.touchUpInside)
        Fview.color15.addTarget(self, action: #selector(ViewController.c15(_:)), for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(Fview)
        
        
        
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
        numberview.back.addTarget(self, action: #selector(ViewController.backactionnum(_:)), for: UIControlEvents.touchUpInside)
        
        numberview.plusOne.addTarget(self, action: #selector(ViewController.plusAction(_:)), for: UIControlEvents.touchUpInside)
        
        
        numberview.minusOne.addTarget(self, action: #selector(ViewController.minusAction(_:)), for: UIControlEvents.touchUpInside)
        
        numberview.width_height_selector.setTitle(width, forSegmentAt: 0)
        numberview.width_height_selector.setTitle(height, forSegmentAt: 1)
        
        
        self.view.addSubview(numberview)
    }
    
    @IBAction func pastemode_action(_ sender: AnyObject) {
        
        switch pastemode {
        case false:
            pastemode = true
            break
        case true:
            pastemode = false
            break
        }
        
        pastemodeChange()
        
    }
    
    
    //*********************//
    
    
    @objc func formatbackaction(_ sender:UIButton)
    {
        
        Fview.removeFromSuperview()
    }
    
    @objc func c1(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=cyan"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=cyan"
        }
        
        fonteditmode()
        
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c2(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=brown"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=brown"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c5(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=white"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=white"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c6(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=blue"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=blue"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c7(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=magenta"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=magenta"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c8(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=red"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=red"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c9(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=orange"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=orange"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c10(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=black"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=black"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c11(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=green"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=green"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c12(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=darkgray"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=darkgray"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c13(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=purple"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=purple"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c14(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=yellow"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=yellow"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c15(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=lightgray"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=lightgray"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    
    
    //**********************BUTTONS*************************************************//
    
    @objc func backactionnum(_ sender:UIButton)
    {
        let indexItem = Int(currentindex.item)
        let indexSection = Int(currentindex.section)
        let value = numberview.inputfield.text!
        
        
        if Double(value) != nil{
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            
            if numberview.width_height_selector.selectedSegmentIndex == 0{
                
                appd.sizeofwidth[indexItem] = Double(value)!
                
                if appd.sizeofwidth[indexItem] < 20{
                    appd.sizeofwidth[indexItem] = 20
                }
                
            }else{
                
                appd.sizeofheight[indexSection] = Double(value)!
                
                if appd.sizeofheight[indexItem] < 20{
                    appd.sizeofheight[indexItem] = 20
                }
                
            }
            
        }
        
        
        numberview.removeFromSuperview()
        
        saveuserD()
        
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "SettingsViewController" )
        self.present( targetViewController, animated: true, completion: nil)
        
        
        
        
    }
    
    @objc func plusAction(_ sender:UIButton)
    {
        let indexItem = Int(currentindex.item)
        let indexSection = Int(currentindex.section)
        var plus = 0
        let horrible = UserDefaults.standard
        
        if indexSection == 0{
            
            (location,content) = otherclass.horribleMethod4Col(tempArray: location,tempArrayContent: content, colInt: indexItem)
            
            
            plus = COLUMNSIZE+1
            
            horrible.set(plus, forKey: "NEWCsize")
            horrible.synchronize()
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.tag_int == 3{
                appd.sizeofwidth.insert(75.0, at: indexItem)
            }else{
                appd.sizeofwidth.insert(100.0, at: indexItem)
            }
            
            
        }else if indexItem == 0{
            
            (location,content) = otherclass.horribleMethod4Row(tempArray: location,tempArrayContent: content, rowInt: indexSection)
            
            
            plus = ROWSIZE+1
            
            
            horrible.set(plus, forKey: "NEWRsize")
            horrible.synchronize()
            
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.tag_int == 3{
                appd.sizeofheight.insert(30.0, at: indexSection)
            }else{
                appd.sizeofheight.insert(40.0, at: indexSection)
            }
            
        }
        
        
        
        
        
        horrible.set(location, forKey: "NEWTMLOCATION")
        horrible.synchronize()
        
        
        horrible.set(content, forKey: "NEWTMCONTENT")
        horrible.synchronize()
        
        let next = storyboard!.instantiateViewController(withIdentifier: "SettingsViewController")
        self.present(next,animated: true, completion: nil)
        
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
            appd.sizeofwidth.remove(at: indexItem)
            
        }else if indexItem == 0{
            
            (location,content) = otherclass.horribleMethod4RowMinus(tempArray: location,tempArrayContent: content, rowInt: indexSection)
            
            
            minus = ROWSIZE-1
            
            horrible.set(minus, forKey: "NEWRsize")
            horrible.synchronize()
            
            
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.sizeofheight.remove(at: indexSection)
            
        }
        
        
        
        horrible.set(location, forKey: "NEWTMLOCATION")
        horrible.synchronize()
        
        
        horrible.set(content, forKey: "NEWTMCONTENT")
        horrible.synchronize()
        
        let next = storyboard!.instantiateViewController(withIdentifier: "SettingsViewController")
        self.present(next,animated: true, completion: nil)
    }
    
    //    func Alphabet(itemnum : Int) ->String {
    //
    //        let tempInt = itemnum
    //        var letter1 = ""
    //
    //        let quotient = tempInt/26
    //
    //        let remainder = tempInt%26
    //        var letter2 = ""
    //
    //
    //        if tempInt > 26 {
    //
    //        switch quotient {
    //        case 0:
    //            letter1 = "Z"
    //        case 1:
    //            letter1 = "A"
    //        case 2:
    //            letter1 = "B"
    //        case 3:
    //            letter1 = "C"
    //        case 4:
    //            letter1 = "D"
    //        case 5:
    //            letter1 = "E"
    //        case 6:
    //            letter1 = "F"
    //        case 7:
    //            letter1 = "G"
    //        case 8:
    //            letter1 = "H"
    //        case 9:
    //            letter1 = "I"
    //        case 10:
    //            letter1 = "J"
    //        case 11:
    //            letter1 = "K"
    //        case 12:
    //            letter1 = "L"
    //        case 13:
    //            letter1 = "M"
    //        case 14:
    //            letter1 = "N"
    //        case 15:
    //            letter1 = "O"
    //        case 16:
    //            letter1 = "P"
    //        case 17:
    //            letter1 = "Q"
    //        case 18:
    //            letter1 = "R"
    //        case 19:
    //            letter1 = "S"
    //        case 20:
    //            letter1 = "T"
    //        case 21:
    //            letter1 = "U"
    //        case 22:
    //            letter1 = "V"
    //        case 23:
    //            letter1 = "W"
    //        case 24:
    //            letter1 = "X"
    //        case 25:
    //            letter1 = "Y"
    //
    //        default:
    //            letter1=""
    //        }
    //        }
    //
    //        switch remainder {
    //        case 0:
    //            letter2 = "Z"
    //        case 1:
    //            letter2 = "A"
    //        case 2:
    //            letter2 = "B"
    //        case 3:
    //            letter2 = "C"
    //        case 4:
    //            letter2 = "D"
    //        case 5:
    //            letter2 = "E"
    //        case 6:
    //            letter2 = "F"
    //        case 7:
    //            letter2 = "G"
    //        case 8:
    //            letter2 = "H"
    //        case 9:
    //            letter2 = "I"
    //        case 10:
    //            letter2 = "J"
    //        case 11:
    //            letter2 = "K"
    //        case 12:
    //            letter2 = "L"
    //        case 13:
    //            letter2 = "M"
    //        case 14:
    //            letter2 = "N"
    //        case 15:
    //            letter2 = "O"
    //        case 16:
    //            letter2 = "P"
    //        case 17:
    //            letter2 = "Q"
    //        case 18:
    //            letter2 = "R"
    //        case 19:
    //            letter2 = "S"
    //        case 20:
    //            letter2 = "T"
    //        case 21:
    //            letter2 = "U"
    //        case 22:
    //            letter2 = "V"
    //        case 23:
    //            letter2 = "W"
    //        case 24:
    //            letter2 = "X"
    //        case 25:
    //            letter2 = "Y"
    //
    //        default:
    //            letter2=""
    //        }
    //
    //        return letter1 + letter2
    //
    //    }
    
    @objc func copyText(){
        
        currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
        
        
        if location.contains(currentindexstr){
            let i = location.index(of: currentindexstr)
            stringboxText = content[i!]
            datainputview.stringbox.text = stringboxText
        }
        
    }
    
    @objc func terminate(){
        datainputview.stringbox.resignFirstResponder()
        datainputview.removeFromSuperview()
    }
    
    @objc func input(){
        
        otherclass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        
        
        math_content.removeAll()
        math_locations.removeAll()
        
        
        
        
        let element :String = datainputview.stringbox.text!
        let IP :String = currentindexstr   //String(currentindex!.item) + String(currentindex!.section)
        
        if location.contains(IP){
            let i = location.index(of: IP)
            content[i!] = element
            location[i!] = IP
            
        }else{
            content.append(element)
            location.append(IP)
        }
        
        
        
        
        myCollectionView.collectionViewLayout.invalidateLayout()
        DispatchQueue.main.async() {
            self.myCollectionView.reloadData() }
        
        stringboxText = element
        
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
    
    func saveuserF(){
        
        let location2 = UserDefaults.standard
        location2.set(bglocation, forKey: "NEWTMBGLOCATION")
        location2.synchronize()
        
        let content2 = UserDefaults.standard
        content2.set(bgcolor, forKey: "NEWTMBGCOLOR")
        content2.synchronize()
        
        let location3 = UserDefaults.standard
        location3.set(tlocation, forKey: "NEWTMTLOCATION")
        location3.synchronize()
        
        let content3 = UserDefaults.standard
        content3.set(tcolor, forKey: "NEWTMTCOLOR")
        content3.synchronize()
        
        
        
    }
    
    
    
    
    @objc func calculatormode(){
        
        math_content.removeAll()
        math_locations.removeAll()
        math_content2.removeAll()
        math_locations2.removeAll()
        
        let previousstr = currentindexstr
        
        
        calculatormode_update()
        
        
        
        currentindexstr = previousstr
        myCollectionView.collectionViewLayout.invalidateLayout()
        DispatchQueue.main.async() {
            self.myCollectionView.reloadData() }
        
        
    }
    
    
    @objc func calculatormode_update(){
        
        var tempStr = "sin(PI/4)^2"//"3*(3^-1)"//"sin(PI/3+PI/6)"//"((sin3)^2+(cos3)^2)"//"1/((1-0)/(2-0))"//"((30+3)*23-3)/5-1"//30 3 + 23 3 - *  count the number of
        
        var bool = false
        let restorestr = currentindexstr
        
        for h in 0..<3{
            
            for i in 0..<location.count {
                
                currentindexstr = location[i]
                tempStr = content[i]
                
                if h == 0{
                    tempStr = mathInterpret_update1_1(Textinput: tempStr)
                    tempStr = mathInterpret2_update1_1(Textinput: tempStr)
                }else{
                    tempStr = mathInterpret_update1_2(Textinput: tempStr)
                    tempStr = mathInterpret2_update1_2(Textinput: tempStr)
                    
                }
                
                
                let notgood = tempStr.suffix(1)
                if notgood == "^"{
                    bool = true
                    tempStr = ""
                }else if notgood == "/"{
                    bool = true
                    tempStr = ""
                }else if notgood == "*"{
                    bool = true
                    tempStr = ""
                }else if notgood == "-"{
                    bool = true
                    tempStr = ""
                }else if notgood == "+"{
                    bool = true
                    tempStr = ""
                }
                
                
                //Feb 9
                var elements = [String]()
                var bz_local = 0
                var startindex = -1
                
                var loopcounter = 10
                
                //PREPARATION
                tempStr = global2.REPLACE_WITH_CONSTANT(source: tempStr)
                
                //
                tempStr = tempStr.replacingOccurrences(of: ",", with: "")
                
                
                if tempStr.contains("]"){
                    
                    tempStr = tempStr.replacingOccurrences(of: "COLUMN[", with: " ")
                    tempStr = tempStr.replacingOccurrences(of: "]", with: " ")//これで中は数字だけcolumn[1]
                    
                    
                    
                    var preelements = tempStr.characters.split{$0 == " "}.map(String.init)
                    
                    for h in 0..<preelements.count {
                        
                        if Int(preelements[h]) != nil{
                            
                            if location.contains("[" + String(currentindex.section) + ", " + String(preelements[h]) + "]"){
                                
                                let j = location.index(of: "[" + String(currentindex.section) + ", " + String(preelements[h]) + "]")
                                
                                
                                var contentstr = content[j!].replacingOccurrences(of: ",", with: "")
                                
                                contentstr = contentstr.replacingOccurrences(of: " ", with: "")
                                
                                if Double(contentstr) != nil{
                                    preelements[h] = contentstr//content[j!]
                                    
                                }else{
                                    
                                    preelements[h] = ""
                                    bool = true
                                    
                                }
                                
                                
                            }else{//no available data
                                preelements[h] = ""
                                bool = true
                            }
                            
                            
                        }else{
                            
                        }
                        
                    }
                    
                    tempStr = preelements.joined()
                    
                    if bool == true{
                        tempStr = ""
                    }
                    
                }else{
                    
                }
                
                
                
                
                //Comma Free
                tempStr = tempStr.replacingOccurrences(of: ",", with: "")
                
                if tempStr.contains("(") {
                    
                }else{
                    loopcounter = 0
                }
                
                
                while loopcounter > 0  {
                    
                    
                    tempStr = tempStr.replacingOccurrences(of: "(", with: " ( ")
                    tempStr = tempStr.replacingOccurrences(of: ")", with: " ) ")//これで中は数字だけ
                    
                    elements = tempStr.characters.split{$0 == " "}.map(String.init)
                    bz_local = 0
                    startindex = -1
                    
                    for i in 0..<elements.count {
                        
                        if elements[i] == "(" {
                            bz_local += 1
                        }
                    }
                    
                    while bz_local > 0 {
                        
                        startindex = global2.BRACKET_INDEX(source: tempStr, bracketsize:bz_local)
                        elements[startindex] = global2.CALCULATION_OPERATION(source: elements[startindex])
                        
                        bz_local -= 1
                    }
                    
                    
                    if elements.count > 2 {//(9.5)->9.5
                        
                        for i in 2..<elements.count {
                            if elements[i] == ")" && elements[i-2] == "("{
                                elements[i] = "nil"
                                elements[i-2] = "nil"
                            }
                        }
                    }
                    
                    elements = elements.filter{$0 != "nil"}
                    
                    tempStr = elements.joined(separator: "")
                    
                    //ここでnext calculation (sin0.7853+1.75)、sin、sqrtを置換
                    tempStr = global2.SCIENTIFIC_OPERATION(source: tempStr)
                    
                    if Double(tempStr) != nil{
                        loopcounter = 0
                    }
                    loopcounter -= 1
                }
                
                
                //()がない場合も考えないといけない。その場合は
                if Double(tempStr) == nil{
                    
                    tempStr = global2.SCIENTIFIC_OPERATION(source: tempStr)
                    tempStr = global2.BASIC_OPERATION(source: tempStr)
                    
                    
                }
                else{
                    //Ok that's it
                }
                
                
                
                
                if Double(tempStr) != nil{
                    
                    //http://swift-salaryman.com/round.php
                    var calculated = Double(tempStr)! * 10000
                    calculated = round(calculated) / 10000
                    
                    let IP :String = location[i]   //String(currentindex!.item) + String(currentindex!.section)
                    
                    if math_locations.contains(IP){
                        let i2 = math_locations.index(of: IP)
                        
                        
                        math_content[i2!] = String(calculated)
                        math_locations[i2!] = IP
                        
                        
                    }else{
                        math_content.append(String(calculated))
                        math_locations.append(IP)
                    }
                    
                }else{
                    let IP :String = location[i]
                    if math_locations.contains(IP){
                        let i2 = math_locations.index(of: IP)
                        math_content[i2!] = content[i]
                        math_locations[i2!] = IP
                        
                        
                    }else{
                        math_content.append(content[i])
                        math_locations.append(IP)
                    }
                    
                }
                
            }//forloopend
            
        }//forloop3 end
        
        
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.exportContent = math_content
        appd.exportContent_location = math_locations
        
        currentindexstr = restorestr
        
    }
    
    
    
    func fonteditmode(){
        
        //let IP = IndexPath(row: currentindex.section, section: currentindex.section)
        let IP :String = currentindexstr
        
        if FONTEDIT.hasPrefix("bg="){
            if bglocation.contains(IP){
                let i = bglocation.index(of: IP)
                bgcolor.remove(at: i!)
                bglocation.remove(at: i!)
                
                
                
            }
            
            bglocation.append(IP)
            
            let value = FONTEDIT.replacingOccurrences(of: "bg=", with: "")
            bgcolor.append(value.replacingOccurrences(of: " ", with: ""))
            
        }else if FONTEDIT.hasPrefix("color="){
            
            if tlocation.contains(IP){
                let i = tlocation.index(of: IP)
                tcolor.remove(at: i!)
                tlocation.remove(at: i!)
                
                
                
            }
            
            tlocation.append(IP)
            
            let value2 = FONTEDIT.replacingOccurrences(of: "color=", with: "")
            tcolor.append(value2.replacingOccurrences(of: " ", with: ""))
            
            
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
        } else {
            
            orientaion = "P"
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
    
    
    //
    func mathInterpret(Textinput:String) -> String{
        
        //String(currentindex!.item) + String(currentindex!.section)
        let currentRow = currentindex.section
        var result = Textinput
        
        for i in 0..<columninNumber.count {
            if result.contains(columninNumber[i]){
                let tempindexItem = columninNumber.index(of: columninNumber[i])
                let IP = String(tempindexItem!) + "," + String(currentRow)
                if location.contains(IP){
                    let j = location.index(of: IP)
                    
                    result = result.replacingOccurrences(of: columninNumber[i], with: content[j!])
                    
                }
            }
        }
        
        return result
        
        
    }
    
    //
    func mathInterpret2(Textinput:String) -> String{
        
        //String(currentindex!.item) + String(currentindex!.section)
        let currentColumn = currentindex.item
        var result = Textinput
        
        
        for i in 0..<rowinNumber.count {
            if result.contains(rowinNumber[i]){
                
                let tempindexSection = rowinNumber.index(of: rowinNumber[i])
                let IP =  String(currentColumn) + "," + String(tempindexSection!)
                if location.contains(IP){
                    let j = location.index(of: IP)
                    
                    result = result.replacingOccurrences(of: rowinNumber[i], with: content[j!])
                    
                    
                }
            }
        }
        
        return result
        
        
    }
    
    
    
    func mathInterpret_update1_1(Textinput:String) -> String{
        
        //String(currentindex!.item) + String(currentindex!.section)
        var prep = currentindexstr.components(separatedBy: ",")
        prep[1] = prep[1].replacingOccurrences(of: "]", with: "")
        prep[1] = prep[1].replacingOccurrences(of: " ", with: "")
        let currentRow = Int(prep[1])!
        var result = Textinput
        
        for i in 0..<columninNumber.count {
            if result.contains(columninNumber[i]){
                
                let tempindexItem = columninNumber.index(of: columninNumber[i])
                let IP = String(tempindexItem!) + "," + String(currentRow)
                if location.contains(IP){
                    let j = location.index(of: IP)
                    
                    result = result.replacingOccurrences(of: columninNumber[i], with: content[j!])
                    
                }
                
            }
        }
        
        return result
        
        
    }
    
    func mathInterpret_update1_2(Textinput:String) -> String{
        
        //String(currentindex!.item) + String(currentindex!.section)
        var prep = currentindexstr.components(separatedBy: ",")
        prep[1] = prep[1].replacingOccurrences(of: "]", with: "")
        prep[1] = prep[1].replacingOccurrences(of: " ", with: "")
        let currentRow = Int(prep[1])!
        var result = Textinput
        
        for i in 0..<columninNumber.count {
            if result.contains(columninNumber[i]){
                
                let tempindexItem = columninNumber.index(of: columninNumber[i])
                let IP = String(tempindexItem!) + "," + String(currentRow)
                
                if math_locations.contains(IP){
                    
                    let j = math_locations.index(of: IP)
                    
                    result = result.replacingOccurrences(of: columninNumber[i], with: math_content[j!])
                    
                }
            }
        }
        
        return result
        
        
    }
    
    //
    func mathInterpret2_update1_1(Textinput:String) -> String{
        
        //String(currentindex!.item) + String(currentindex!.section)
        var prep = currentindexstr.components(separatedBy: ",")
        prep[0] = prep[0].replacingOccurrences(of: "[", with: "")
        prep[0] = prep[0].replacingOccurrences(of: " ", with: "")
        let currentColumn = Int(prep[0])!
        var result = Textinput
        
        
        for i in 0..<rowinNumber.count {
            if result.contains(rowinNumber[i]){
                
                let tempindexSection = rowinNumber.index(of: rowinNumber[i])
                let IP =  String(currentColumn) + "," + String(tempindexSection!)
                if location.contains(IP){
                    let j = location.index(of: IP)
                    
                    result = result.replacingOccurrences(of: rowinNumber[i], with: content[j!])
                }
                
            }
        }
        
        return result
        
        
    }
    
    func mathInterpret2_update1_2(Textinput:String) -> String{
        
        //String(currentindex!.item) + String(currentindex!.section)
        var prep = currentindexstr.components(separatedBy: ",")
        prep[0] = prep[0].replacingOccurrences(of: "[", with: "")
        prep[0] = prep[0].replacingOccurrences(of: " ", with: "")
        let currentColumn = Int(prep[0])!
        var result = Textinput
        
        
        for i in 0..<rowinNumber.count {
            if result.contains(rowinNumber[i]){
                
                let tempindexSection = rowinNumber.index(of: rowinNumber[i])
                let IP =  String(currentColumn) + "," + String(tempindexSection!)
                
                
                if math_locations.contains(IP){
                    
                    let j = math_locations.index(of: IP)
                    
                    result = result.replacingOccurrences(of: rowinNumber[i], with: math_content[j!])
                }
            }
        }
        
        return result
        
        
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
            
            if tempStr.count == 0{
                math_locations[i] = "null"
                math_content[i] = "null"
            }
            
            
            
            
        }
        
        return InputArray
    }
    
    func indexlabel(){
        
        let column = GetExcelColumnName(columnNumber: currentindex.item)
        let row = currentindex.section
        
        label.text = String(column)+String(row)
        
        if currentindex.item == 0{
            label.text = String(row)
        }
        
        if currentindex.section == 0{
            label.text = column
        }
    }
    
    func pastemodeChange(){
        switch pastemode {
        case false:
            
            let locationstr = Locale.current.languageCode!
            
            if locationstr == "ja"{
                pastemode_state.setTitle("入力", for: .normal)
            }else if locationstr == "fr"{
                pastemode_state.setTitle("Entrée", for: .normal)
            }else if locationstr == "zh"{
                pastemode_state.setTitle("输入", for: .normal)
            }else if locationstr == "de"{
                pastemode_state.setTitle("Eingang", for: .normal)
            }else if locationstr == "it"{
                pastemode_state.setTitle("Ingresso", for: .normal)
            }else if locationstr == "da"{
                pastemode_state.setTitle("Indtast data", for: .normal)
            }else if locationstr == "ru"{
                pastemode_state.setTitle("введите", for: .normal)
            }else if locationstr == "es"{
                pastemode_state.setTitle("Entrada", for: .normal)
            }else if locationstr == "sv"{
                pastemode_state.setTitle("Ange data", for: .normal)
            }else{
                pastemode_state.setTitle("Enter", for: .normal)
            }
            
            
            
            break
        case true:
            let locationstr = Locale.current.languageCode!
            
            if locationstr == "ja"{
                pastemode_state.setTitle("貼り付け", for: .normal)
            }else if locationstr == "fr"{
                pastemode_state.setTitle("Coller", for: .normal)
            }else if locationstr == "zh"{
                pastemode_state.setTitle("粘贴", for: .normal)
            }else if locationstr == "de"{
                pastemode_state.setTitle("Einfügen", for: .normal)
            }else if locationstr == "it"{
                pastemode_state.setTitle("Incolla", for: .normal)
            }else if locationstr == "da"{
                pastemode_state.setTitle("indsætte", for: .normal)
            }else if locationstr == "ru"{
                pastemode_state.setTitle("вставить", for: .normal)
            }else if locationstr == "es"{
                pastemode_state.setTitle("Pegar", for: .normal)
            }else if locationstr == "sv"{
                pastemode_state.setTitle("Klistra", for: .normal)
            }else{
                pastemode_state.setTitle("Paste", for: .normal)
            }
            
            
            
            break
            
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
        tlocation.removeAll()
        textsize.removeAll()
        sizelocation.removeAll()
        bgcolor.removeAll()
        bglocation.removeAll()
        
        
        
        
        
    }
    
   
    //
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            KEYBOARDLOCATION = keyboardHeight
            
        }
    }
    
    @objc func moveUp(){
        var newone = currentindex.section-1
        if newone < 1{
            newone = 2
        }
        currentindex = IndexPath(item: currentindex.item, section: newone)
        currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
        indexlabel()
        
        cursor = currentindexstr
        
        myCollectionView.reloadData()
    }
    @objc func moveDown(){
        var newone = currentindex.section+1
        if newone < 1{
            newone = 2
        }
        currentindex = IndexPath(item: currentindex.item, section: newone)
        currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
        indexlabel()
        
        cursor = currentindexstr
        myCollectionView.reloadData()
    }
    @objc func moveRight(){
        var newone = currentindex.item+1
        if newone < 1{
            newone = 1
        }
        currentindex = IndexPath(item: newone, section: currentindex.section)
        currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
        indexlabel()
        
        cursor = currentindexstr
        myCollectionView.reloadData()
    }
    @objc func moveLeft(){
        var newone = currentindex.item-1
        if newone < 1{
            newone = 1
        }
        currentindex = IndexPath(item: newone, section: currentindex.section)
        currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
        indexlabel()
        
        
        cursor = currentindexstr
        myCollectionView.reloadData()
    }
    
    func noInternet(){
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            
            COLUMNSIZE = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
            
            if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
                
                ROWSIZE = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
                
            }else{
                ROWSIZE = 20
            }
        }
        else
        {
            initString()
            
        }
        
        
        //
        if (UserDefaults.standard.object(forKey: "NEWTMLOCATION") != nil) {
            
            location = UserDefaults.standard.object(forKey: "NEWTMLOCATION") as! Array
          
            
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMCONTENT") != nil) {
            
            content = UserDefaults.standard.object(forKey: "NEWTMCONTENT") as! Array
           
            
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMBGLOCATION") != nil) {
            
            bglocation = UserDefaults.standard.object(forKey: "NEWTMBGLOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMBGCOLOR") != nil) {
            
            bgcolor = UserDefaults.standard.object(forKey: "NEWTMBGCOLOR") as! Array
        }
        
        
        if (UserDefaults.standard.object(forKey: "NEWTMTLOCATION") != nil) {
            
            tlocation = UserDefaults.standard.object(forKey: "NEWTMTLOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMTCOLOR") != nil) {
            
            tcolor = UserDefaults.standard.object(forKey: "NEWTMTCOLOR") as! Array
        }
        
        if location.count != content.count {
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            location.removeAll()
            content.removeAll()
            
            math_locations.removeAll()
            math_content.removeAll()
            
            math_locations2.removeAll()
            math_content2.removeAll()
            
            bglocation.removeAll()
            bgcolor.removeAll()
            
            
            tlocation.removeAll()
            sizelocation.removeAll()
            cursor = String()
            tcolor.removeAll()
            textsize.removeAll()
            
            initString()
        }
        
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
    
    func zipping(){
      
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let Name = "archived.zip"
        let filePath = URL(fileURLWithPath: paths).appendingPathComponent(Name).absoluteURL
        
      
        
        
        
        if let fileData = NSData(contentsOf: filePath) {
            print("cleared")
            clearTheFolder()
        }
        
        if let fileData = NSData(contentsOf: URL(fileURLWithPath: paths).appendingPathComponent("archived.xlsx").absoluteURL) {
            print("cleared")
            clearTheFolder()
        }
        
        
        if let fileData = NSData(contentsOf: URL(fileURLWithPath: paths).appendingPathComponent("testin2.xlsx")) {
            print("here file")
        }
        

        
        
        let url1 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filePath0 = URL(fileURLWithPath: url1).appendingPathComponent("testin2.xlsx").path
        print(filePath0)
        let success: Bool = SSZipArchive.unzipFile(atPath: filePath0,
                                                   toDestination: url1,
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
            removeX()
        
      
        } else {
            print("No success unzip")
        
            return
        }
        
        
        do {
          
            
            let filePath2 = URL(fileURLWithPath: url1).appendingPathComponent("archived.xlsx").path
            
            let success = SSZipArchive.createZipFile(atPath: filePath2,
                                                     withContentsOfDirectory: url1,
                                                     keepParentDirectory: false,
                                                     compressionLevel: -1,
                                                     password: nil,
                                                     aes: true,
                                                     progressHandler: nil)
            if success {
                print("Success zip")
                
                let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
                let myFilesPath = documentDirectoryPath.appending("")
                let files = FileManager.default.enumerator(atPath: myFilesPath)
                
                while let file = files?.nextObject() {
                    print("\(myFilesPath)/\(file)")
                }
               
            } else {
                print("No success zip")
               
            }
            // Zip
            
        }
        catch {
            print("Something went wrong")
        }
    }
    
    func clearTheFolder(){
                let fileManager = FileManager.default
        
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
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
            let filePath = URL(fileURLWithPath: url1).appendingPathComponent("testin2.xlsx")
            try fileManager.removeItem(at: filePath)
           
        }catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    
    
}

