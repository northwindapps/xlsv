//
//  CreditViewController.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2016/11/28.
//  Copyright © 2016年 Credera. All rights reserved.
//

import UIKit

class CreditController: UIViewController {

    @IBOutlet weak var creditview: UITextView!
    @IBOutlet weak var returnButton: UIButton!
    
    @IBAction func returnAction(_ sender: Any) {
        showAnimate()
    }
    override func viewDidLoad() {
        
        creditview.isEditable = false
        creditview.dataDetectorTypes = .link
        
        creditview.text = "Developer's website:\nhttps://northwindsoftware.com/?US\n\nTutorial of the app (Youtube): \nhttps://www.youtube.com/channel/UCzMh7Tx9e1BRpmQibgX2Skw\n\n\n Credit\nThis application uses the following open source widely in the code.  \n\n\n1.https://github.com/kwandrews7/MultiDirectionCollectionView/tree/adding-sticky-headersCopyright \n(c) 2015 Kyle Andrews\n\n\nLicense(MIT):https://github.com/kwandrews7/MultiDirectionCollectionView/blob/adding-sticky-headers/LICENSE\n\n2.https://github.com/MaxDesiatov/CoreXLSX\n\nCopyright 2018-2019 Max Desiatov\n\nApache License Version 2.0, January 2004 http://www.apache.org/licenses/"
        
//        returnButton.addTarget(self, action: #selector(returnTOP), for: UIControl.Event.touchUpInside)
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showAnimate()
    {
      
        let next = storyboard!.instantiateViewController(withIdentifier: "StartLine") as! ViewController
        next.modalPresentationStyle = .fullScreen
        self.present(next,animated: true, completion: nil)
        
    }
    
    @objc func returnTOP() {
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController //Landscape
        targetViewController.modalPresentationStyle = .fullScreen
        self.present( targetViewController, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
