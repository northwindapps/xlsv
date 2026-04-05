//
//  Customview2.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2016/12/09.
//  Copyright © 2016年 Credera. All rights reserved.
//

import UIKit

class RangeSelectionOpsView: UIView {

    var view3:UIView!
    
    @IBOutlet weak var insertcol: UIButton!
    
    @IBOutlet weak var insertrow: UIButton!
    
    @IBOutlet weak var deletecol: UIButton!
    
    @IBOutlet weak var deleterow: UIButton!
    
    @IBOutlet weak var deletevalues: UIButton!
    
    @IBOutlet weak var `return`: UIButton!
    
    @IBOutlet weak var copyandpaste: UIButton!
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
        view3 = loadviewfromNib()
        view3.frame = bounds
        //http://stackoverflow.com/questions/30867325/binary-operator-cannot-be-applied-to-two-UIView.AutoresizingMask-operands
        view3.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view3)
        
    }
    
    //http://stackoverflow.com/questions/34658838/instantiate-view-from-nib-throws-error
    func loadviewfromNib() ->UIView
    {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "RangeSelectionOpsView",bundle: bundle)
        let view3 = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view3
    }

}
