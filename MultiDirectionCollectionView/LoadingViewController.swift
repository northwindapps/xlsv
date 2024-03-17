//
//  LoadingView.swift
//  MultiDirectionCollectionView
//
//  Created by yujin on 2024/03/16.
//  Copyright © 2024 Credera. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController,UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Call the showAnimate function after a 5-second delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showAnimate()
            }
        
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
        next.modalPresentationStyle = .fullScreen
        self.present(next,animated: true, completion: nil)
        
    }
    
}
