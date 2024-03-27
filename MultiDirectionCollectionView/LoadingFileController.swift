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
    print("yourExcelfile",appd.ws_path)
    let ehp = ExcelHelper()
        ehp.readExcel2(path: appd.ws_path, wsIndex: idx ?? 1)
    // Do any additional setup after loading the view.
    print("end LoadingFileController")
    
    let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "StartLine" ) as! ViewController//Landscape
        
    targetViewController.isExcel = true
    targetViewController.modalPresentationStyle = .fullScreen
    DispatchQueue.main.async {
        self.present(targetViewController, animated: true, completion: nil)
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



