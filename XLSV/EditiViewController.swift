//
//  EditiViewController.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2017/02/10.
//  Copyright © 2017年 Credera. All rights reserved.
//
//http://stackoverflow.com/questions/24701911/how-to-receive-touches-on-a-uicollectionview-in-the-blank-space-around-all-cells nice tips

import UIKit
import MessageUI
import QuartzCore


let reuseIdentifier2 = "customCell"

class EditViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate,UITextViewDelegate,MFMailComposeViewControllerDelegate,UICollectionViewDelegateFlowLayout{
    
    var tag_int :Int!
    
    var device_size : Int = 0
    
    var current_range : NSRange!
    
    var recover_int : Int!
    
    var selectedIndexPaths = NSMutableSet()
    
    //http://stackoverflow.com/questions/28360919/my-table-view-reuse-the-selected-cells-when-scroll-in-swift
    //var selectedIndexPaths = NSMutableSet()
    
    //http://stackoverflow.com/questions/31706404/ios-8-and-swift-call-a-function-in-another-class-from-view-controller
    //var global = ns()
    
    //var Fview = formatview()
    
    var customview3 :Customview3!
    
    var boolean = false//coulmnsize_check
    
    
    //StringFormat
    var fontsize = 12
    var fontcolor = 10
    var labelcolor = 5
    var fontbackground = 15
    var labelborderclear = 0
    var fontitalic = 0
    var fontbold = 0
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    
    
    @IBAction func scshot(_ sender: Any) {
        
        let contentOffset = myCollectionView.contentOffset
        
        UIGraphicsBeginImageContextWithOptions(myCollectionView.bounds.size, true, 1)
        
        let context = UIGraphicsGetCurrentContext()
        
        context!.translateBy(x: 0, y: -contentOffset.y)
        
        myCollectionView.layer.render(in: context!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)

        
        /*
        myCollectionView.frame = CGRectMake(myCollectionView.frame.origin.x, myCollectionView.frame.origin.y, myCollectionView.contentSize.width, myCollectionView.contentSize.height);
        
        UIGraphicsBeginImageContextWithOptions(myCollectionView.frame.size,false,0.0)
        
        
        let context = UIGraphicsGetCurrentContext()
        
        let previousFrame = myCollectionView.frame
        
        
        
        myCollectionView.layer.render(in: context!)
        
        myCollectionView.frame = previousFrame
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        
         */
        let dialogmessage = "SUCCESSFUL SCREENSHOTCAPTURING!\nPress Back to return. "
        let message = UserDefaults.standard
        message.set(dialogmessage, forKey: "TMDM")
        message.synchronize()
        
        //
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "Dview" )
        self.present( targetViewController, animated: true, completion: nil)
        
    }
 
    
    
    //forexport
    var data: Data? = nil
    
    
    
    
    
    
    
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        
        
        
        
        var rowsize = 260
        
        
        if (UserDefaults.standard.object(forKey: "TMRS") != nil) {
            
            rowsize = UserDefaults.standard.object(forKey: "TMRS") as! Int
        }else{
            
        }
        
        
        
        return rowsize
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        
        
        
        var columnsize = 27
        
        
        if (UserDefaults.standard.object(forKey: "TMCS") != nil) {
            
            
            columnsize = UserDefaults.standard.object(forKey: "TMCS") as! Int
        }else{
            
        }
        
        
        
        return columnsize
    }
    
    //Writing Values
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier2, for: indexPath) as! CustomCollectionViewCell
        
 
        
        
        cell.label.text = ""
        
        cell.label.lineBreakMode = .byWordWrapping // or NSLineBreakMode.ByWordWrapping
        cell.label.numberOfLines = 0
        
        
        cell.layer.borderColor = UIColor.gray.cgColor
        
        //
        configure(cell, forRowAtIndexPath: indexPath)
        
        if (UserDefaults.standard.object(forKey: "TMCELLWIDTH") != nil) {
            
            let CELL_WIDTH = UserDefaults.standard.object(forKey: "TMCELLWIDTH") as! Double
            
            let CELL_HEIGHT = UserDefaults.standard.object(forKey: "TMCELLHEIGHT") as! Double
            
            cell.label.frame = CGRectMake(0, 0, CGFloat(CELL_WIDTH), CGFloat(CELL_HEIGHT))
        }
        else
        {
            cell.label.frame = CGRectMake(0, 0, CGFloat(100), CGFloat(30))
        }
        
        
                //print(global.StringArray.count)
        
        //http://stackoverflow.com/questions/29381994/swift-check-string-for-nil-empty
        //http://qiita.com/satomyumi/items/b0d071cc906574086ac4
        
        
       
        
        //cell.label.font = UIFont.systemFont(ofSize: CGFloat(fontsize))
        
                
        
        switch indexPath.item {
        case 0:
            if cell.label.text?.characters.count != 0 {
                
            }
            else{
                cell.label.text = global.array0[indexPath.section]
                
            }
            
            break
        case 1:
            if cell.label.text?.characters.count != 0 {
                
            }
            else{
                cell.label.text = global.array1[indexPath.section]
                
            }
            break
        case 2:
            if cell.label.text?.characters.count != 0 {
                
            }
            else{
                cell.label.text = global.array2[indexPath.section]
                
            }
            
            break
        case 3:
            if cell.label.text?.characters.count != 0 {
                
            }
            else{
                cell.label.text = global.array3[indexPath.section]
            }
            
            break
        case 4:
            if global.array4[indexPath.section].isEmpty {
                
            }
            else{
                cell.label.text = global.array4[indexPath.section]
            }
            
            break
        case 5:
            
            if global.array5[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array5[indexPath.section]
            }
            
            break
        case 6:
            
            if global.array6[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array6[indexPath.section]
            }
            
            break
        case 7:
            
            if global.array7[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array7[indexPath.section]
            }
            
            break
        case 8:
            
            if global.array8[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array8[indexPath.section]
            }
            
            break
        case 9:
            
            if global.array9[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array9[indexPath.section]
            }
            
            break
        case 10:
            
            if global.array10[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array10[indexPath.section]
            }
            
            break
        case 11:
            
            if global.array11[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array11[indexPath.section]
            }
            
            break
        case 12:
            
            if global.array12[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array12[indexPath.section]
            }
            
            break
        case 13:
            
            if global.array13[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array13[indexPath.section]
            }
            
            break
        case 14:
            
            if global.array14[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array14[indexPath.section]
            }
            
            break
        case 15:
            
            if global.array15[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array15[indexPath.section]
            }
            
            break
        case 16:
            
            if global.array16[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array16[indexPath.section]
            }
            
            break
        case 17:
            
            if global.array17[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array17[indexPath.section]
            }
            
            break
        case 18:
            
            if global.array18[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array18[indexPath.section]
            }
            
            break
        case 19:
            
            if global.array19[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array19[indexPath.section]
            }
            
            break
        case 20:
            
            if global.array20[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array20[indexPath.section]
            }
            
            break
        case 21:
            
            if global.array21[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array21[indexPath.section]
            }
            
            break
        case 22:
            
            if global.array22[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array22[indexPath.section]
            }
            
            break
        case 23:
            
            if global.array23[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array23[indexPath.section]
            }
            
            break
        case 24:
            
            if global.array24[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array24[indexPath.section]
            }
            
            break
        case 25:
            
            if global.array25[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array25[indexPath.section]
            }
            
            break
        case 26:
            
            if global.array26[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array26[indexPath.section]
            }
            
            break
        case 27:
            
            if global.array27[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array27[indexPath.section]
            }
            
            break
        case 28:
            
            if global.array28[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array28[indexPath.section]
            }
            
            break
        case 29:
            
            if global.array29[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array29[indexPath.section]
            }
            
            break
        case 30:
            
            if global.array30[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array30[indexPath.section]
            }
            
            break
        case 31:
            
            if global.array31[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array31[indexPath.section]
            }
            
            break
        case 32:
            
            if global.array32[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array32[indexPath.section]
            }
            
            break
        case 33:
            
            if global.array33[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array33[indexPath.section]
            }
            
            break
        case 34:
            
            if global.array34[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array34[indexPath.section]
            }
            
            break
        case 35:
            
            if global.array35[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array35[indexPath.section]
            }
            
            break
        case 36:
            
            if global.array36[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array36[indexPath.section]
            }
            
            break
        case 37:
            
            if global.array37[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array37[indexPath.section]
            }
            
            break
        case 38:
            
            if global.array38[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array38[indexPath.section]
            }
            
            break
        case 39:
            
            if global.array39[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array39[indexPath.section]
            }
            
            break
        case 40:
            
            if global.array40[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array40[indexPath.section]
            }
            
            break
            
            
            
        default:
            break
        }
        
        
        
        return cell
    }
    
    
    
    //Hiding Keyboard
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    
    //Touching one of cells
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //print("Cell row \(indexPath.row) selected")
        //print("Cell section\(indexPath.section) selected")
        
                
        /*

        //
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CustomCollectionViewCell
        
        //cell.label.backgroundColor = UIColor.cyan
        //cell.label.textColor = UIColor.black
        //cell.label.layer.borderColor = UIColor.white.cgColor
        //cell.layer.borderColor = UIColor.clear.cgColor
        
        
        let fontsize = CGFloat(self.fontsize)
        
        
        
        
        //Italic
        if fontitalic == 0 {
            
            cell.label.font = UIFont.systemFont(ofSize: fontsize)
            
            
        }else{
            cell.label.font = UIFont.italicSystemFont(ofSize: fontsize)
            
        }
        
        //Bold
        if fontbold == 0 {
            
            
            
            
        }else{
            cell.label.font = UIFont.boldSystemFont(ofSize: fontsize)
            
        }
        
        
        
        //Text
        cell.label.textColor = colorlist(fontcolor)
        
        //Label
        cell.label.backgroundColor = colorlist(labelcolor)
        
        //BG
        
        
        cell.layer.borderColor = colorlist(fontbackground).cgColor
        
         */
 
        //Re Typing Text
        
        /*
        switch indexPath.item {
        case 0:
            if global.array0[indexPath.section].isEmpty {
                
            }
            else{
                cell.label.text = global.array0[indexPath.section]
                
            }
            
            break
        case 1:
            if global.array1[indexPath.section].isEmpty {
                
            }
            else{
                cell.label.text = global.array1[indexPath.section]
            }
            break
        case 2:
            if global.array2[indexPath.section].isEmpty {
                
            }
            else{
                cell.label.text = global.array2[indexPath.section]
            }
            
            break
        case 3:
            if global.array3[indexPath.section].isEmpty {
                
            }
            else{
                cell.label.text = global.array3[indexPath.section]
            }
            
            break
        case 4:
            if global.array4[indexPath.section].isEmpty {
                
            }
            else{
                cell.label.text = global.array4[indexPath.section]
            }
            
            break
        case 5:
            
            if global.array5[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array5[indexPath.section]
            }
            
            break
        case 6:
            
            if global.array6[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array6[indexPath.section]
            }
            
            break
        case 7:
            
            if global.array7[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array7[indexPath.section]
            }
            
            break
        case 8:
            
            if global.array8[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array8[indexPath.section]
            }
            
            break
        case 9:
            
            if global.array9[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array9[indexPath.section]
            }
            
            break
        case 10:
            
            if global.array10[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array10[indexPath.section]
            }
            
            break
        case 11:
            
            if global.array11[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array11[indexPath.section]
            }
            
            break
        case 12:
            
            if global.array12[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array12[indexPath.section]
            }
            
            break
        case 13:
            
            if global.array13[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array13[indexPath.section]
            }
            
            break
        case 14:
            
            if global.array14[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array14[indexPath.section]
            }
            
            break
        case 15:
            
            if global.array15[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array15[indexPath.section]
            }
            
            break
        case 16:
            
            if global.array16[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array16[indexPath.section]
            }
            
            break
        case 17:
            
            if global.array17[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array17[indexPath.section]
            }
            
            break
        case 18:
            
            if global.array18[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array18[indexPath.section]
            }
            
            break
        case 19:
            
            if global.array19[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array19[indexPath.section]
            }
            
            break
        case 20:
            
            if global.array20[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array20[indexPath.section]
            }
            
            break
        case 21:
            
            if global.array21[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array21[indexPath.section]
            }
            
            break
        case 22:
            
            if global.array22[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array22[indexPath.section]
            }
            
            break
        case 23:
            
            if global.array23[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array23[indexPath.section]
            }
            
            break
        case 24:
            
            if global.array24[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array24[indexPath.section]
            }
            
            break
        case 25:
            
            if global.array25[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array25[indexPath.section]
            }
            
            break
        case 26:
            
            if global.array26[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array26[indexPath.section]
            }
            
            break
        case 27:
            
            if global.array27[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array27[indexPath.section]
            }
            
            break
        case 28:
            
            if global.array28[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array28[indexPath.section]
            }
            
            break
        case 29:
            
            if global.array29[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array29[indexPath.section]
            }
            
            break
        case 30:
            
            if global.array30[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array30[indexPath.section]
            }
            
            break
        case 31:
            
            if global.array31[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array31[indexPath.section]
            }
            
            break
        case 32:
            
            if global.array32[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array32[indexPath.section]
            }
            
            break
        case 33:
            
            if global.array33[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array33[indexPath.section]
            }
            
            break
        case 34:
            
            if global.array34[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array34[indexPath.section]
            }
            
            break
        case 35:
            
            if global.array35[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array35[indexPath.section]
            }
            
            break
        case 36:
            
            if global.array36[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array36[indexPath.section]
            }
            
            break
        case 37:
            
            if global.array37[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array37[indexPath.section]
            }
            
            break
        case 38:
            
            if global.array38[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array38[indexPath.section]
            }
            
            break
        case 39:
            
            if global.array39[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array39[indexPath.section]
            }
            
            break
        case 40:
            
            if global.array40[indexPath.section].isEmpty {
            }            else{
                
                cell.label.text = global.array40[indexPath.section]
            }
            
            break
            
            
            
        default:
            break
        }
    
 
        //let delegate = UIApplication.shared.delegate as! AppDelegate
        
        
        */
        
        
        
        //myCollectionView.deselectAllItems()
        
    }
    
    
    
    //http://stackoverflow.com/questions/27674317/changing-cell-background-color-in-uicollectionview-in-swift
    /*
     func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath
     indexPath: IndexPath) {
     
     let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CustomCollectionViewCell
     
     cell.backgroundColor = UIColor.cyan
     }
     */
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        
        
        
        recover_int = 0
        
        
        //http://qiita.com/xa_un/items/814a5cd4472674640f58
        
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        tag_int = appDelegate.tag_int
        
        
        device_size  = tag_int
        
        //
        // viewにロングタップのジェスチャーを追加http://swift-studying.com/blog/swift/?p=541
        /*
         let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.allclear(_:)))
         longPressGesture.minimumPressDuration = 0.01
         
         self.clearbutton.addGestureRecognizer(longPressGesture)
         */
        
        //Loading global.StringArray
        
        if (UserDefaults.standard.object(forKey: "TMa0") != nil) {
            
            
            
            global.nsuserload()
            
            
        }
        else
        {
            
            
            
        }
        
      
        
        
    }
    
       
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let emailController = MFMailComposeViewController()
        emailController.mailComposeDelegate = self
        emailController.setSubject("CSV File")
        emailController.setMessageBody("", isHTML: false)
        
        
        // Attaching the .CSV file to the email.
        emailController.addAttachmentData(data!, mimeType: "text/csv", fileName: "Sample.csv")
        
        return emailController
        
        // Attaching the .CSV file to the email.
        //emailController.addAttachmentData(NSData(contentsOfFile: "YourFile")!, mimeType: "text/csv", fileName: "Sample.csv")
        
        
    }
    
    
    //http://stackoverflow.com/questions/35782218/swift-how-to-make-mfmailcomposeviewcontroller-disappear
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        //ROTATION
        
        
        
        // NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.orientationdidChange(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        
    }
    
    
    
    
    
    
    
    
    
    // https://sites.google.com/a/gclue.jp/swift-docs/ni-yinki100-ios/2-utility/010-duan-mono-xiangkiga-bianwattakotowo-jian-zhisuru
    
    //http://mslgt.hatenablog.com/entry/2014/09/21/140159
    
    
    
    
    
    //http://stackoverflow.com/questions/32851720/how-to-remove-special-characters-from-string-in-swift-2
    func removeSpecialCharsFromString(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("1234567890-.".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    func removeSpecialCharsFromStringOprators(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("MaximnSuAvg%^×÷".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    
    func renumbering() {
        //
        
        
        
        global.array0.insert(" ", at: 0)
        global.array1.insert("-", at: 0)
        global.array2.insert("-", at: 0)
        global.array3.insert("-", at: 0)
        global.array4.insert("-", at: 0)
        global.array5.insert("-", at: 0)
        global.array6.insert("-", at: 0)
        global.array7.insert("-", at: 0)
        global.array8.insert("-", at: 0)
        global.array9.insert("-", at: 0)
        global.array10.insert("-", at: 0)
        global.array11.insert("-", at: 0)
        global.array12.insert("-", at: 0)
        global.array13.insert("-", at: 0)
        global.array14.insert("-", at: 0)
        global.array15.insert("-", at: 0)
        global.array16.insert("-", at: 0)
        global.array17.insert("-", at: 0)
        global.array18.insert("-", at: 0)
        global.array19.insert("-", at: 0)
        global.array20.insert("-", at: 0)
        global.array21.insert("-", at: 0)
        global.array22.insert("-", at: 0)
        global.array23.insert("-", at: 0)
        global.array24.insert("-", at: 0)
        global.array25.insert("-", at: 0)
        global.array26.insert("-", at: 0)
        global.array27.insert("-", at: 0)
        global.array28.insert("-", at: 0)
        global.array29.insert("-", at: 0)
        global.array30.insert("-", at: 0)
        global.array31.insert("-", at: 0)
        global.array32.insert("-", at: 0)
        global.array33.insert("-", at: 0)
        global.array34.insert("-", at: 0)
        global.array35.insert("-", at: 0)
        global.array36.insert("-", at: 0)
        global.array37.insert("-", at: 0)
        global.array38.insert("-", at: 0)
        global.array39.insert("-", at: 0)
        global.array40.insert("-", at: 0)
        
        
        
        global.array1[0] = "A"
        global.array2[0] = "B"
        global.array3[0] = "C"
        global.array4[0] = "D"
        global.array5[0] = "E"
        global.array6[0] = "F"
        global.array7[0] = "G"
        global.array8[0] = "H"
        global.array9[0] = "I"
        global.array10[0] = "J"
        global.array11[0] = "K"
        global.array12[0] = "L"
        global.array13[0] = "M"
        global.array14[0] = "N"
        global.array15[0] = "O"
        global.array16[0] = "P"
        global.array17[0] = "Q"
        global.array18[0] = "R"
        global.array19[0] = "S"
        global.array20[0] = "T"
        global.array21[0] = "U"
        global.array22[0] = "V"
        global.array23[0] = "W"
        global.array24[0] = "X"
        global.array25[0] = "Y"
        global.array26[0] = "Z"
        global.array27[0] = "AA"
        global.array28[0] = "AB"
        global.array29[0] = "AC"
        global.array30[0] = "AD"
        global.array31[0] = "AE"
        global.array32[0] = "AF"
        global.array33[0] = "AG"
        global.array34[0] = "AH"
        global.array35[0] = "AI"
        global.array36[0] = "AJ"
        global.array37[0] = "AK"
        global.array38[0] = "AL"
        global.array39[0] = "AM"
        global.array40[0] = "AN"
        
        for i in 1..<global.array0.count {
            global.array0[i] = (String(i))
        }
        
        
        let rowsize = UserDefaults.standard
        rowsize.set(global.array0.count, forKey: "TMRS")
        rowsize.synchronize()
        
    }
    
    func renumberingforshiftop() {
        
        //
        
        global.array0.removeAll()
        
        global.array0.append(" ")
        
        for i in 1..<global.array1.count {
            
            global.array0.append(String(i))
            
        }
        
        
        
        global.array1[0] = "A"
        
        global.array2[0] = "B"
        
        global.array3[0] = "C"
        
        global.array4[0] = "D"
        
        global.array5[0] = "E"
        
        global.array6[0] = "F"
        
        global.array7[0] = "G"
        
        global.array8[0] = "H"
        
        global.array9[0] = "I"
        
        global.array10[0] = "J"
        
        global.array11[0] = "K"
        
        global.array12[0] = "L"
        
        global.array13[0] = "M"
        
        global.array14[0] = "N"
        
        global.array15[0] = "O"
        
        global.array16[0] = "P"
        
        global.array17[0] = "Q"
        
        global.array18[0] = "R"
        
        global.array19[0] = "S"
        
        global.array20[0] = "T"
        
        global.array21[0] = "U"
        
        global.array22[0] = "V"
        
        global.array23[0] = "W"
        
        global.array24[0] = "X"
        
        global.array25[0] = "Y"
        
        global.array26[0] = "Z"
        
        global.array27[0] = "AA"
        
        global.array28[0] = "AB"
        
        global.array29[0] = "AC"
        
        global.array30[0] = "AD"
        
        global.array31[0] = "AE"
        
        global.array32[0] = "AF"
        
        global.array33[0] = "AG"
        
        global.array34[0] = "AH"
        
        global.array35[0] = "AI"
        
        global.array36[0] = "AJ"
        
        global.array37[0] = "AK"
        
        global.array38[0] = "AL"
        
        global.array39[0] = "AM"
        
        global.array40[0] = "AN"
        
        
        
    }
    
    func screenShotMethod(_ sender:UIButton) {
        /*
         //Create the UIImage
         UIGraphicsBeginImageContextWithOptions(myCollectionView.frame.size,false,0.0)
         myCollectionView.layer.render(in: UIGraphicsGetCurrentContext()!)
         let image = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         
         
         
         
         //Save it to the camera roll
         UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
         */
        //selectedIndexPaths.removeAllObjects()
        //myCollectionView.reloadData()
        
        /*
         myCollectionView.frame = CGRectMake(myCollectionView.frame.origin.x, myCollectionView.frame.origin.y, myCollectionView.contentSize.width, myCollectionView.contentSize.height);
         
         UIGraphicsBeginImageContextWithOptions(myCollectionView.frame.size,false,0.0)
         
         
         let context = UIGraphicsGetCurrentContext()
         
         let previousFrame = myCollectionView.frame
         
         
         
         myCollectionView.layer.render(in: context!)
         
         myCollectionView.frame = previousFrame
         
         let image = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext();
         
         
         
         let imageView=UIImageView(frame: CGRect(x: 10, y: 100, width: 150, height: 100))
         
         imageView.image = image
         
         self.view.addSubview(imageView)
         */
        
        
        myCollectionView.reloadData()
    }
    
    //
    
    /*
    func backaction(_ sender:UIButton){
        
        Fview.removeFromSuperview()
        
    }
    
    func screen(_ sender: UISwitch){
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if Fview.screenshotswitch.isOn  {
            
            
            appDelegate.labelborderclear = 1
            
            
        }
        else
        {
            
            appDelegate.labelborderclear = 0
        }
        
        //2017.2.2
        myCollectionView.reloadData()
        
        
    }
    
    func c1(_ sender:UIButton){
        
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            print("font")
            fontcolor = 1
            break
        case 1:
            print("label")
            labelcolor = 1
            break
        case 2:
            fontbackground = 1
            break
        default:
            break
        }
        
        print("c1")
    }
    
    func c2(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 2
            break
        case 1:
            labelcolor = 2
            break
        case 2:
            fontbackground = 2
            break
        default:
            break
        }
        
        print("c2")
        
    }
    
    func c3(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 3
            break
        case 1:
            labelcolor = 3
            break
        case 2:
            fontbackground = 3
            break
        default:
            break
        }
        
        print("c3")
        
    }
    
    func c4(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 4
            break
        case 1:
            labelcolor = 4
            break
        case 2:
            fontbackground = 4
            break
        default:
            break
        }
        
        print("c4")
        
    }
    
    func c5(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 5
            break
        case 1:
            labelcolor = 5
            break
        case 2:
            fontbackground = 5
            break
        default:
            break
        }
        print("c5")
    }
    
    func c6(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 6
            break
        case 1:
            labelcolor = 6
            break
        case 2:
            fontbackground = 6
            break
        default:
            break
        }
        print("c6")
    }
    
    func c7(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 7
            break
        case 1:
            labelcolor = 7
            break
        case 2:
            fontbackground = 7
            break
        default:
            break
        }
        print("c7")
    }
    
    func c8(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 8
            break
        case 1:
            labelcolor = 8
            break
        case 2:
            fontbackground = 8
            break
        default:
            break
        }
        
    }
    
    func c9(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 9
            break
        case 1:
            labelcolor = 9
            break
        case 2:
            fontbackground = 9
            break
        default:
            break
        }
        
    }
    
    func c10(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 10
            break
        case 1:
            labelcolor = 10
            break
        case 2:
            fontbackground = 10
            break
        default:
            break
        }
        
        
    }
    
    func c11(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 11
            break
        case 1:
            labelcolor = 11
            break
        case 2:
            fontbackground = 11
            break
        default:
            break
        }
        
    }
    
    func c12(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 12
            break
        case 1:
            labelcolor = 12
            break
        case 2:
            fontbackground = 12
            break
        default:
            break
        }
        
        
    }
    
    func c13(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 13
            break
        case 1:
            labelcolor = 13
            break
        case 2:
            fontbackground = 13
            break
        default:
            break
        }
        
    }
    
    func c14(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 14
            break
        case 1:
            labelcolor = 14
            break
        case 2:
            fontbackground = 14
            break
        default:
            break
        }
        
        
    }
    
    func c15(_ sender:UIButton){
        
        
        switch Fview.fontSeg.selectedSegmentIndex{
        case 0:
            fontcolor = 15
            break
        case 1:
            labelcolor = 15
            break
        case 2:
            fontbackground = 15
            break
        default:
            break
        }
        
        
        
    }
    
    func Italic(_ sender:UISwitch){
        
        
        
        
        if Fview.italicbool.isOn {
            fontitalic = 1
        }
        else{
            fontitalic = 0
        }
        
        print(fontitalic)
        
        
        
    }
    
    func Bold(_ sender:UISwitch){
        
        
        
        
        if Fview.boldbool.isOn {
            fontbold = 1
        }
        else{
            fontbold = 0
        }
        
        print(fontbold)
        
        
    }
    
    
    func slider(_ sender:UISlider){
        
        
        
        
        switch (floor(sender.value)) {
        case 10:
            Fview.sizelabel.text = "10"
            fontsize = 10
            
            break
            
            
        case 11:
            Fview.sizelabel.text = "11"
            fontsize = 11
            
            break
            
            
        case 12:
            Fview.sizelabel.text = "12"
            fontsize = 12
            
            break
            
        case 13:
            Fview.sizelabel.text = "13"
            fontsize = 13
            break
            
        case 14:
            Fview.sizelabel.text = "14"
            fontsize = 14
            break
            
        case 15:
            Fview.sizelabel.text = "15"
            fontsize = 15
            break
            
        case 16:
            Fview.sizelabel.text = "16"
            fontsize = 16
            break
        case 17:
            Fview.sizelabel.text = "17"
            fontsize = 17
            
            break
            
        case 18:
            Fview.sizelabel.text = "18"
            fontsize = 18
            break
            
        case 19:
            Fview.sizelabel.text = "19"
            fontsize = 19
            break
            
        case 20:
            Fview.sizelabel.text = "20"
            fontsize = 20
            break
            
        case 21:
            Fview.sizelabel.text = "21"
            fontsize = 21
            break
        case 22:
            Fview.sizelabel.text = "22"
            fontsize = 22
            break
            
            
        default:
            break
        }
        
    }
    
    
    //http://www.codingexplorer.com/create-uicolor-swift/
    func colorlist(_ number : Int) -> UIColor {
        
        
        var thecolor = UIColor.white
        
        switch number {
        case 1:
            thecolor = UIColor(red: 255/255, green: 237/255, blue: 252/255, alpha: 0.9)
            break
        case 2:
            thecolor = UIColor(red: 185/255, green: 255/255, blue: 255/255, alpha: 0.9)
            break
            
        case 3:
            thecolor = UIColor(red: 208/255, green: 255/255, blue: 172/255, alpha: 0.9)
            break
            
        case 4:
            thecolor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
            break
            
        case 5:
            thecolor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
            break
        case 6:
            thecolor = UIColor(red: 0/255, green: 0/255, blue: 255/255, alpha: 1.0)
            break
            
        case 7:
            thecolor = UIColor(red: 255/255, green: 111/255, blue: 207/255, alpha: 1.0)
            break
            
        case 8:
            thecolor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1.0)
            break
            
        case 9:
            thecolor = UIColor(red: 255/255, green: 127/255, blue: 0/255, alpha: 1.0)
            break
            
        case 10:
            thecolor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
            break
        case 11:
            thecolor = UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1.0)
            break
            
        case 12:
            thecolor = UIColor(red: 0/255, green: 128/255, blue: 64/255, alpha: 1.0)
            break
            
        case 13:
            thecolor = UIColor(red: 128/255, green: 0/255, blue: 255/255, alpha: 1.0)
            break
            
        case 14:
            thecolor = UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 1.0)
            break
            
        case 15:
            //thecolor = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0)
            thecolor = UIColor.lightGray
            break
            
            
            
        default:
            break
        }
        
        
        return thecolor
        
    }
     */
    
    //http://code-examples-ja.hateblo.jp/entry/2016/09/21/Swift3
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /*
    @IBAction func formataction(_ sender: AnyObject) {
        
        
        if Fview != nil{
            
            Fview.removeFromSuperview()
        }
        
        switch device_size {
        case 0:
            Fview = formatview(frame: CGRect(x:250,y:10, width: 300,height: 310))
            break
        case 1:
            Fview = formatview(frame: CGRect(x:150,y:10, width: 300,height: 310))
            break
        case 2:
            Fview = formatview(frame: CGRect(x:250,y:10, width: 300,height: 310))
            break
        case 3:
            Fview = formatview(frame: CGRect(x:250,y:10, width: 300,height: 310))
            break
        case 4:
            Fview = formatview(frame: CGRect(x:650,y:300, width: 300,height: 310))
            break
        case 5:
            Fview = formatview(frame: CGRect(x:1000,y:300, width: 300,height: 310))
            break
            
            
        default:
            Fview = formatview(frame: CGRect(x:250,y:10, width: 300,height: 310))
            break
            
        }
        
        
        
        Fview .layer.borderWidth = 1
        
        Fview .layer.cornerRadius = 8;
        
        Fview .layer.borderColor = UIColor.black.cgColor
        
        Fview .color5.layer.borderWidth = 1
        
        Fview .color5.layer.borderColor = UIColor.black.cgColor
        
        Fview.backaction.addTarget(self, action: #selector(EditViewController.backaction(_:)), for: UIControlEvents.touchUpInside)
        
        Fview.color1.addTarget(self, action: #selector(EditViewController.c1(_:)), for: UIControlEvents.touchUpInside)
        Fview.color2.addTarget(self, action: #selector(EditViewController.c2(_:)), for: UIControlEvents.touchUpInside)
        Fview.color3.addTarget(self, action: #selector(EditViewController.c3(_:)), for: UIControlEvents.touchUpInside)
        Fview.color4.addTarget(self, action: #selector(EditViewController.c4(_:)), for: UIControlEvents.touchUpInside)
        Fview.color5.addTarget(self, action: #selector(EditViewController.c5(_:)), for: UIControlEvents.touchUpInside)
        Fview.color6.addTarget(self, action: #selector(EditViewController.c6(_:)), for: UIControlEvents.touchUpInside)
        Fview.color7.addTarget(self, action: #selector(EditViewController.c7(_:)), for: UIControlEvents.touchUpInside)
        Fview.color8.addTarget(self, action: #selector(EditViewController.c8(_:)), for: UIControlEvents.touchUpInside)
        Fview.color9.addTarget(self, action: #selector(EditViewController.c9(_:)), for: UIControlEvents.touchUpInside)
        Fview.color10.addTarget(self, action: #selector(EditViewController.c10(_:)), for: UIControlEvents.touchUpInside)
        Fview.color11.addTarget(self, action: #selector(EditViewController.c11(_:)), for: UIControlEvents.touchUpInside)
        Fview.color12.addTarget(self, action: #selector(EditViewController.c12(_:)), for: UIControlEvents.touchUpInside)
        Fview.color13.addTarget(self, action: #selector(EditViewController.c13(_:)), for: UIControlEvents.touchUpInside)
        Fview.color14.addTarget(self, action: #selector(EditViewController.c14(_:)), for: UIControlEvents.touchUpInside)
        Fview.color15.addTarget(self, action: #selector(EditViewController.c15(_:)), for: UIControlEvents.touchUpInside)
        Fview.sizeslider.addTarget(self, action: #selector(EditViewController.slider(_:)), for: UIControlEvents.touchUpInside)
        
        Fview.screenshotswitch.addTarget(self, action: #selector(EditViewController.screen(_:)), for: UIControlEvents.touchUpInside)
        
        Fview.italicbool.addTarget(self, action: #selector(EditViewController.Italic(_:)), for: UIControlEvents.touchUpInside)
        Fview.boldbool.addTarget(self, action: #selector(EditViewController.Bold(_:)), for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(Fview)
        
        
        
        
    }
    */
    
    @IBAction func show3(_ sender: AnyObject) {
        
        if customview3 != nil{
            customview3.removeFromSuperview()
        }
        
        switch tag_int {
        case 0:
            customview3 = Customview3(frame: CGRect(x:130,y:60, width: 250,height: 210))
            break
        case 1:
            customview3 = Customview3(frame: CGRect(x:230,y:60, width: 250,height: 210))
            break
        case 2:
            customview3 = Customview3(frame: CGRect(x:230,y:60, width: 250,height: 210))
            break
        case 3:
            customview3 = Customview3(frame: CGRect(x:230,y:60, width: 250,height: 210))
            break
        case 4:
            customview3 = Customview3(frame: CGRect(x:5,y:200, width: 250,height: 210))
            break
        case 5:
            customview3 = Customview3(frame: CGRect(x:5,y:100, width: 250,height: 210))
            break
            
            
            
            
            
        default:
            customview3 = Customview3(frame: CGRect(x:5,y:150, width: 250,height: 210))
            break
            
        }
        
        customview3.searchfield.delegate = self
        customview3.replacefield.delegate = self
        
        
        customview3.layer.borderWidth = 1
        
        customview3.layer.cornerRadius = 8;
        
        customview3.layer.borderColor = UIColor.black.cgColor
        
        customview3.searchokbutton.addTarget(self, action: #selector(EditViewController.searchaction(_:)), for: UIControlEvents.touchUpInside)
        
        customview3.replaceokbutton.addTarget(self, action: #selector(EditViewController.replaceaction(_:)), for: UIControlEvents.touchUpInside)
        
        customview3.backbutton.addTarget(self, action: #selector(EditViewController.back3action(_:)), for: UIControlEvents.touchUpInside)
        
        
        
        self.view.addSubview(customview3)
        
        
    }
    
    
    //
    func searchaction(_ sender:UIButton) {
        
        //
        selectedIndexPaths.removeAllObjects()
        
        let matchcontains = customview3.searchfield.text
        
        if customview3.mcselector.selectedSegmentIndex == 0 {
            
            
            selectedIndexPaths = global.searchfunction(target: matchcontains!)
            
        }else if customview3.mcselector.selectedSegmentIndex == 1 {
            
            selectedIndexPaths = global.searchfunction2(target: matchcontains!)
        }else{
            
        }
        
        myCollectionView.reloadData()
        
        
        resultLabel.text = String(selectedIndexPaths.count) + " " + "cases" + " " + "found"
        
        
        
    }
    
    func replaceaction(_ sender:UIButton) {
        
        //
        
        let matchcontains = customview3.searchfield.text
        let replacetext = customview3.replacefield.text
        
        if customview3.mcselector.selectedSegmentIndex == 0 {
            
            
            global.replacefunction(target: matchcontains!, replaced: replacetext!)
            
        }else if customview3.mcselector.selectedSegmentIndex == 1 {
            
            global.replacefunction2(target: matchcontains!, replaced: replacetext!)
        }else{
            
        }
        
        myCollectionView.reloadData()
        
        
        
    }
    
    func back3action(_ sender:UIButton)
    {
        
        
        self.customview3.removeFromSuperview()
        
        
    }

    func configure(_ cell: UICollectionViewCell, forRowAtIndexPath indexPath: IndexPath) {
        
        if selectedIndexPaths.contains(indexPath) {
            // selected
            cell.backgroundColor = UIColor.cyan
        }
        else {
            
            cell.backgroundColor = UIColor.white //it also delete index numbers
        }
    }




}


 

extension UICollectionView {
    func deselectAllItems(animated: Bool = false) {
        for indexPath in self.indexPathsForSelectedItems ?? [] {
            self.deselectItem(at: indexPath, animated: animated)
        }
    }
}

