//
//  formatview.swift
//  TableGeneratorAdfree
//
//  Created by 矢野悠人 on 2017/01/11.
//  Copyright © 2017年 yumiya. All rights reserved.
//

import UIKit

class formatview: UIView {
    var lastLocation = CGPoint(x: 0, y: 0)
    
    @IBOutlet weak var fontsegment: UISegmentedControl!
    @IBOutlet weak var formatBackButton: UIButton!
    @IBOutlet weak var color1: UIButton!
    @IBOutlet weak var color2: UIButton!
    
    @IBOutlet weak var color5: UIButton!
    @IBOutlet weak var color6: UIButton!
    @IBOutlet weak var color7: UIButton!
    @IBOutlet weak var color8: UIButton!
    @IBOutlet weak var color9: UIButton!
    @IBOutlet weak var color10: UIButton!
    @IBOutlet weak var color11: UIButton!
    @IBOutlet weak var color12: UIButton!
    @IBOutlet weak var color13: UIButton!
    @IBOutlet weak var color14: UIButton!
    @IBOutlet weak var color15: UIButton!
    @IBOutlet weak var sizeslider: UISlider!
    @IBOutlet weak var sizelabel: UILabel!
    
    
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    @IBOutlet weak var fontSeg: UISegmentedControl!
    
    var view:UIView!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        // Initialization code
        let panRecognizer = UIPanGestureRecognizer(target:self, action:#selector(detectPan))
        self.gestureRecognizers = [panRecognizer]
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
    
    @objc func detectPan(_ recognizer:UIPanGestureRecognizer) {
         let translation  = recognizer.translation(in: self.superview)
         self.center = CGPoint(x: lastLocation.x + translation.x, y: lastLocation.y + translation.y)
     }
     
     override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
         // Promote the touched view
         self.superview?.bringSubview(toFront: self)
         
         // Remember original location
         lastLocation = self.center
     }
    
    //http://stackoverflow.com/questions/34658838/instantiate-view-from-nib-throws-error
    func loadviewfromNib() ->UIView
    {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "formatviewboard",bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    
}
