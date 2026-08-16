//
//  Customview2.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2016/12/09.
//  Copyright © 2016年 Credera. All rights reserved.
//

import UIKit

class Datafilter: UIView {

    var view:UIView!
    
    @IBOutlet weak var closebutton: UIButton!
    
    @IBOutlet weak var applybutton: UIButton!
    
    @IBOutlet weak var deselectbutton: UIButton!
    
    
    @IBOutlet weak var textequalfield: UITextField!
    
    @IBOutlet weak var numlargerfield: UITextField!
    
    @IBOutlet weak var numlesserfield: UITextField!
    
    @IBOutlet weak var numequalfield: UITextField!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
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
    
    //http://stackoverflow.com/questions/34658838/instantiate-view-from-nib-throws-error
    func loadviewfromNib() ->UIView
    {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "Datafilter",bundle: bundle)
        let v = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return v
    }

}
