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


class SearchController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate,UITextViewDelegate,MFMailComposeViewControllerDelegate,UICollectionViewDelegateFlowLayout,UIDocumentPickerDelegate,UIGestureRecognizerDelegate,GADBannerViewDelegate{
    
    @IBOutlet weak var bannerview: GADBannerView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var enterButton: UIButton!
    @IBOutlet weak var pageButton: UIButton!
    @IBOutlet weak var fileTitle: UILabel!
    
    
    var KEYBOARDLOCATION = CGFloat()
    @objc var List: Array<AnyObject> = []
    
    var location_s = [String]()
    var content_s = [String]()
    
    //mergedcells
    var nousecells = [[Int]]()
    
    var currentindex : IndexPath!
    var currentindexstr : String!
    
    //Font location_s
    var bglocation_s = [String]()
    var tlocation_s = [String]()
    var sizelocation_s = [String]()
    var cursor = String()

    var tcolor_s = [String]()
    var textsize_s = [String]()
    var bgcolor_s = [String]()
    
    var columninNumber = [String]()
    var rowinNumber = [String]()
    
    var COLUMNSIZE_s = 0
    var ROWSIZE_s = 0
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
    
    //
    var search_text = ""
    var replace_text = ""
    var csview = false
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    
    
    @IBOutlet weak var pastemode_state: UIButton!
    
    var customview3 :Customview3!
    
    //forexport
    var data: Data? = nil
    var byproduct: NSMutableString? = nil

    
    
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
        
        
        
        ROWSIZE_s = rowsize
        
        
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
        
        COLUMNSIZE_s = columnsize
        
        appd.numberofColumn = columnsize
        
        return columnsize
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CustomCollectionViewCell
        
        var cell_content_s = ""
        
        cell.label2!.lineBreakMode = .byWordWrapping // or NSLineBreakMode.ByWordWrapping
        cell.label2!.numberOfLines = 0
        
        //content_s
        if location_s.contains(String(indexPath.item)+","+String(indexPath.section)){
            
            let i = location_s.index(of: String(indexPath.item)+","+String(indexPath.section))
            
            cell.label2!.text = content_s[i!].replacingOccurrences(of: "\"\"", with: "\n")
            
            cell_content_s = content_s[i!].replacingOccurrences(of: "\"\"", with: "\n")
            cell.label2?.textAlignment = .center
            
            
        }else
        {
            cell.label2!.text = ""
     
        }
        
        
        //Textsize
        if location_s.contains(String(indexPath.item)+","+String(indexPath.section)){
            
            let i = location_s.index(of:String(indexPath.item)+","+String(indexPath.section))
            
            //http://stackoverflow.com/questions/27595799/convert-string-to-cgfloat-in-swift
            //http://stackoverflow.com/questions/24356888/how-do-i-change-the-font-size-of-a-uilabel-in-swift
            let fl: CGFloat = CGFloat((textsize_s[i!] as NSString).doubleValue)
            
            //cell.label2!.font = cell.label2!.font.withSize(fl)
            cell.label2!.font = UIFont.systemFont(ofSize: fl)
            
        }else{
            
            let fl: CGFloat = CGFloat(("13" as NSString).doubleValue)
            
            cell.label2!.font = UIFont.systemFont(ofSize: fl)
        }
        
        
        
        //Border
        if cursor == (String(indexPath.item)+","+String(indexPath.section)){
            
            cell.label2!.layer.borderColor = UIColor.red.cgColor
            cell.label2!.layer.borderWidth = 4.0
        }else{
            cell.label2!.layer.borderColor = UIColor.orange.cgColor
            cell.label2!.layer.borderWidth = 0.5
        }
        
        
        //BG
        cell.label2!.backgroundColor = UIColor.white
        cell.label2!.textColor = UIColor.black
            
            if indexPath.item == 0{
                
                if indexPath.section > 0{
                    cell.label2!.text = String(indexPath.section)
                    rowinNumber.append("r" + cell.label2!.text!)
                }
                
                cell.label2!.backgroundColor = UIColor(red: 195/255, green: 255/255, blue: 255/255, alpha:1)
                cell.label2!.textColor = UIColor.black
                cell.label2?.textAlignment = .center
            }else if indexPath.section == 0{
                
                if indexPath.item > 0{//0,0 == greyzone
                    cell.label2!.text = GetExcelColumnName(columnNumber: indexPath.item)//ABCDE...
                    columninNumber.append(cell.label2!.text!)
                }
                
                
                cell.label2!.backgroundColor = UIColor(red: 195/255, green: 255/255, blue: 255/255, alpha:1)
                cell.label2!.textColor = UIColor.black
                cell.label2?.textAlignment = .center
            }else{
                // BG
                if csview == false {
                    if cell_content_s == search_text && search_text != "" {
                        cell.label2!.backgroundColor = UIColor.magenta
                    }else{
                        cell.label2!.backgroundColor = UIColor.white
                    }
                    
                }else if csview == true{
                    if cell_content_s.contains(search_text) && search_text != "" {
                        cell.label2!.backgroundColor = UIColor.yellow
                    }else{
                        cell.label2!.backgroundColor = UIColor.white
                    }
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
            
            saveuserD_search()
            saveuserF()
            return false
        }
        
        return true
    }
    
    
    //Touching one of cells
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { }
    
    
    
    //http://stackoverflow.com/questions/27674317/changing-cell-background-color-in-uicollectionview-in-swift
    

    
    @objc func back2(_ sender:UIButton)
    {
        saveJSONAction_search()
        
    }
    
    @objc func close(){
        self.customview3.removeFromSuperview()
    }
    
    
    
    @objc func localsave(_ sender:UIButton)
    {
        //       postAction()
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "creditView" )
        self.present( targetViewController, animated: true, completion: nil)
        
        self.customview3.removeFromSuperview()
    }
    
    @objc func reset(_ sender:UIButton)
    {
        
        location_s.removeAll()
        content_s.removeAll()
        
       
        
        bglocation_s.removeAll()
        bgcolor_s.removeAll()
        
        
        tlocation_s.removeAll()
        sizelocation_s.removeAll()
        cursor = String()
        tcolor_s.removeAll()
        textsize_s.removeAll()
        
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
        
        self.customview3.removeFromSuperview()
    }
    
    
    @objc func localload(_ sender:UIButton)
    {
        
        location_s.removeAll()
        content_s.removeAll()
        
        //Font location_s
        bglocation_s.removeAll()
        tlocation_s.removeAll()
        sizelocation_s.removeAll()
        
        
        tcolor_s.removeAll()
        textsize_s.removeAll()
        bgcolor_s.removeAll()
        
        
        self.customview3.removeFromSuperview()
        
        performSegue(withIdentifier: "previousData", sender: nil)
        
        //let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "localsaveandload" )
        //self.present( targetViewController, animated: true, completion: nil)
        
        
    }
    
    
    @objc func icloudview(_ sender:UIButton){
        
        var message = "Current data will be lost. Is that ok?"
        var yes = "OK"
        var no = "No"
        let location_sstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if location_sstr.contains( "ja")
        {
            message = "現在のデータは失われます。それは大丈夫ですか？"
            yes = "はい"
            no = "いいえ"
        }else if location_sstr.contains( "fr")
        {
            message = "Les données actuelles seront perdues. Est-ce que ça va?"
            yes = "oui"
            no = "non"
        }else if location_sstr.contains( "zh"){
            
            message = "当前数据将丢失。这可以吗？"
            yes = "是"
            no = "否"
        }else if location_sstr.contains( "de")
        {
            
            message = "Aktuelle Daten gehen verloren. Ist das in Ordnung?"
            yes = "ja"
            no = "nein"
        }else if location_sstr.contains( "it")
        {
            
            message = "I dati attuali andranno persi. È ok?"
            yes = "si"
            no = "no"
        }else if location_sstr.contains( "ru")
        {
            
            message = "Текущие данные будут потеряны. Это нормально?"
            yes = "да"
            no = "нет"
        }else if location_sstr.contains("sv")
        {
            message = "Nuvarande data kommer att gå förlorade. Är det okej?"
            yes = "ja"
            no = "nej"
        }else if location_sstr.contains("da")
        {
            message = "Aktuelle data vil gå tabt. Er det i orden?"
            yes = "ja"
            no = "nej"
        }else if location_sstr.contains("ar")
        {
            message = "ستفقد البيانات الحالية. هل هذا جيد؟"
            yes = "نعم"
            no = "لا"
            
        }else if location_sstr.contains("es")
        {
            message = "Los datos actuales se perderán. ¿Eso esta bien?"
            yes = "si"
            no = "no"
        }else{
            
        }
        
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: yes, style: .default, handler: { action in
            //reset all
            self.location_s.removeAll()
            self.content_s.removeAll()
          
            self.bgcolor_s.removeAll()
            self.cursor = String()
            self.tcolor_s.removeAll()
            self.textsize_s.removeAll()
            
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.JSON.removeAll()
            appd.currentDir.removeAll()
            appd.mergedCellListJSON.removeAll()
            appd.nousecells.removeAll()
            
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "iCloud" )//Landscape
            self.present( targetViewController, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
        
        self.present(alert, animated: true)
     
        self.customview3.removeFromSuperview()
        
    }
    
    
    
    override func viewDidLoad() {
        
        menuButton.layer.borderWidth = 1.0
        pageButton.layer.cornerRadius = 8.0
        
        myCollectionView.layer.borderWidth = 1.0
        myCollectionView.layer.borderColor = UIColor.gray.cgColor
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let location_sstr = Locale.current.languageCode!
        
        if location_sstr == "ja"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "ページ", for: .normal)
        }else if location_sstr == "fr"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "pages", for: .normal)
        }else if location_sstr == "zh"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "页数", for: .normal)
        }else if location_sstr == "de"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "Seiten", for: .normal)
        }else if location_sstr == "it"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "pagine", for: .normal)
        }else if location_sstr == "da"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "sider", for: .normal)
        }else if location_sstr == "ru"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "страницы", for: .normal)
        }else if location_sstr == "es"{
            pageButton.setTitle(String(appd.index+1) + "/" + String(appd.JSON.count) + " " + "paginas", for: .normal)
        }else if location_sstr == "sv"{
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
        //noInternet_search()


        if appd.JSON.count > 0{
            let index = appd.index
            COLUMNSIZE_s = appd.JSON[index]["cSize"] as! Int
            ROWSIZE_s = appd.JSON[index]["rSize"] as! Int
            location_s = appd.JSON[index]["location_s"] as! [String]
            content_s = appd.JSON[index]["content_ss"] as! [String]
        }

        otherclass.storeValues(rl:location_s,rc:content_s,rsize:ROWSIZE_s,csize:COLUMNSIZE_s)





        //https://stackoverflow.com/questions/31774006/how-to-get-height-of-keyboard
       

        bannerview.isHidden = true
        bannerview.delegate = self
        bannerview.adUnitID = "ca-app-pub-5284441033171047/6150797968"
        //        bannerview.adUnitID = "ca-app-pub-3940256099942544/2934735716" test
        bannerview.rootViewController = self
        bannerview.load(GADRequest())
    
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
        
        COLUMNSIZE_s = 27
        ROWSIZE_s = 50
        
        
        let appheight = UserDefaults.standard
        appheight.set(COLUMNSIZE_s, forKey: "NEWCsize")
        appheight.synchronize()
        
        let appheight2 = UserDefaults.standard
        appheight2.set(ROWSIZE_s, forKey: "NEWRsize")
        appheight2.synchronize()
        
    }
    
    
    
    @objc func restore()
    {
        //It's now restoreing.
        
        (content_s,location_s,COLUMNSIZE_s,ROWSIZE_s) = otherclass.outValues()
        
        
        
        
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
        
        if customview3 != nil{
            
            customview3.removeFromSuperview()
        }
        
        switch tag_int {
        case 0:
            customview3 = Customview3(frame: CGRect(x:5,y:50, width: 250,height: 210))
            break
        case 1:
            customview3 = Customview3(frame: CGRect(x:5,y:50, width: 250,height: 210))
            break
        case 2:
            customview3 = Customview3(frame: CGRect(x:5,y:50, width: 250,height: 210))
            break
        case 3:
            customview3 = Customview3(frame: CGRect(x:5,y:10, width: 250,height: 210))
            break
        case 4:
            customview3 = Customview3(frame: CGRect(x:5,y:200, width: 250,height: 210))
            break
        case 5:
            customview3 = Customview3(frame: CGRect(x:5,y:190, width: 250,height: 210))
            break
            
            
            
            
            
        default:
            customview3 = Customview3(frame: CGRect(x:5,y:150, width: 235,height: 130))
            break
            
        }
        
        
        
        
        customview3.layer.borderWidth = 1
        
        customview3.layer.cornerRadius = 8;
        
        
        customview3.layer.borderColor = UIColor.black.cgColor
        
        customview3.closebutton.addTarget(self, action: #selector(close), for: UIControlEvents.touchUpInside)
        
        
        customview3.backbutton.addTarget(self, action: #selector(back2(_:)), for: UIControlEvents.touchUpInside)
        
        customview3.mcselector.addTarget(self, action: #selector(sliderValueChanged), for: UIControlEvents.valueChanged)
        
        customview3.save.addTarget(self, action: #selector(saveuserD_search), for: UIControlEvents.touchUpInside)
        
        customview3.searchkbutton.addTarget(self, action: #selector(search), for: UIControlEvents.touchUpInside)
        
        customview3.replaceokbutton.addTarget(self, action: #selector(replace), for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(customview3)
    }
    
    
    
    func numberviewopen() {
        
        if numberview != nil {
            numberview.removeFromSuperview()
        }
        
        
        //if UIDevice.current.orientation.isLandscape{
        var width = "width"
        var height = "height"
        let location_sstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if location_sstr.contains( "ja")
        {
            width = "横幅"
            height = "縦幅"
        }else if location_sstr.contains( "fr")
        {
            width = "largeur"
            height = "la taille"
        }else if location_sstr.contains( "zh"){
            width = "宽度"
            height = "高度"
        }else if location_sstr.contains( "de")
        {
            width = "Breite"
            height = "Höhe"
        }else if location_sstr.contains( "it")
        {
            
            width = "altezza"
            height = "larghezza"
        }else if location_sstr.contains( "ru")
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
    
    
    
    //**********************BUTTONS*************************************************//
    
    @objc func backactionnum(_ sender:UIButton)
    {
        let indexItem = Int(currentindex.item)
        let indexSection = Int(currentindex.section)
        let value = numberview.inputfield.text!
        
        
        if Double(value) != nil{
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            
            if numberview.width_height_selector.selectedSegmentIndex == 0{
                
                appd.customSizedWidth[indexItem] = Double(value)!
                
                if appd.customSizedWidth[indexItem] < 20{
                    appd.customSizedWidth[indexItem] = 20
                }
                
            }else{
                
                appd.customSizedHeight[indexSection] = Double(value)!
                
                if appd.customSizedHeight[indexItem] < 20{
                    appd.customSizedHeight[indexItem] = 20
                }
                
            }
            
        }
        
        
        numberview.removeFromSuperview()
        
        saveuserD_search()
        
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
            
            (location_s,content_s) = otherclass.horribleMethod4Col(tempArray: location_s,tempArrayContent: content_s, colInt: indexItem)
            
            
            plus = COLUMNSIZE_s+1
            
            horrible.set(plus, forKey: "NEWCsize")
            horrible.synchronize()
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.tag_int == 3{
                appd.customSizedWidth.insert(75.0, at: indexItem)
            }else{
                appd.customSizedWidth.insert(100.0, at: indexItem)
            }
            
            
        }else if indexItem == 0{
            
            (location_s,content_s) = otherclass.horribleMethod4Row(tempArray: location_s,tempArrayContent: content_s, rowInt: indexSection)
            
            
            plus = ROWSIZE_s+1
            
            
            horrible.set(plus, forKey: "NEWRsize")
            horrible.synchronize()
            
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.tag_int == 3{
                appd.customSizedHeight.insert(30.0, at: indexSection)
            }else{
                appd.customSizedHeight.insert(40.0, at: indexSection)
            }
            
        }
        
        
        
        
        
        horrible.set(location_s, forKey: "NEWTMLOCATION")
        horrible.synchronize()
        
        
        horrible.set(content_s, forKey: "NEWTMCONTENT")
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
            
            (location_s,content_s) = otherclass.horribleMethod4ColMinus(tempArray: location_s,tempArrayContent:content_s , colInt: indexItem)
            
            
            minus = COLUMNSIZE_s-1
            horrible.set(minus, forKey: "NEWCsize")
            horrible.synchronize()
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.customSizedWidth.remove(at: indexItem)
            
        }else if indexItem == 0{
            
            (location_s,content_s) = otherclass.horribleMethod4RowMinus(tempArray: location_s,tempArrayContent: content_s, rowInt: indexSection)
            
            
            minus = ROWSIZE_s-1
            
            horrible.set(minus, forKey: "NEWRsize")
            horrible.synchronize()
            
            
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.customSizedHeight.remove(at: indexSection)
            
        }
        
        
        
        horrible.set(location_s, forKey: "NEWTMLOCATION")
        horrible.synchronize()
        
        
        horrible.set(content_s, forKey: "NEWTMCONTENT")
        horrible.synchronize()
        
        let next = storyboard!.instantiateViewController(withIdentifier: "SettingsViewController")
        self.present(next,animated: true, completion: nil)
    }
    
  
    
    @objc func copyText(){
        
      
    }
    
    @objc func search(){
        search_text = customview3.searchfield.text!
        myCollectionView.reloadData()
    }
    
    @objc func replace(){
        search_text = customview3.searchfield.text!
        if customview3.mcselector.selectedSegmentIndex == 0 {
            for i in 0..<content_s.count {
                if content_s[i] == search_text{
                    content_s[i] = customview3.replacefield.text!
                }
            }
        }else {
            for i in 0..<content_s.count {
                if content_s[i].contains(search_text){
                    content_s[i] = content_s[i].replacingOccurrences(of: search_text, with: customview3.replacefield.text!)
                }
            }
        }
 
        myCollectionView.reloadData()
    }
    
    @objc func sliderValueChanged(_ sender:Any){
//        if csview == false{
//            csview = true
//        }else if csview == true{
//            csview = false
//        }
        csview = !csview
    }
    
    @objc func terminate(){
        
        saveuserF()
        saveuserD_search()
       
    }
    
    @objc func input(){ }
    
    @objc func saveuserD_search() {
        
        let location_s1 = UserDefaults.standard
        location_s1.set(location_s, forKey: "NEWTMLOCATION")
        location_s1.synchronize()
        
        let content_s1 = UserDefaults.standard
        content_s1.set(content_s, forKey: "NEWTMCONTENT")
        content_s1.synchronize()
        
        let appheight = UserDefaults.standard
        appheight.set(COLUMNSIZE_s, forKey: "NEWCsize")
        appheight.synchronize()
        
        let appheight2 = UserDefaults.standard
        appheight2.set(ROWSIZE_s, forKey: "NEWRsize")
        appheight2.synchronize()
        
    }
    
    func saveuserF(){
        
//        let location_s2 = UserDefaults.standard
//        location_s2.set(bglocation_s, forKey: "NEWTMBGLOCATION")
//        location_s2.synchronize()
        
        let content_s2 = UserDefaults.standard
        content_s2.set(bgcolor_s, forKey: "NEWTMBGCOLOR")
        content_s2.synchronize()
        
//        let location_s3 = UserDefaults.standard
//        location_s3.set(tlocation_s, forKey: "NEWTMTLOCATION")
//        location_s3.synchronize()
        
        let content_s3 = UserDefaults.standard
        content_s3.set(tcolor_s, forKey: "NEWTMTCOLOR")
        content_s3.synchronize()
        
        let content_s4 = UserDefaults.standard
        content_s4.set(textsize_s, forKey: "NEWTMTEXTSIZE")
        content_s4.synchronize()
    
    }
    
    
    
    
    @objc func calculatormode(){
       
        let previousstr = currentindexstr
        
        
        calculatormode_update()
        
        
        
        currentindexstr = previousstr
        myCollectionView.collectionViewLayout.invalidateLayout()
        DispatchQueue.main.async() {
            self.myCollectionView.reloadData() }
        
        
    }
    
    
    @objc func calculatormode_update(){
        
      
      
    }
    
    
    
    func fonteditmode(){
        
        //let IP = IndexPath(row: currentindex.section, section: currentindex.section)
        let IP :String = currentindexstr
        
        if (location_s.firstIndex(of: IP) != nil) {
            
        }else{
            content_s.append(" ")
            location_s.append(IP)
            bgcolor_s.append("white")
            tcolor_s.append("black")
            textsize_s.append("10")
        }
        
        let idx = location_s.firstIndex(of: IP)
        
        if FONTEDIT.hasPrefix("bg="){
            
            let value = FONTEDIT.replacingOccurrences(of: "bg=", with: "").replacingOccurrences(of: " ", with: "")
            bgcolor_s[idx!] = value
            
        }else if FONTEDIT.hasPrefix("color="){
            
            let value2 = FONTEDIT.replacingOccurrences(of: "color=", with: "").replacingOccurrences(of: " ", with: "")
            tcolor_s[idx!] = value2
            
        }
        
        
        
    
        
        myCollectionView.reloadData()
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
        
    
        return Textinput
        
        
    }
    
    //
    func mathInterpret2(Textinput:String) -> String{
        
       
        
        return Textinput
        
        
    }
    
    
    
    func mathInterpret_update1_1(Textinput:String) -> String{
      
        
        return Textinput
        
        
    }
    
    func mathInterpret_update1_2(Textinput:String) -> String{
        
      
        
        return Textinput
        
        
    }
    
    //
    func mathInterpret2_update1_1(Textinput:String) -> String{
        
      
        return Textinput
        
        
    }
    
    func mathInterpret2_update1_2(Textinput:String) -> String{
        
    
        
        return Textinput
        
        
    }
    
    
    func cleanArray(InputArray:[String]) -> [String]{
        
  
        
        return InputArray
    }
    
    func cleanArray2(InputArray:[String]) -> [String]{
    
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
            
            let location_sstr = Locale.current.languageCode!
            
            if location_sstr == "ja"{
                pastemode_state.setTitle("入力", for: .normal)
            }else if location_sstr == "fr"{
                pastemode_state.setTitle("Entrée", for: .normal)
            }else if location_sstr == "zh"{
                pastemode_state.setTitle("输入", for: .normal)
            }else if location_sstr == "de"{
                pastemode_state.setTitle("Eingang", for: .normal)
            }else if location_sstr == "it"{
                pastemode_state.setTitle("Ingresso", for: .normal)
            }else if location_sstr == "da"{
                pastemode_state.setTitle("Indtast data", for: .normal)
            }else if location_sstr == "ru"{
                pastemode_state.setTitle("введите", for: .normal)
            }else if location_sstr == "es"{
                pastemode_state.setTitle("Entrada", for: .normal)
            }else if location_sstr == "sv"{
                pastemode_state.setTitle("Ange data", for: .normal)
            }else{
                pastemode_state.setTitle("Enter", for: .normal)
            }
            
            
            
            break
        case true:
            let location_sstr = Locale.current.languageCode!
            
            if location_sstr == "ja"{
                pastemode_state.setTitle("貼り付け", for: .normal)
            }else if location_sstr == "fr"{
                pastemode_state.setTitle("Coller", for: .normal)
            }else if location_sstr == "zh"{
                pastemode_state.setTitle("粘贴", for: .normal)
            }else if location_sstr == "de"{
                pastemode_state.setTitle("Einfügen", for: .normal)
            }else if location_sstr == "it"{
                pastemode_state.setTitle("Incolla", for: .normal)
            }else if location_sstr == "da"{
                pastemode_state.setTitle("indsætte", for: .normal)
            }else if location_sstr == "ru"{
                pastemode_state.setTitle("вставить", for: .normal)
            }else if location_sstr == "es"{
                pastemode_state.setTitle("Pegar", for: .normal)
            }else if location_sstr == "sv"{
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
        
        
        if Double(tempStr) != nil{
            
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
        
        //Font location_s
        tcolor_s.removeAll()
        tlocation_s.removeAll()
        textsize_s.removeAll()
        sizelocation_s.removeAll()
        bgcolor_s.removeAll()
        bglocation_s.removeAll()
        
        
        
        
        
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
    
    func noInternet_search(){
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            
            COLUMNSIZE_s = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
            
            if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
                
                ROWSIZE_s = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
                
            }else{
                ROWSIZE_s = 20
            }
        }
        else
        {
            initString()
            
        }
        
        
        //
        if (UserDefaults.standard.object(forKey: "NEWTMLOCATION") != nil) {
            
            location_s = UserDefaults.standard.object(forKey: "NEWTMLOCATION") as! Array
          
            
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMCONTENT") != nil) {
            
            content_s = UserDefaults.standard.object(forKey: "NEWTMCONTENT") as! Array
           
            
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMBGLOCATION") != nil) {
            
            bglocation_s = UserDefaults.standard.object(forKey: "NEWTMBGLOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMBGCOLOR") != nil) {
            
            bgcolor_s = UserDefaults.standard.object(forKey: "NEWTMBGCOLOR") as! Array
        }
        
        
        if (UserDefaults.standard.object(forKey: "NEWTMTLOCATION") != nil) {
            
            tlocation_s = UserDefaults.standard.object(forKey: "NEWTMTLOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMTCOLOR") != nil) {
            
            tcolor_s = UserDefaults.standard.object(forKey: "NEWTMTCOLOR") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMTEXTSIZE") != nil) {
            
            textsize_s = UserDefaults.standard.object(forKey: "NEWTMTEXTSIZE") as! Array
        }
        
        if location_s.count != content_s.count {
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            location_s.removeAll()
            content_s.removeAll()
           
            bglocation_s.removeAll()
            bgcolor_s.removeAll()
            
            
            tlocation_s.removeAll()
            sizelocation_s.removeAll()
            cursor = String()
            tcolor_s.removeAll()
            textsize_s.removeAll()
            
            initString()
        }
        
        if location_s.count != bgcolor_s.count || location_s.count != tcolor_s.count || location_s.count != textsize_s.count{
            bgcolor_s.removeAll()
            textsize_s.removeAll()
            tcolor_s.removeAll()
            
            for _ in 0..<location_s.count{
                bgcolor_s.append("white")
                textsize_s.append("10")
                tcolor_s.append("black")
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
    
  
    //
    @objc func saveJSONAction_search(){
        
        var message = "Do you save this file?"
        var yes = "OK"
        var no = "No"
        let location_sstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if location_sstr.contains( "ja")
        {
            message = "このファイルを保存しますか？"
            yes = "はい"
            no = "いいえ"
        }else if location_sstr.contains( "fr")
        {
            message = "Enregistrez-vous ce fichier?"
            yes = "oui"
            no = "non"
        }else if location_sstr.contains( "zh"){
            
            message = "您保存此文件吗？"
            yes = "是"
            no = "否"
        }else if location_sstr.contains( "de")
        {
            
            message = "Speichern Sie diese Datei?"
            yes = "ja"
            no = "nein"
        }else if location_sstr.contains( "it")
        {
            
            message = "Salvi questo file?"
            yes = "si"
            no = "no"
        }else if location_sstr.contains( "ru")
        {
            
            message = "Вы сохраняете этот файл?"
            yes = "да"
            no = "нет"
        }else if location_sstr.contains("sv")
        {
            message = "Sparar du den här filen?"
            yes = "ja"
            no = "nej"
        }else if location_sstr.contains("da")
        {
            message = "Gemmer du denne fil?"
            yes = "ja"
            no = "nej"
        }else if location_sstr.contains("ar")
        {
            message = "هل تحفظ هذا الملف؟"
            yes = "نعم"
            no = "لا"
            
        }else if location_sstr.contains("es")
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
            
            if name!.count > 0 {
                self.saveAsLocalJson_search(filename:name!)
              
            }
            
            appd.viewconSelectedName = "Initial"
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" )
            self.present( targetViewController, animated: true, completion: nil)
        })
        
        let nilAction = UIAlertAction(title: no, style: .default, handler: {action in
            
    
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" )
            self.present( targetViewController, animated: true, completion: nil)
        })
        alert.addAction(confirmAction)
        alert.addAction(nilAction)
        
        self.present(alert, animated: true)
        
        resetAll()
        appd.viewconSelectedName = "Initial"
        
        
       
        
        self.customview3.removeFromSuperview()
        
        
        
    }

    @objc func saveAsLocalJson_search(filename:String) {
        
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let today: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        let date = dateFormatter.string(from: today)
        
        
        let dict : [String:Any] = ["filename": filename,
                                   "date": date,
                                   "content_s": content_s,
                                   "location_s": location_s,
                                   "fontsize": textsize_s,
                                   "fontcolor_s": tcolor_s,
                                   "bgcolor_s": bgcolor_s,
                                   "rowsize": ROWSIZE_s,
                                   "columnsize": COLUMNSIZE_s,
                                   "customcellWidth":appDelegate.customSizedWidth,
                                   "customcellHeight": appDelegate.customSizedHeight,
                                   "ccwLocation": appDelegate.cswLocation,
                                   "cchLocation": appDelegate.cshLocation]
        
        print(dict, "search_dict")
        
        let test = ReadWriteJSON()
        test.saveJsonFile(source: dict, title: filename)
        
        
        
    }
    
    @objc func resetAll (){
    //reset all
    location_s.removeAll()
    content_s.removeAll()
    bgcolor_s.removeAll()
    cursor = String()
    tcolor_s.removeAll()
    textsize_s.removeAll()
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
    
    saveuserD_search()
    saveuserF()
    
    }
    
    
}


