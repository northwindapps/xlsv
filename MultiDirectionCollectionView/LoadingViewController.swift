//
//  LoadingView.swift
//  MultiDirectionCollectionView
//
//  Created by yujin on 2024/03/16.
//  Copyright © 2024 Credera. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var uai: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Call the showAnimate function after a 5-second delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.showAnimate()
        }
        startLoading()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showAnimate()
    {
        
        let next = storyboard!.instantiateViewController(withIdentifier: "StartLine") as! ViewController
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
//        if appd.sheetNames.count{
//            next.isExcel = false
//        }else{
//            next.isExcel = true
//        }
        next.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(next, animated: true, completion: nil)
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
