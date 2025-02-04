//
//  Customview2.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2016/12/09.
//  Copyright © 2016年 Credera. All rights reserved.
//

import UIKit

class Customview3: UIView {

    var view2:UIView!
    
    @IBOutlet weak var closebutton: UIButton!
    @IBOutlet weak var backbutton: UIButton!
    @IBOutlet weak var mcselector: UISegmentedControl!
    
    @IBOutlet weak var save: UIButton!
    
    @IBOutlet weak var searchfield: UITextField!
    
    
    @IBOutlet weak var searchkbutton: UIButton!
    
    @IBOutlet weak var replacefield: UITextField!
    
    
    @IBOutlet weak var replaceokbutton: UIButton!
    
    @IBOutlet weak var searchlabel: UILabel!
    
    @IBOutlet weak var replacelabel: UILabel!
    
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
        view2 = loadviewfromNib()
        view2.frame = bounds
        //http://stackoverflow.com/questions/30867325/binary-operator-cannot-be-applied-to-two-UIView.AutoresizingMask-operands
        view2.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view2)
        
    }
    
    //http://stackoverflow.com/questions/34658838/instantiate-view-from-nib-throws-error
    func loadviewfromNib() ->UIView
    {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "Customviewboard3",bundle: bundle)
        let view2 = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view2
    }

}
