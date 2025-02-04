//
//  VideoViewController.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2017/01/28.
//  Copyright © 2017年 Credera. All rights reserved.
//

import UIKit
import GoogleMobileAds

class VideoViewController: UIViewController,GADBannerViewDelegate {
    @IBOutlet weak var mywebview: UIWebView!
    @IBOutlet weak var bannerview: GADBannerView!
    
    override func viewDidLoad() {

    let url: URL = URL(string: "https://www.youtube.com/channel/UCzhiGM_2DmbKdgDJjbyYfAQ")!
    let request: URLRequest = URLRequest(url: url)
    
    //var htmlString:String! = "<br /><h2>Welcome to SourceSafari!!!</h2>"
    //myview.loadHTMLString(htmlString, baseURL:url )
    
    
    
    mywebview.loadRequest(request)
        
        bannerview.isHidden = true
        bannerview.delegate = self

        
        //
        bannerview.adUnitID = "ca-app-pub-5284441033171047/4378716417"
        bannerview.rootViewController = self
        bannerview.load(GADRequest())

    
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
}

override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
}
    

    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerview.isHidden = false
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        bannerview.isHidden = true
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
