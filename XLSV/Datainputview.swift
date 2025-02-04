//
//  Datainputview.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2017/07/03.
//  Copyright © 2017年 Credera. All rights reserved.
//

import UIKit

class Datainputview: UIView {
//    var lastLocation = CGPoint(x: 0, y: 0)
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    var view:UIView!

    @IBOutlet weak var okbutton: UIButton!
    
    @IBOutlet weak var stringbox: UITextView!
   
    @IBOutlet weak var copyButton: UIButton!

    
    @IBOutlet weak var returnbutton: UIButton!
    @IBOutlet weak var fontbutton: UIButton!
    
    @IBOutlet weak var rightArrow: UIButton!
    @IBOutlet weak var leftArrow: UIButton!
    @IBOutlet weak var upArrow: UIButton!
    @IBOutlet weak var downArrow: UIButton!
    
    @IBOutlet weak var getValuesButton: UIButton!
    
    @IBOutlet weak var getRefButton: UIButton!
    
    @IBOutlet weak var sinButton: UIButton!
    @IBOutlet weak var asinButton: UIButton!
    @IBOutlet weak var cosButton: UIButton!
    @IBOutlet weak var acosButton: UIButton!
    @IBOutlet weak var tanButton: UIButton!
    @IBOutlet weak var atanButton: UIButton!
    
    @IBOutlet weak var logdButton: UIButton!
    @IBOutlet weak var lnButton: UIButton!
    
    @IBOutlet weak var expButton: UIButton!
    @IBOutlet weak var powButton: UIButton!
    
    @IBOutlet weak var sqrtButton: UIButton!
    @IBOutlet weak var complexButton: UIButton!
    
    @IBOutlet weak var piButton: UIButton!
    @IBOutlet weak var imsumButton: UIButton!
    
    @IBOutlet weak var imsubButton: UIButton!
    @IBOutlet weak var improButton: UIButton!
    
    @IBOutlet weak var imargButton: UIButton!
    @IBOutlet weak var imdivButton: UIButton!
    
    @IBOutlet weak var imabsButton: UIButton!
    @IBOutlet weak var imrectButton: UIButton!
    
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var crossButton: UIButton!
    
    @IBOutlet weak var openBraceButton: UIButton!
    @IBOutlet weak var closeBraceButton: UIButton!
    
    @IBOutlet weak var commaButton: UIButton!
    @IBOutlet weak var colonButton: UIButton!
    
    
    
    //new buttons
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        // Initialization code SUSPEND
//        let panRecognizer = UIPanGestureRecognizer(target:self, action:#selector(detectPan))
//        self.gestureRecognizers = [panRecognizer]
        setup()
    }
    
    required init(coder aDecoder:NSCoder)
    {
        super.init(coder:aDecoder)!
        setup()
    }
    
    func setup()
    {
        view = loadviewfromNib()
        view.frame = bounds
        //http://stackoverflow.com/questions/30867325/binary-operator-cannot-be-applied-to-two-UIView.AutoresizingMask-operands
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
        
    }
    
//    @objc func detectPan(_ recognizer:UIPanGestureRecognizer) {
//         let translation  = recognizer.translation(in: self.superview)
//         self.center = CGPoint(x: lastLocation.x + translation.x, y: lastLocation.y + translation.y)
//     }
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        // Promote the touched view
//        self.superview?.bringSubview(toFront: self)
//
//        // Remember original location
//        lastLocation = self.center
//    }
    
    //http://stackoverflow.com/questions/34658838/instantiate-view-from-nib-throws-error
    func loadviewfromNib() ->UIView
    {
       
        
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            // It's an iPhone
            let bundle = Bundle(for: type(of: self))
            let nib = UINib(nibName: "Datainput",bundle: bundle)
            let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
            return view
        case .pad:
            // It's an iPad
            let bundle = Bundle(for: type(of: self))
            let nib = UINib(nibName: "Input4Pad",bundle: bundle)
            let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
            return view
        default:
            let bundle = Bundle(for: type(of: self))
            let nib = UINib(nibName: "Datainput",bundle: bundle)
            let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
            return view
        }
        
        
    }
    
}
