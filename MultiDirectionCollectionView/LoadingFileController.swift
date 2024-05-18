//
//  LoadingFileController.swift
//  MultiDirectionCollectionView
//
//  Created by yujin on 2024/03/27.
//  Copyright © 2024 Credera. All rights reserved.
//

import Foundation
import UIKit

class LoadingFileController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var uai: UIActivityIndicatorView!
    
    var idx:Int?
    
    override func viewDidLoad() {
    super.viewDidLoad()

    // Call the showAnimate function after a 5-second delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        self.showAnimate()
    }
    startLoading()
}

override func viewDidAppear(_ animated: Bool) {
    
}

override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
}

func showAnimate()
{
    let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
    if appd.ws_path == "" {
        let next = storyboard!.instantiateViewController(withIdentifier: "StartLine") as! ViewController
        next.modalPresentationStyle = .fullScreen
        self.present(next,animated: true, completion: nil)
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController//Landscape
            
        targetViewController.isExcel = false
        targetViewController.sheetIdx = idx ?? 1
        targetViewController.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        return
    }
    
    if appd.ws_path != "" {
        print("yourExcelfile",appd.ws_path)
        let ehp = ExcelHelper()
        ehp.readExcel2(path: appd.ws_path, wsIndex: appd.wsSheetIndex)
        // Do any additional setup after loading the view.
        let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //let url = serviceInstance.testSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
        let notUsed = serviceInstance.testReadXMLSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
        print("end LoadingFileController")
        
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController//Landscape
        
        targetViewController.isExcel = true
        targetViewController.sheetIdx = appd.wsSheetIndex
        targetViewController.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        return
    }
    
}

func startLoading() {
       // Start animating the activity indicator
       uai.startAnimating()
       
       // Optionally, disable user interaction to prevent interaction during loading
       view.isUserInteractionEnabled = false
   }

   func stopLoading() {
       // Stop animating the activity indicator
       uai.stopAnimating()
       
       // Re-enable user interaction
       view.isUserInteractionEnabled = true
   }

}



