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
    var isFromFF = false
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

    // Whichever mode presented this loading screen (e.g. a cell-size slider
    // change) needs to land back in that same mode -- isFromFF must be set by
    // the caller before presenting, otherwise this always falls back to
    // ViewController.
    let identifier = isFromFF ? "Filefill" : "StartLine"

    if appd.imported_xlsx_file_path == "" {
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: identifier )
        if let ff = targetViewController as? FileFillViewController {
            ff.isExcel = false
        } else if let vc = targetViewController as? ViewController {
            vc.isExcel = false
        }
        targetViewController.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        return
    }

    if appd.imported_xlsx_file_path != "" {
        print("yourExcelfile",appd.imported_xlsx_file_path)
        // readExcel2/testReadXMLSandBox used to run here too, but their result was
        // never read -- the freshly-presented ViewController below immediately
        // redoes the exact same full unzip+parse itself in its own viewDidLoad
        // (loadExcelSheet), since it's a new instance with empty location/content
        // arrays. Running it twice just doubled the ~200-350ms parse cost on
        // every settings change (cell size, etc.) for no benefit.
        print("end LoadingFileController")

        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: identifier )
        if let ff = targetViewController as? FileFillViewController {
            ff.isExcel = true
        } else if let vc = targetViewController as? ViewController {
            vc.isExcel = true
        }
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
