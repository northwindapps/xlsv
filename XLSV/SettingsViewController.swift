//
//  SettingsViewController.swift
//  MultiDirectionCollectionView
//
//  Created by yujinyano on 2018/09/07.
//  Copyright © 2018年 Credera. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController,UITextFieldDelegate {

     @IBOutlet weak var cellWidthlabel: UILabel!
    var idx:Int?
       
    @IBOutlet weak var `return`: UIButton!
    
       @IBAction func exsmallCell(_ sender: Any) {
           let location1 = UserDefaults.standard
           location1.set(0, forKey: "cellSize")
           location1.synchronize()
           showAnimate()
       }
       @IBAction func smallCell(_ sender: Any) {
           let location1 = UserDefaults.standard
           location1.set(1, forKey: "cellSize")
           location1.synchronize()
           showAnimate()
       }
       
       @IBAction func middiumCell(_ sender: Any) {
           let location1 = UserDefaults.standard
           location1.set(2, forKey: "cellSize")
           location1.synchronize()
           showAnimate()
       }
       
       
       @IBAction func largeCell(_ sender: Any) {
           let location1 = UserDefaults.standard
           location1.set(3, forKey: "cellSize")
           location1.synchronize()
           showAnimate()
       }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
      
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showAnimate() -> Bool
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if appd.imported_xlsx_file_path == "" {
            let next = storyboard!.instantiateViewController(withIdentifier: "StartLine") as! ViewController
            next.modalPresentationStyle = .fullScreen
            self.present(next,animated: true, completion: nil)
            return true
        }
        
        print("go to file view")
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "LoadingFileController" ) as! LoadingFileController //Landscape
        targetViewController.idx = idx
        targetViewController.modalPresentationStyle = .fullScreen
        // Present the target view controller after LoadingFileController's view has appeared
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        
        return true
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
 

}
