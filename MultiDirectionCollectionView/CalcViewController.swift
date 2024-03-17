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
import CoreFoundation


class CalcViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate,UITextViewDelegate,MFMailComposeViewControllerDelegate,UICollectionViewDelegateFlowLayout,UIDocumentPickerDelegate,UIGestureRecognizerDelegate,GADBannerViewDelegate{
    
    @IBOutlet weak var calculatorButton: UIButton!
    @IBOutlet weak var bannerview: GADBannerView!
    @IBOutlet weak var fileTitle: UILabel!
    
    @IBOutlet weak var mailbutton: UIButton!
    
    
    var alphabetCounterPart = [String]()
    var KEYBOARDLOCATION = CGFloat()
    @objc var List: Array<AnyObject> = []
    
    var location = [String]()
    var content = [String]()
    
    var math_locations = [String]()
    var math_content = [String]()
    
    var math_locations2 = [String]()
    var math_content2 = [String]()
    
    var numberContent = [String]()
    var numberContentLocationInLetters = [String]()
    //mergedcells
    var nousecells = [[Int]]()
    
    var expression = ""
    var clipBoard = ""
    var columnNames = [String]()
    
    //Font location
    //    var bglocation = [String]()
    //    var tlocation = [String]()
    //    var sizelocation = [String]()
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
    
    var tag_int :Int!
    
    var current_range : NSRange!
    
    
    var stringboxText = ""
    var pastemode : Bool = false
    
    var f_content = [String]()
    var f_calculated = [String]()
    var f_location = [String]()
    
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
    
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    var calcboard :Calcboard!
    
    
    var calcdatainputview :CalcDatainputview!
    
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
        var rowsize = appd.DEFAULT_ROW_NUMBER//100
        
        if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
            let v = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
            if v > rowsize{
                rowsize = v
            }
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
        var columnsize = appd.DEFAULT_COLUMN_NUMBER //27
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            let v = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
            if v > columnsize{
                columnsize = v
            }
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
            
            let notFunc = content[i!].replacingOccurrences(of: "\"\"", with: "\n")
            
            
            
            if f_location.contains(String(indexPath.item)+","+String(indexPath.section)){
                let idx = f_location.index(of: String(indexPath.item)+","+String(indexPath.section))
                cell.label.text = f_calculated[idx!]
            }else{
                cell.label.text = notFunc
            }
            
            
        }else
        {
            cell.label.text = ""
        }
        
        
        //Textsize
        if location.contains(String(indexPath.item)+","+String(indexPath.section)){
            
            let i = location.index(of:String(indexPath.item)+","+String(indexPath.section))
            
            //http://stackoverflow.com/questions/27595799/convert-string-to-cgfloat-in-swift
            //http://stackoverflow.com/questions/24356888/how-do-i-change-the-font-size-of-a-uilabel-in-swift
            
            //something went wrong maybe fix it in future..maybe
            if location.count != textsize.count{
                textsize.removeAll()
                bgcolor.removeAll()
                tcolor.removeAll()
                for _ in 0..<location.count{
                    textsize.append("13")
                    bgcolor.append("white")
                    tcolor.append("black")
                }
            }
            let fl: CGFloat = CGFloat((textsize[i!] as NSString).doubleValue)
            cell.label.font = UIFont.systemFont(ofSize: fl)
            
        }else{
            
            let fl: CGFloat = CGFloat(("13" as NSString).doubleValue)
            
            cell.label.font = UIFont.systemFont(ofSize: fl)
        }
        
        
        //Calculation
        
        
        //Border
        if cursor == (String(indexPath.item)+","+String(indexPath.section)) || changeaffected.contains(String(indexPath.item)+","+String(indexPath.section))  {
            
            cell.label.layer.borderColor = UIColor(red: 255/255, green: 0/255, blue: 51/255, alpha: 1).cgColor
            cell.label.layer.borderWidth = 3.0
            
            
        }else{
            
            if f_location.contains(String(indexPath.item)+","+String(indexPath.section)){
                cell.label.layer.borderColor = UIColor(red: 0/255, green: 153/255, blue: 255/255, alpha: 1).cgColor
                cell.label.layer.borderWidth = 3.0
            }else{
                cell.label.layer.borderColor = UIColor.orange.cgColor
                cell.label.layer.borderWidth = 0.5
            }
        }
        
        
        //BG
        if location.contains(String(indexPath.item)+","+String(indexPath.section)){
            let i = location.index(of: String(indexPath.item)+","+String(indexPath.section))
            
            cell.label.backgroundColor = UIColor.white
            
            
            //textcolor
            if tcolor[i!] == "blue"{
                
                cell.label.textColor = UIColor(red: 51/255, green: 153/255, blue: 255/255, alpha: 1)
                
            }else if tcolor[i!] == "red"{
                
                cell.label.textColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)
                
            }else{
                cell.label.textColor = UIColor.black
            }
            
            
            
        }else{
            cell.label.backgroundColor = UIColor.white
            cell.label.textColor = UIColor.black
            
            if indexPath.item == 0{
                
                if indexPath.section > 0{
                    cell.label.text = String(indexPath.section)
                    rowinNumber.append("r" + cell.label.text!)
                }
                
                cell.label.backgroundColor = UIColor(red: 195/255, green: 255/255, blue: 255/255, alpha: 1)
                cell.label.textColor = UIColor.black
            }else if indexPath.section == 0{
                
                if indexPath.item > 0{//0,0 == greyzone
                    cell.label.text = GetExcelColumnName(columnNumber: indexPath.item)//ABCDE...
                    columninNumber.append(cell.label.text!)
                }
                
                
                cell.label.backgroundColor = UIColor(red: 195/255, green: 255/255, blue: 255/255, alpha:1)
                cell.label.textColor = UIColor.black
            }
        }
        
        
        
        
        
        
        //http://stackoverflow.com/questions/29381994/swift-check-string-for-nil-empty
        //http://qiita.com/satomyumi/items/b0d071cc906574086ac4
        
        
        return cell
        
        
    }
    
    
    //Hiding Keyboard
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            changeaffected.removeAll()
            
            //todo: replace a_E6↓6 syntax
            
            //sumFunc()
            
            input()
            saveuserD()
            saveuserF()
            stringboxText = ""
            return false
        }
        
        return true
    }
    
    func sumFunc (){
        
        var chaos = calcdatainputview.stringbox.text
        var product = "f_"
        
        var columnNames = [String]()
        for idx in 0..<COLUMNSIZE {
            let letters = GetExcelColumnName(columnNumber: idx)
            columnNames.append(letters)
        }
        
        if (chaos?.contains("a_"))! && (chaos?.contains("↓"))!{
            let arry = chaos?.replacingOccurrences(of: "a_", with: "").components(separatedBy: "↓")
            
            if arry!.count > 1{
                let variable = arry![0]//E4
                let number = arry![1]//6
                
                if columnNames.contains(alphabetOnlyString(text: variable)) && Int(number) != nil{
                    let l = alphabetOnlyString(text: variable)
                    let digits = numberOnlyString(text: variable)
                    
                    for idx in 0..<Int(number)!{
                        let n = Int(digits)!  + idx
                        
                        if idx == Int(number)!-1{
                            product = product + l + String(n)
                        }else{
                            product = product + l + String(n) + "+"
                        }
                    }
                    calcdatainputview.stringbox.text = product
                }else{
                    return
                }
                
            }
        } else if (chaos?.contains("a_"))! && (chaos?.contains("→"))!{
            let arry = chaos?.replacingOccurrences(of: "a_", with: "").components(separatedBy: "→")
            
            if arry!.count > 1{
                let variable = arry![0]//E4
                let number = arry![1]//6
                
                if columnNames.contains(alphabetOnlyString(text: variable)) && Int(number) != nil{
                    let l_l = columnNames.index(of: alphabetOnlyString(text: variable))
                    let l = alphabetOnlyString(text: variable)
                    let digits = numberOnlyString(text: variable)
                    
                    for idx in 0..<Int(number)!{
                        let n = Int(l_l!)  + idx
                        
                        if idx == Int(number)!-1{
                            product = product + GetExcelColumnName(columnNumber: n) + number
                        }else{
                            product = product + GetExcelColumnName(columnNumber: n) + number + "+"
                        }
                    }
                    calcdatainputview.stringbox.text = product
                }else{
                    return
                }
                
            }
        }else{
            return
        }
        
    }
    
    func alphabetOnlyString(text: String) -> String {
        let okayChars = Set("ABCDEFGHIJKLKMNOPQRSTUVWXYZ")
        return text.filter {okayChars.contains($0) }
    }
    
    func numberOnlyString(text: String) -> String {
        let okayChars = Set("1234567890")
        return text.filter {okayChars.contains($0) }
    }
    
    //Touching one of cells
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //reset change history
        changeaffected.removeAll()
        
        //pastemode abolish
        pastemode = false
        
        
        
        
        
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
            //no other choise
            opencalcdatainputview()
            opencalcdatainputview()
        }
        
    }
    
    
    
    //http://stackoverflow.com/questions/27674317/changing-cell-background-color-in-uicollectionview-in-swift
    
    func opencalcdatainputview(){
        //don't forget first call
        if calcdatainputview != nil{
            calcdatainputview.removeFromSuperview()
        }
        if orientaion == "P"{
            
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                // It's an iPhone
                
                //                        calcdatainputview = calcdatainputview(frame: CGRect(x:20,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 280,height: 60))
                //calcdatainputview = calcdatainputview(frame: CGRect(x:0,y:5, width: 320,height: 60))
                calcdatainputview = CalcDatainputview(frame: CGRect(x:Int(0),y:Int(SCREENSIZE - KEYBOARDLOCATION - 85.0), width: 320,height: 85))
                calcdatainputview.downArrow.addTarget(self, action: #selector(imoveDown), for: UIControlEvents.touchUpInside)
                calcdatainputview.rightArrow.addTarget(self, action: #selector(imoveRight), for: UIControlEvents.touchUpInside)
                
                break
            case .pad:
                // It's an iPad
                calcdatainputview = CalcDatainputview(frame: CGRect(x:Int(SCREENSIZE_w*0.5-210),y:Int(SCREENSIZE - KEYBOARDLOCATION - 85.0), width: 420,height: 85))
                
                calcdatainputview.downArrow.addTarget(self, action: #selector(moveDown), for: UIControlEvents.touchUpInside)
                calcdatainputview.rightArrow.addTarget(self, action: #selector(moveRight), for: UIControlEvents.touchUpInside)
                
                
                break
            case .unspecified:
                // Uh, oh! What could it be?
                //calcdatainputview = calcdatainputview(frame: CGRect(x:20,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 280,height: 60))
                
                calcdatainputview = CalcDatainputview(frame: CGRect(x:Int(0),y:Int(SCREENSIZE - KEYBOARDLOCATION - 85.0), width: 320,height: 85))
                
                break
            default:
                break
            }
            
        }else if orientaion == "L"{
            
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                // It's an iPhone
                
                calcdatainputview = CalcDatainputview(frame: CGRect(x:0,y:5, width: 320,height: 60))
                calcdatainputview.downArrow.addTarget(self, action: #selector(imoveDown), for: UIControlEvents.touchUpInside)
                calcdatainputview.rightArrow.addTarget(self, action: #selector(imoveRight), for: UIControlEvents.touchUpInside)
                
                break
            case .pad:
                // It's an iPad
                calcdatainputview = CalcDatainputview(frame: CGRect(x:Int(SCREENSIZE_w*0.5-210),y:Int(SCREENSIZE - KEYBOARDLOCATION - 84.0), width: 420,height: 85))
                
                calcdatainputview.downArrow.addTarget(self, action: #selector(ViewController.moveDown), for: UIControlEvents.touchUpInside)
                calcdatainputview.rightArrow.addTarget(self, action: #selector(ViewController.moveRight), for: UIControlEvents.touchUpInside)
                
                break
            case .unspecified:
                // Uh, oh! What could it be?
                calcdatainputview = CalcDatainputview(frame: CGRect(x:20,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 385,height: 85))
                
                break
            default:
                break
            }
            
        }
        
        up_bool = false
        down_bool = false
        right_bool = false
        left_bool = false
        
        
        calcdatainputview.stringbox.delegate = self
        calcdatainputview.stringbox.layer.borderWidth = 1
        calcdatainputview.stringbox.layer.borderColor = UIColor.gray.cgColor
        calcdatainputview.returnButton.addTarget(self, action: #selector(copyText2), for: UIControlEvents.touchUpInside)
        calcdatainputview.closeButton.addTarget(self, action: #selector(close), for: UIControlEvents.touchUpInside)
        calcdatainputview.copyButton.addTarget(self, action: #selector(getIdx), for: UIControlEvents.touchUpInside)
        calcdatainputview.appendButton.addTarget(self, action: #selector(append), for: UIControlEvents.touchUpInside)
        calcdatainputview.stringbox.becomeFirstResponder()
        
        self.view.addSubview(calcdatainputview)
        
        
        //http://studyswift.blogspot.jp/2015/01/showhide-keyboard-while-using.html
        
        
        
        //https://stackoverflow.com/questions/46375700/programmatically-create-touchupinside-event-for-uitextfield
        
        
        calcdatainputview.stringbox.text = stringboxText
        
        //calcdatainputview.stringbox.text = expression
        
        
        for idx in 0..<COLUMNSIZE {
            let letters = GetExcelColumnName(columnNumber: idx)
            columnNames.append(letters)
        }
        
        myCollectionView.reloadData()
        
    }
    
    
    
    
    
    override func viewDidLoad() {
        
        calculatorButton.layer.borderWidth = 1.0
        myCollectionView.layer.borderWidth = 1.0
        myCollectionView.layer.borderColor = UIColor.gray.cgColor
        mailbutton.layer.borderWidth = 0.5
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let locationstr = Locale.current.languageCode!
        
        if locationstr == "ja"{
            
            mailbutton.setTitle("Eメール", for: .normal)
        }else if locationstr == "fr"{
            
            mailbutton.setTitle("email" , for: .normal)
        }else if locationstr == "zh"{
            
            mailbutton.setTitle("邮件", for: .normal)
        }else if locationstr == "de"{
            
            mailbutton.setTitle("email" , for: .normal)
        }else if locationstr == "it"{
            
            mailbutton.setTitle("email", for: .normal)
        }else if locationstr == "da"{
            
            mailbutton.setTitle("email", for: .normal)
        }else if locationstr == "ru"{
            
            mailbutton.setTitle("почта", for: .normal)
        }else if locationstr == "es"{
            
            mailbutton.setTitle("correo", for: .normal)
        }else if locationstr == "sv"{
            
            mailbutton.setTitle("epost", for: .normal)
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
        bannerview.load(GADRequest())
        
        Thread.sleep(forTimeInterval: 0.5)
        let pointA = CGPoint.init(x: 600, y: 600)
        myCollectionView.setContentOffset(pointA, animated: true)
        myCollectionView.scrollToNextItem()
        
        //Preperation for Calc
        calculatormode_update()
        fileTitle.text = appd.viewconSelectedName
        
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
        
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "SearchView" )
        self.present( targetViewController, animated: true, completion: nil)
        
    }
    
    
    //http://code-examples-ja.hateblo.jp/entry/2016/09/21/Swift3
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
    @IBAction func excelExport(_ sender: Any) {
        test_format_calc()
        sleep(1)
        csvEmail_calc()
    }
    
    func test_format_calc(){
        
        
        for idx in 0..<f_location.count {
            if location.contains(f_location[idx]){
                let idxl = location.index(of: f_location[idx])
                content[idxl!] = f_calculated[idx]
            }
        }
        
        
        if content != []{
            
            if content.count != bgcolor.count || content.count != tcolor.count || content.count != textsize.count {
                bgcolor.removeAll()
                tcolor.removeAll()
                textsize.removeAll()
                
                for _ in 0..<content.count{
                    bgcolor.append("white")
                    textsize.append("10")
                    tcolor.append("black")
                }
                
            }
            for idx in 0..<content.count{
                if content[idx].count == 0 || content[idx] == ""{
                    // you are fool... content.remove(at idx);
                    location[idx] = ""
                    bgcolor[idx] = ""
                    tcolor[idx] = ""
                    textsize[idx] = ""
                }
            }
            
            //filter function
            content = content.filter(){$0 != ""}
            location = location.filter(){$0 != ""}
            bgcolor = bgcolor.filter(){$0 != ""}
            tcolor = tcolor.filter(){$0 != ""}
            textsize = textsize.filter(){$0 != ""}
        }
    }
    
    func csvEmail_calc() {
        csvexport_calc()
        if MFMailComposeViewController.canSendMail() {
            let today: Date = Date()
            let dateFormatter: DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            let date = dateFormatter.string(from: today)
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            
            mail.setSubject("from XLSV")
            
            //csv
            mail.addAttachmentData(data!, mimeType: "text/csv", fileName: date + "calc" + ".csv")
            
            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }
    
    @objc func csvexport_calc()
    {
        
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
    
    
    @IBAction func show3(_ sender: AnyObject) {
        
        if calcboard != nil{
            
            calcboard.removeFromSuperview()
        }
        
        switch tag_int {
        case 0:
            calcboard = Calcboard(frame: CGRect(x:5,y:50, width: 250,height: 150))
            break
        case 1:
            calcboard = Calcboard(frame: CGRect(x:5,y:50, width: 250,height: 150))
            break
        case 2:
            calcboard = Calcboard(frame: CGRect(x:5,y:50, width: 250,height: 150))
            break
        case 3:
            calcboard = Calcboard(frame: CGRect(x:5,y:10, width: 250,height: 150))
            break
        case 4:
            calcboard = Calcboard(frame: CGRect(x:5,y:200, width: 250,height: 150))
            break
        case 5:
            calcboard = Calcboard(frame: CGRect(x:5,y:190, width: 250,height: 150))
            break
            
            
            
            
            
        default:
            calcboard = Calcboard(frame: CGRect(x:5,y:150, width: 235,height: 130))
            break
            
        }
        
        
        
        
        calcboard.layer.borderWidth = 1
        
        calcboard.layer.cornerRadius = 8;
        
        calcboard.clearbutton.contentHorizontalAlignment = .left
        calcboard.executebutton.contentHorizontalAlignment = .left
        
        calcboard.layer.borderColor = UIColor.black.cgColor
        
        calcboard.closeboard.addTarget(self, action: #selector(close2), for: UIControlEvents.touchUpInside)
        
        
        calcboard.backbutton.addTarget(self, action: #selector(back2(_:)), for: UIControlEvents.touchUpInside)
        
        //calcboard.csvbutton.addTarget(self, action: #selector(saveCalculated), for: UIControlEvents.touchUpInside)
        
        calcboard.clearbutton.addTarget(self, action: #selector(clearResults), for: UIControlEvents.touchUpInside)
        
        calcboard.executebutton.addTarget(self, action: #selector(calculatormode_update), for: UIControlEvents.touchUpInside)
        
        //calcboard.replaceokbutton.addTarget(self, action: #selector(replace), for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(calcboard)
    }
    
    
    func numberviewopen() {
        
        
    }
    
    func saveCalculated(){
        //        //you know about id? it's identical. must be an unique.
        //        for idx in 0..<f_location.count {
        //            if location.contains(f_location[idx]){
        //                let idxC = location.index(of: f_location[idx])
        //                content[idxC!] = f_calculated[idx]
        //            }
        //        }
        //        saveuserD()
        //        myCollectionView.reloadData()
    }
    
    @objc func clearResults(){
        //goodbye
        f_content.removeAll()
        f_calculated.removeAll()
        f_location.removeAll()
        
        myCollectionView.reloadData()
    }
    
    @objc func close2(_ sender:UIButton){
        self.calcboard.removeFromSuperview()
    }
    
    @objc func back2(_ sender:UIButton)
    {
        saveJSONAction_calc()
        
        
        
        
    }
    
    @objc func saveAsLocalJson_calc(filename:String) {
        
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
                                   "cchLocation": appDelegate.cshLocation]
        
        
        let test = ReadWriteJSON()
        test.saveJsonFile(source: dict, title: filename)
        
        
        
    }
    
    //*********************//
    
    
    //**********************BUTTONS*************************************************//
    
    @objc func backactionnum(_ sender:UIButton)
    {
        
        
        
    }
    
    @objc func plusAction(_ sender:UIButton)
    {
        
    }
    
    
    @objc func close(_ sender:UIButton)
    {
        calcdatainputview.removeFromSuperview()
    }
    
    @objc func append(){
        expression =  calcdatainputview.stringbox.text
        if expression.hasPrefix("f_"){
            
        }else{
            expression = "f_" + expression
        }
        calcdatainputview.stringbox.text = expression
    }
    @objc func getIdx(){
        
        currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
        
        
        
        let column = GetExcelColumnName(columnNumber: currentindex.item)
        let row = currentindex.section
        
        var labelStr = String(column)+String(row)
        
        if currentindex.item == 0{
            labelStr = String(row)
        }
        
        if currentindex.section == 0{
            labelStr = column
        }
        
        
        calcdatainputview.stringbox.text =  labelStr
        
        stringboxText = labelStr
        
        
        
        
        //        if location.contains(currentindexstr){
        //            let i = location.index(of: currentindexstr)
        //            stringboxText = content[i!]
        //            calcdatainputview.stringbox.text = stringboxText
        //        }
        
    }
    
    @objc func copyText2(){
        currentindexstr = String(currentindex!.item)+","+String(currentindex!.section)
        if location.contains(currentindexstr){
            let i = location.index(of: currentindexstr)
            stringboxText = content[i!]
            calcdatainputview.stringbox.text = stringboxText
        }
        
    }
    
    @objc func terminate(){
        saveuserD()
        saveuserF()
        calcdatainputview.stringbox.resignFirstResponder()
        calcdatainputview.removeFromSuperview()
    }
    
    @objc func input(){
        
        otherclass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        
        
        math_content.removeAll()
        math_locations.removeAll()
        
        let element :String = calcdatainputview.stringbox.text!
        let IP = currentindexstr   //String(currentindex!.item) + String(currentindex!.section)
        let t_item = IP!.components(separatedBy: ",")[0]
        let t_section = IP!.components(separatedBy: ",")[1]
        
        let IP_i = Int(t_item)!
        let IP_s = Int(t_section)!
        
        
        
        //20200502
        //storeInput(IPd: IP, elementd: element) implement this function in iphone too? i dont know it is a good idea
        var padAry = element.components(separatedBy: "↓")//7,2 replac, loop
        var collocation = -1
        //print(padAry)
        if Int(padAry.last!) == nil{
            padAry = element.components(separatedBy: "→")
            if columnNames.index(of: padAry[0]) != nil{
                collocation = columnNames.index(of: padAry[0])!
            }
            
        }
        
        //
        let i = location.index(of: IP!)
            expression = ""
        if content[i!] != nil{
            expression = content[i!]
        }
        

        if padAry.count == 2 && Int(numberOnlyString(text:expression)) != nil{
         
            let loop = Int(padAry[1])
            let tgt = Int(padAry[0])
            
            if down_bool && loop != nil{
                for idx in 0..<loop!{
                    let IPl = t_item + "," + String(IP_s+idx)
                    if IP_s+idx <= 0 {
                        //it's
                    }else{
                      
                        let nextRow = tgt! + idx
                        let each = expression.replacingOccurrences(of: padAry[0], with: String(nextRow))
                        storeInput(IPd: IPl, elementd: each)
                    }
                }
            }
            else if right_bool && Int(padAry.last!) != nil && collocation != -1{
                let loop = Int(padAry[1])
                let tgt = collocation
                
                for idx in 0..<loop!{
                    let IPl = String(IP_i+idx) + "," + t_section
                    if IP_i+idx <= 0 {
                        //it's
                    }else{
                        let nextColumn = tgt + idx
                        let nextColumnLetters = GetExcelColumnName(columnNumber: nextColumn)
                        let each = expression.replacingOccurrences(of: padAry[0], with: nextColumnLetters)
                        storeInput(IPd: IPl, elementd: each)
                        print(each)
                    }
                }
            }
        
        }else{
            storeInput(IPd: IP!, elementd: element)
        }
        
        calculatormode_update()
        
        DispatchQueue.main.async() {
            self.myCollectionView.reloadData()
            //self.myCollectionView.collectionViewLayout.invalidateLayout()
        }
        
        stringboxText = element
        
    }
    
    func storeInput(IPd:String, elementd:String)
    {
        if location.contains(IPd){
            let i = location.index(of: IPd)
            if content[i!] != elementd{
                changeaffected.append(IPd)
            }
            content[i!] = elementd
            location[i!] = IPd
            
            
            
            
        }else{
            content.append(elementd)
            location.append(IPd)
            
            //updated
            textsize.append("10")
            bgcolor.append("white")
            tcolor.append("black")
            changeaffected.append(IPd)
        }
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
    
    
    
    
    
    
    
    @objc func calculatormode_update(){
        calcPrep()
        
        f_content.removeAll()
        f_calculated.removeAll()
        f_location.removeAll()
        //search formula content
        for idx in 0..<content.count {
            if content[idx].contains("f_"){
                f_content.append(content[idx].replacingOccurrences(of: "f_", with: ""))
                f_location.append(location[idx])
            }
        }
        
        
        var tempStr = "sin(PI/4)^2"//"3*(3^-1)"//"sin(PI/3+PI/6)"//"((sin3)^2+(cos3)^2)"//"1/((1-0)/(2-0))"//"((30+3)*23-3)/5-1"//30 3 + 23 3 - *  count the number of
        
        for i in 0..<f_content.count {
            
            let noAnswer = f_content[i]
            tempStr = replaceVariables(chaos: f_content[i])
            
            tempStr = rejectCapitalLetters(chaos: tempStr)
            //print(tempStr, "tempStr")
            //filter
            
            
            let notgood = tempStr.suffix(1)
            if notgood == "^"{
                
                tempStr = ""
            }else if notgood == "/"{
                
                tempStr = ""
            }else if notgood == "*"{
                
                tempStr = ""
            }else if notgood == "-"{
                
                tempStr = ""
            }else if notgood == "+"{
                
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
                //print(calculated, "final answer")
                f_calculated.append(String(calculated))
                
            }else{
                print("noAnswer")
                f_calculated.append(noAnswer)
            }
            
        }//forloopend
        
        myCollectionView.reloadData()
        
    }
    
    
    
    func fonteditmode(){
        
    }
    
    
    func deleteall(){
        
        calcdatainputview.stringbox.text=""
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
        
    }
    @objc func moveDown(){
        down_bool = !down_bool
        up_bool = false
        right_bool = false
        left_bool = false
        
        expression =  calcdatainputview.stringbox.text + "↓"
        calcdatainputview.stringbox.text = expression
        
        calcdatainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        
        if down_bool {
            calcdatainputview.downArrow.setImage(UIImage(named: "downArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }else if !down_bool{
            calcdatainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
    }
    @objc func imoveDown(){
        down_bool = true
        up_bool = false
        right_bool = false
        left_bool = false
        
        expression =  calcdatainputview.stringbox.text + "↓"
        calcdatainputview.stringbox.text = expression
        
        
        
        
        calcdatainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        if down_bool {
            calcdatainputview.downArrow.setImage(UIImage(named: "downArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }else if !down_bool{
            calcdatainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
    }
    @objc func moveRight(){
        right_bool = !right_bool
        down_bool = false
        up_bool = false
        left_bool = false
        
        expression = calcdatainputview.stringbox.text + "→"
        calcdatainputview.stringbox.text = expression
        
        calcdatainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        
        
        if right_bool {
            calcdatainputview.rightArrow.setImage(UIImage(named: "rightArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }else if !right_bool{
            calcdatainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
    }
    @objc func imoveRight(){
        right_bool = !right_bool
        down_bool = false
        up_bool = false
        left_bool = false
        
        expression = calcdatainputview.stringbox.text + "→"
        calcdatainputview.stringbox.text = expression
        
        calcdatainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        if right_bool {
            calcdatainputview.rightArrow.setImage(UIImage(named: "rightArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }else if !right_bool{
            calcdatainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
    }
    @objc func moveLeft(){
        
        
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
        
        
        if (UserDefaults.standard.object(forKey: "NEWTMBGCOLOR") != nil) {
            
            bgcolor = UserDefaults.standard.object(forKey: "NEWTMBGCOLOR") as! Array
        }
        
        
        if (UserDefaults.standard.object(forKey: "NEWTMTCOLOR") != nil) {
            
            tcolor = UserDefaults.standard.object(forKey: "NEWTMTCOLOR") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMSIZE") != nil) {
            
            textsize = UserDefaults.standard.object(forKey: "NEWTMSIZE") as! Array
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
            
            for _ in 0..<location.count{
                bgcolor.append("white")
                textsize.append("10")
                tcolor.append("black")
            }
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
    
    
    
    
    //    func alphabetLettersCounterPart(){
    //
    //        var columnSize = 0
    //
    //        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
    //            columnSize = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
    //        }
    //
    //        for idx in 0..<columnSize  {
    //            alphabetCounterPart.append(GetExcelColumnName(columnNumber: idx))
    //        }
    //
    //        if alphabetCounterPart.count > 0{
    //            alphabetCounterPart[0] = "NULL"
    //        }
    //    }
    
    //in update_calculated
    func replaceVariables(chaos:String) -> String{
        var temp = chaos
        
        for idx in 0..<numberContentLocationInLetters.count {
            let noComma = numberContentLocationInLetters[idx].replacingOccurrences(of: ",", with: "")
            if temp.contains(noComma){
                temp = temp.replacingOccurrences(of: noComma, with: numberContent[idx])
            }
        }// don't know how many times should I do this. -> you know. one time.
        
        temp = temp.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: "¥", with: "").replacingOccurrences(of: "€", with: "")
        
        return temp
    }
    
    func rejectCapitalLetters(chaos:String) -> String{
        let capitalLetterRegEx = ".*[A-Z]+.*"
        let exist = NSPredicate(format: "SELF MATCHES %@", capitalLetterRegEx).evaluate(with: chaos)
        if exist {
            return ""
        }else{
            return chaos
        }
    }
    
    
    
    func calcPrep(){
        numberContentLocationInLetters.removeAll()
        numberContent.removeAll()
        
        for idx in 0..<content.count {
            let checkit = content[idx].replacingOccurrences(of: "¥", with: "").replacingOccurrences(of: "$", with: "").replacingOccurrences(of: "€", with: "")
            if Double(checkit) != nil{
                numberContent.append(content[idx])//4
                
                let number = location[idx].components(separatedBy: ",")[0]
                let number2 = location[idx].components(separatedBy: ",")[1]
                let intnumber = Double(number)
                let alphabets = GetExcelColumnName(columnNumber: Int(intnumber!))
                let each = String(alphabets + "," + number2)
                numberContentLocationInLetters.append(each)//A2
            }
        }
    }
    
    
    @objc func saveJSONAction_calc(){
        
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
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        alert.textFields![0].text = appd.viewconSelectedName
        
        
        let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
            let name = alert.textFields![0].text
            
            appd.viewconSelectedName = ""
            
            if name!.count > 0 {
                self.saveAsLocalJson_calc(filename:name!)
                self.resetAll()
            }
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" )
            self.present( targetViewController, animated: true, completion: nil)
        })
        
        let nilAction = UIAlertAction(title: no, style: .default, handler: {action in
            
            self.resetAll()
            
            appd.viewconSelectedName = ""
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" )
            self.present( targetViewController, animated: true, completion: nil)
        })
        alert.addAction(confirmAction)
        alert.addAction(nilAction)
        
        self.present(alert, animated: true)
        
        
        appd.viewconSelectedName = ""
        
        
        
        self.calcboard.removeFromSuperview()
        
        
        
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
        appd.JSON.removeAll()
        appd.currentDir.removeAll()
        appd.mergedCellListJSON.removeAll()
        appd.nousecells.removeAll()
        appd.cswLocation.removeAll()
        appd.cshLocation.removeAll()
        appd.customSizedWidth.removeAll()
        appd.customSizedHeight.removeAll()
        
        saveuserD()
        saveuserF()
        
    }
    
    
}


